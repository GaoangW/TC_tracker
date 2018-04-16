% Copyright (C)2018, Gaoang Wang, All rights reserved.
function TC_tracker(img_folder,det_path,ROI_path,param,save_path,seq_name,result_save_path,video_save_path)

tic
rand_color = rand(1500,3);
img_list = dir([img_folder,'\*.jpg']);
if isempty(ROI_path)
    temp_img = imread([img_folder,'\',img_list(1).name]);
    mask = ones(size(temp_img,1),size(temp_img,2));
else
    mask = im2double(imread(ROI_path));
end

%% read detection file
fileID = fopen(det_path,'r');
A = textscan(fileID,'%d %d %d %d %d %d %f %d %d %d %s','Delimiter',',');
fclose(fileID);
M = zeros(size(A{1},1),10);
for n = 1:10
    M(:,n) = A{n};
end
% M(:,1) = M(:,1)+1;
% M(:,3) = M(:,3)+1;
% M(:,4) = M(:,4)+1;


track_params.img_size = size(mask);
track_params.num_fr = length(img_list);
track_params.const_fr_thresh = 10;
track_params.overlap_thresh1 = param.IOU_thresh;
track_params.overlap_thresh2 = 0.8;
track_params.lb_thresh = 0.3;
track_params.max_track_id = 0;
track_params.color_thresh = param.color_thresh;
track_params.det_score_thresh = param.det_score_thresh;
track_struct.track_params = track_params;
track_struct.tracklet_mat = [];
track_struct.track_obj = cell(1,track_params.num_fr);
M(:,5) = min(M(:,5),track_params.img_size(2)-M(:,3)+1);
M(:,6) = min(M(:,6),track_params.img_size(1)-M(:,4)+1);
for n = 1:track_params.num_fr
    idx = find(M(:,1)==n & M(:,7)>track_params.det_score_thresh);
    det_bbox = M(idx,3:6);
    [~,choose_idx] = mergeBBox(det_bbox, 0.8, M(idx,7));
    idx = idx(choose_idx);
    
    % check whether detection in the ROI mask
    mask_flag = ones(length(idx),1);
    left_pts = round([M(idx,3),M(idx,4)+M(idx,6)-1]);
    right_pts = round([M(idx,3)+M(idx,5)-1,M(idx,4)+M(idx,6)-1]);
%     left_pts = max(left_pts,1);
%     left_pts(:,1) = min(left_pts(:,1),track_params.img_size(2));
%     left_pts(:,2) = min(left_pts(:,2),track_params.img_size(1));
%     right_pts = max(right_pts,1);
%     right_pts(:,1) = min(right_pts(:,1),track_params.img_size(2));
%     right_pts(:,2) = min(right_pts(:,2),track_params.img_size(1));
    
    right_idx = (right_pts(:,1)-1)*track_params.img_size(1)+right_pts(:,2);
    left_idx = (left_pts(:,1)-1)*track_params.img_size(1)+left_pts(:,2);
    
    right_idx(right_idx<0) = 1;
    left_idx(left_idx<0) = 1;
    out_idx = find(mask(right_idx)<0.5 | mask(left_idx)<0.5);
    mask_flag(out_idx) = 0;
    
    det_score = M(idx,7);
    mask_flag(det_score<track_params.det_score_thresh) = 0;
    
    track_struct.track_obj{n}.track_id = [];
    if isempty(idx)
        track_struct.track_obj{n}.bbox = [];
        track_struct.track_obj{n}.det_class = [];
        track_struct.track_obj{n}.det_score = [];
        track_struct.track_obj{n}.mask_flag = [];
        continue
    end
    track_struct.track_obj{n}.bbox = M(idx,3:6);
    track_struct.track_obj{n}.det_class = A{11}(idx);
    track_struct.track_obj{n}.det_score = M(idx,7)/100;
    track_struct.track_obj{n}.mask_flag = mask_flag;
end

%% forward tracking
for n = 1:track_params.num_fr-1
    if n==1
        img_path = [img_folder,'\',img_list(n).name];
        img1 = im2double(imread(img_path));
    end
    img_path = [img_folder,'\',img_list(n+1).name];
    img2 = im2double(imread(img_path));
    [track_struct.track_obj{n}, track_struct.track_obj{n+1}, track_struct.tracklet_mat, track_struct.track_params] = forwardTracking(...
        track_struct.track_obj{n}, track_struct.track_obj{n+1}, track_struct.track_params, n+1, track_struct.tracklet_mat, ...
        img1, img2);
    img1 = img2;
end

%% tracklet clustering
iters = 10;
track_struct.tracklet_mat = preprocessing(track_struct.tracklet_mat, 5);
for n = 1:iters
    [track_struct.tracklet_mat,flag,~] = trackletClusterInit(track_struct.tracklet_mat,param);
    if flag==1
        break
    end
end
[track_struct.prev_tracklet_mat,track_struct.tracklet_mat] = postProcessing(track_struct.tracklet_mat, track_struct.track_params);

%% Gaussian regression for smoothness
sigma = 8;
remove_idx = [];
N_tracklet = size(track_struct.tracklet_mat.xmin_mat,1);
xmin_reg = cell(1,N_tracklet);
ymin_reg = cell(1,N_tracklet);
xmax_reg = cell(1,N_tracklet);
ymax_reg = cell(1,N_tracklet);
for n = 1:N_tracklet
    det_idx = find(track_struct.tracklet_mat.xmin_mat(n,:)>=0);
    if length(det_idx)<track_struct.track_params.const_fr_thresh
        remove_idx = [remove_idx,n];
        continue
    end
    
    % bbox regression
    xmin_reg{n} = fitrgp(det_idx',track_struct.tracklet_mat.xmin_mat(n,det_idx)','Basis','linear',...
        'FitMethod','exact','PredictMethod','exact','Sigma',sigma,'ConstantSigma',true,'KernelFunction','matern52','KernelParameters',[1000,1000]);
    ymin_reg{n} = fitrgp(det_idx',track_struct.tracklet_mat.ymin_mat(n,det_idx)','Basis','linear',...
        'FitMethod','exact','PredictMethod','exact','Sigma',sigma,'ConstantSigma',true,'KernelFunction','matern52','KernelParameters',[1000,1000]);
    xmax_reg{n} = fitrgp(det_idx',track_struct.tracklet_mat.xmax_mat(n,det_idx)','Basis','linear',...
        'FitMethod','exact','PredictMethod','exact','Sigma',sigma,'ConstantSigma',true,'KernelFunction','matern52','KernelParameters',[1000,1000]);
    ymax_reg{n} = fitrgp(det_idx',track_struct.tracklet_mat.ymax_mat(n,det_idx)','Basis','linear',...
        'FitMethod','exact','PredictMethod','exact','Sigma',sigma,'ConstantSigma',true,'KernelFunction','matern52','KernelParameters',[1000,1000]);
    t_min = min(det_idx);
    t_max = max(det_idx);
    track_struct.tracklet_mat.xmin_mat(n,t_min:t_max) = predict(xmin_reg{n},(t_min:t_max)')';
    track_struct.tracklet_mat.ymin_mat(n,t_min:t_max) = predict(ymin_reg{n},(t_min:t_max)')';
    track_struct.tracklet_mat.xmax_mat(n,t_min:t_max) = predict(xmax_reg{n},(t_min:t_max)')';
    track_struct.tracklet_mat.ymax_mat(n,t_min:t_max) = predict(ymax_reg{n},(t_min:t_max)')';
end
track_struct.tracklet_mat.xmin_mat(remove_idx,:) = [];
track_struct.tracklet_mat.ymin_mat(remove_idx,:) = [];
track_struct.tracklet_mat.xmax_mat(remove_idx,:) = [];
track_struct.tracklet_mat.ymax_mat(remove_idx,:) = [];
track_struct.tracklet_mat.color_mat(remove_idx,:,:) = [];
track_struct.tracklet_mat.class_mat(remove_idx,:) = [];
track_struct.tracklet_mat.det_score_mat(remove_idx,:) = [];
time_use = toc;
run_speed = track_params.num_fr/time_use;
if ~isempty(seq_name)
    save([result_save_path,'\',seq_name,'.mat'],'track_struct');
end

%% plot tracking result
if exist(save_path,'dir')<=0
    mkdir(save_path);
end
for t = 1:track_params.num_fr
    img_name = img_list(t).name;
    img = imread([img_folder,'\',img_name]);
    figure, imshow(img); hold on
    for n = 1:size(track_struct.tracklet_mat.xmin_mat,1)
        if track_struct.tracklet_mat.xmin_mat(n,t)==-1
            continue
        end
        x_min = track_struct.tracklet_mat.xmin_mat(n,t);
        y_min = track_struct.tracklet_mat.ymin_mat(n,t);
        x_max = track_struct.tracklet_mat.xmax_mat(n,t);
        y_max = track_struct.tracklet_mat.ymax_mat(n,t);
        plot([x_min,x_min],[y_min,y_max], 'Color', rand_color(n,:), 'LineWidth', 1); hold on
        plot([x_min,x_max],[y_min,y_min], 'Color', rand_color(n,:), 'LineWidth', 1); hold on
        plot([x_min,x_max],[y_max,y_max], 'Color', rand_color(n,:), 'LineWidth', 1); hold on
        plot([x_max,x_max],[y_min,y_max], 'Color', rand_color(n,:), 'LineWidth', 1); hold on
        text(x_min,y_min-20,num2str(n),'FontSize',20,'Color', rand_color(n,:))
    end
    saveas(gcf,[save_path,'\',img_list(t).name]);
    close all
end
fr2video([save_path,'\'], [video_save_path,'\',seq_name,'.avi'], 25);

%% write results
if ~isempty(seq_name)
    writeTxt(seq_name,result_save_path,result_save_path);
    file_name = [result_save_path,'\',seq_name,'_Speed.txt'];
    fileID = fopen(file_name,'w');
    fprintf(fileID,'%f',run_speed);
    fclose(fileID);
end