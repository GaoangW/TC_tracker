function f = combCost(track_set, tracklet_mat, cluster_params, appearance_cost)

N_tracklet = length(track_set);
track_interval = tracklet_mat.track_interval;
[~,sort_idx] = sort(track_interval(track_set,2),'ascend');

% split cost
split_cost = 1;

% regression cost
t = [];
test_t = [];
test_x = [];
test_y = [];
test_w = [];
test_h = [];
det_x = [];
det_y = [];
det_w = [];
det_h = [];
train_t = [];
train_x = [];
train_y = [];
train_w = [];
train_h = [];
end_t = [];
piece_x = [];
piece_y = [];
len_test = 4;
if N_tracklet<=1
    color_flag = 0;
else
    color_flag = 1;
    diff_mean_color = zeros(3,N_tracklet-1);
end

for n = 1:N_tracklet
    track_id = track_set(sort_idx(n));
    temp_t = track_interval(track_id,1):track_interval(track_id,2);
    
    if color_flag==1
        if n==1
            temp_color = tracklet_mat.color_mat(track_id,temp_t,:);
            if length(temp_t)>cluster_params.color_sample_size
                end_color = temp_color(1,end-cluster_params.color_sample_size:end,:);
            else
                end_color = temp_color;
            end
        elseif n<N_tracklet
            temp_color = tracklet_mat.color_mat(track_id,temp_t,:);
            if length(temp_t)>cluster_params.color_sample_size
                start_color = temp_color(1,1:cluster_params.color_sample_size,:);
            else
                start_color = temp_color;
            end
            diff_mean_color(1,n-1) = abs(mean(start_color(:,1))-mean(end_color(:,1)));
            diff_mean_color(2,n-1) = abs(mean(start_color(:,2))-mean(end_color(:,2)));
            diff_mean_color(3,n-1) = abs(mean(start_color(:,3))-mean(end_color(:,3)));
            if length(temp_t)>cluster_params.color_sample_size
                end_color = temp_color(1,end-cluster_params.color_sample_size:end,:);
            else
                end_color = temp_color;
            end
        else
            temp_color = tracklet_mat.color_mat(track_id,temp_t,:);
            if length(temp_t)>cluster_params.color_sample_size
                start_color = temp_color(1,1:cluster_params.color_sample_size,:);
            else
                start_color = temp_color;
            end
            diff_mean_color(1,n-1) = abs(mean(start_color(1,:,1))-mean(end_color(1,:,1)));
            diff_mean_color(2,n-1) = abs(mean(start_color(1,:,2))-mean(end_color(1,:,2)));
            diff_mean_color(3,n-1) = abs(mean(start_color(1,:,3))-mean(end_color(1,:,3)));
        end
    end
    temp_test_t1 = temp_t(1):min(temp_t(end),temp_t(1)+len_test);
    temp_test_t2 = max(temp_t(end)-len_test,temp_t(1)):temp_t(end);
    
    if n~=1
        test_x = [test_x,tracklet_mat.det_x(track_id,temp_test_t1)];
        test_y = [test_y,tracklet_mat.det_y(track_id,temp_test_t1)];
        test_w = [test_w,tracklet_mat.xmax_mat(track_id,temp_test_t1)-tracklet_mat.xmin_mat(track_id,temp_test_t1)+1];
        test_h = [test_h,tracklet_mat.ymax_mat(track_id,temp_test_t1)-tracklet_mat.ymin_mat(track_id,temp_test_t1)+1];
        test_t = [test_t,temp_test_t1];
        end_t = [end_t,temp_t(1)];
    end
    
    if n~=N_tracklet
        test_x = [test_x,tracklet_mat.det_x(track_id,temp_test_t2)];
        test_y = [test_y,tracklet_mat.det_y(track_id,temp_test_t2)];
        test_w = [test_w,tracklet_mat.xmax_mat(track_id,temp_test_t2)-tracklet_mat.xmin_mat(track_id,temp_test_t2)+1];
        test_h = [test_h,tracklet_mat.ymax_mat(track_id,temp_test_t2)-tracklet_mat.ymin_mat(track_id,temp_test_t2)+1];
        test_t = [test_t,temp_test_t2];
        end_t = [end_t,temp_t(end)];
    end
    
%     temp_t = uniformSample(temp_t, cluster_params.track_len);
    det_x = [det_x,tracklet_mat.det_x(track_id,temp_t)];
    det_y = [det_y,tracklet_mat.det_y(track_id,temp_t)];
    det_w = [det_w,tracklet_mat.xmax_mat(track_id,temp_t)-tracklet_mat.xmin_mat(track_id,temp_t)+1];
    det_h = [det_h,tracklet_mat.ymax_mat(track_id,temp_t)-tracklet_mat.ymin_mat(track_id,temp_t)+1];
    t = [t, temp_t];
    
    temp_t1 = temp_t(1:min(length(temp_t),cluster_params.track_len));
    temp_t2 = temp_t(end-min(length(temp_t),cluster_params.track_len)+1:end);
    train_t = [train_t,temp_t1,temp_t2];
    train_x = [train_x,tracklet_mat.det_x(track_id,temp_t1),tracklet_mat.det_x(track_id,temp_t2)];
    train_y = [train_y,tracklet_mat.det_y(track_id,temp_t1),tracklet_mat.det_y(track_id,temp_t2)];
    train_w = [train_w,tracklet_mat.xmax_mat(track_id,temp_t1)-tracklet_mat.xmin_mat(track_id,temp_t1)+1,...
        tracklet_mat.xmax_mat(track_id,temp_t2)-tracklet_mat.xmin_mat(track_id,temp_t2)+1];
    train_h = [train_h,tracklet_mat.ymax_mat(track_id,temp_t1)-tracklet_mat.ymin_mat(track_id,temp_t1)+1,...
        tracklet_mat.ymax_mat(track_id,temp_t2)-tracklet_mat.ymin_mat(track_id,temp_t2)+1];
end

grad_cost = 0;
if length(unique(t))<cluster_params.len_tracklet_thresh
    reg_cost = cluster_params.small_track_cost;  
    grad_cost = 0;
else
    [t,idx] = unique(t);
    det_x = det_x(idx);
    det_y = det_y(idx);
    det_w = det_w(idx);
    det_h = det_h(idx);
%     [t,sample_idx] = uniformSample(t, cluster_params.track_len);
%     det_x = det_x(sample_idx);
%     det_y = det_y(sample_idx);
%     det_w = det_w(sample_idx);
%     det_h = det_h(sample_idx);

    [train_t,idx] = unique(train_t);
    train_x = train_x(idx);
    train_y = train_y(idx);
    train_w = train_w(idx);
    train_h = train_h(idx);
    
    det_size = sqrt(train_w.^2+train_h.^2);
    model_x = fitrgp(train_t',train_x','Basis','linear',...
        'FitMethod','exact','PredictMethod','exact','Sigma',cluster_params.sigma,...
        'ConstantSigma',true,'KernelFunction','matern52','KernelParameters',[1000,1000]);
    model_y = fitrgp(train_t',train_y','Basis','linear',...
        'FitMethod','exact','PredictMethod','exact','Sigma',cluster_params.sigma,...
        'ConstantSigma',true,'KernelFunction','matern52','KernelParameters',[1000,1000]);
    model_bbox = fitrgp(train_t',det_size','Basis','linear',...
        'FitMethod','exact','PredictMethod','exact','Sigma',cluster_params.sigma,...
        'ConstantSigma',true,'KernelFunction','matern52','KernelParameters',[1000,1000]);
    
    if ~isempty(test_t)
        [test_t,test_idx] = unique(test_t);
        test_x = test_x(test_idx);
        test_y = test_y(test_idx);
        test_w = test_w(test_idx);
        test_h = test_h(test_idx);
        pred_test_x = predict(model_x,test_t');
        pred_test_y = predict(model_y,test_t');
        test_size = predict(model_bbox,test_t');
        err = sum(sqrt((pred_test_x-test_x').^2+(pred_test_y-test_y').^2)./test_size);
    else
        err = 0;
    end
    reg_cost = err;
    
    pred_x = predict(model_x,t');
    pred_y = predict(model_y,t');
    smooth_size = predict(model_bbox,t');
    t_min = min(t);
    t_max = max(t);
    t_t = t_min:t_max;
%     pred_x_t = predict(model_x,t');
%     pred_y_t = predict(model_y,t');
    
    pred_x_t = interp1(t,pred_x',t_t,'linear');
    pred_y_t = interp1(t,pred_y',t_t,'linear');
    pred_size_t = interp1(t,smooth_size,t_t,'linear');
    
    ax = pred_x_t(3:end)+pred_x_t(1:end-2)-2*pred_x_t(2:end-1);
    ay = pred_y_t(3:end)+pred_y_t(1:end-2)-2*pred_y_t(2:end-1);
    if isempty(ax)
        grad_cost = 0;
    else
        acc_err = sqrt(ax.^2+ay.^2)./pred_size_t(2:end-1);
        t_interval = t_t(2:end-1);
        max_grad = zeros(size(end_t));
        for n = 1:length(end_t)
            temp_idx = find(t_interval==end_t(n));
            min_idx = max(1,temp_idx-3);
            max_idx = min(length(t_interval),temp_idx+3);    
            max_grad(n) = max(acc_err(min_idx:max_idx)); 
        end           
        grad_cost = sum(max_grad);
%         grad_cost = cluster_params.lambda_grad*sum(acc_err(acc_err>2e-3));%max(max(abs(ax)),max(abs(ay)))^2;%max(sqrt(ax.^2+ay.^2));
    end
    
    
%     if length(train_t)>100
%         figure, plot(t,pred_x,'r.',t,det_x,'k.')
%         figure, plot(t_t(2:end-1),acc_err,'b');
%         close all
%     end
end

% color cost
color_cost = 0;
if color_flag==1
    max_diff_color = max(diff_mean_color);
    color_cost = sum(max_diff_color);
end
if nargin>3
    color_cost = appearance_cost;
end

% time cost
track_dist = track_interval(track_set(sort_idx(2:end)),1)-track_interval(track_set(sort_idx(1:end-1)),2);
max_dist = max(track_dist);
if isempty(max_dist) || max_dist<=0
    time_cost = 0;
else
    time_cost = (max_dist^3)/1e6;
end

% cost = cluster_params.split_cost*split_cost+cluster_params.lambda_reg*reg_cost+...
%     cluster_params.lambda_color*color_cost+cluster_params.lambda_grad*grad_cost+...
%     cluster_params.lambda_time*time_cost;
f = [split_cost,reg_cost,color_cost,grad_cost,time_cost];