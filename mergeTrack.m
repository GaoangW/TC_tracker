function [new_tracklet_mat,end_flag] = mergeTrack(tracklet_mat)

% get tracklet interval
new_tracklet_mat = tracklet_mat;
N_tracklet = size(new_tracklet_mat.xmin_mat,1);
track_interval = zeros(N_tracklet,2);
cand_idx = find(new_tracklet_mat.xmin_mat>=0);
min_mask = Inf*ones(size(new_tracklet_mat.xmin_mat));
min_mask(cand_idx) = cand_idx;
[min_v,track_interval(:,1)] = min(min_mask,[],2);
track_interval(min_v==Inf,1) = -1;
max_mask = -1*ones(size(new_tracklet_mat.xmin_mat));
max_mask(cand_idx) = cand_idx;
[max_v,track_interval(:,2)] = max(max_mask,[],2);
track_interval(max_v==0,2) = -1;

% fit gaussian regression model
sigma = 8;
len_tracklet_thresh = 10;
model_set.x = cell(1,N_tracklet);
model_set.y = cell(1,N_tracklet);
for n = 1:N_tracklet
    len_tracklet = track_interval(n,2)-track_interval(n,1)+1;
    if len_tracklet<len_tracklet_thresh
        continue
    end
    t = find(new_tracklet_mat.xmin_mat(n,:)>=0);
    det_pts = [0.5*(new_tracklet_mat.xmin_mat(n,t)+...
        new_tracklet_mat.xmax_mat(n,t))+1; ...
        new_tracklet_mat.ymax_mat(n,t)];
    det_pts = det_pts';

    model_set.x{n} = fitrgp(t',det_pts(:,1),'Basis','linear',...
        'FitMethod','exact','PredictMethod','exact','Sigma',sigma,'ConstantSigma',true,'KernelFunction','matern52','KernelParameters',[1000,1000]);    
    model_set.y{n} = fitrgp(t',det_pts(:,2),'Basis','linear',...
        'FitMethod','exact','PredictMethod','exact','Sigma',sigma,'ConstantSigma',true,'KernelFunction','matern52','KernelParameters',[1000,1000]);    
end

% merge track
t_dist_thresh = 50;
lambda_fit_cost = 80;
testing_size = 10;
intersect_ratio = 0.2;
% assign_idx = zeros(N_tracklet,50);
% assign_cost = zeros(N_tracklet,50);
assign_cost = -1*ones(N_tracklet,N_tracklet);
for n = 1:N_tracklet
    t_1 = find(new_tracklet_mat.xmin_mat(n,:)>=0);
    if length(t_1)<len_tracklet_thresh
        continue
    end
    
    % find available tracklets before and after 
    cand_idx = find(track_interval(n,1)-track_interval(:,2)<t_dist_thresh & track_interval(:,1)-track_interval(n,2)<t_dist_thresh);
    if isempty(cand_idx)
        continue
    end
    remove_idx = [];
    vec_idx1 = find(new_tracklet_mat.xmin_mat(n,:)>=0);
    for k = 1:length(cand_idx)
        vec_idx2 = find(new_tracklet_mat.xmin_mat(cand_idx(k),:)>=0);
        vec_idx3 = intersect(vec_idx1,vec_idx2);
        if length(vec_idx3)/min(length(vec_idx1),length(vec_idx3))>intersect_ratio
            remove_idx = [remove_idx,k];
        end
    end
    cand_idx(remove_idx) = [];
    if isempty(cand_idx)
        continue
    end
    cand_idx(assign_cost(n,cand_idx)>=0) = [];
    if isempty(cand_idx)
        continue
    end
    
    for k = 1:length(cand_idx)
        t2 = find(new_tracklet_mat.xmin_mat(cand_idx(k),:)>=0);
        
        t2_after_idx = t2(t2>track_interval(n,2));
        if length(t2_after_idx)>testing_size
            t2_after_idx = t2_after_idx(1:testing_size);
        end
        t2_before_idx = t2(t2<track_interval(n,1));
        if length(t2_before_idx)>testing_size
            t2_before_idx = t2_before_idx(end-testing_size+1:end);
        end
        t2_mid_idx = t2(t2<track_interval(n,2) & t2>track_interval(n,1));
        t2 = [t2_before_idx,t2_mid_idx,t2_after_idx];
        
%         t_2 = find(new_tracklet_mat.xmin_mat(cand_idx(k),:)>=0);
%         t_3 = intersect(t_1,t_2);
%         t1 = setdiff(t_1,t_3);
%         t2 = setdiff(t_2,t_3);
        
        det_pts2 = [0.5*(new_tracklet_mat.xmin_mat(cand_idx(k),t2)+...
            new_tracklet_mat.xmax_mat(cand_idx(k),t2))+1; ...
            new_tracklet_mat.ymax_mat(cand_idx(k),t2)];
        det_pts2 = det_pts2';
        
        xpred2 = predict(model_set.x{n},t2');
        ypred2 = predict(model_set.y{n},t2');
        
        mean_err = mean(sqrt((xpred2-det_pts2(:,1)).^2+(ypred2-det_pts2(:,2)).^2));

        assign_cost(cand_idx(k),n) = mean_err;
        assign_cost(n,cand_idx(k)) = mean_err;

%         cost_vec(k) = mean(sqrt((xpred2-det_pts2(:,1)).^2+(ypred2-det_pts2(:,2)).^2));
    end
    
    
        
%     [min_cost,min_idx] = min(cost_vec);
%     if min_cost>lambda_fit_cost
%         continue
%     end
%     comb_idx = cand_idx(min_idx);
%     
%     [~,min_assign_idx] = min(assign_idx(comb_idx,:));
%     assign_idx(comb_idx,min_assign_idx) = n;
%     assign_cost(comb_idx,min_assign_idx) = min_cost;
      
    % find available tracklets after end fr
%     cand_idx = find(track_interval(:,1)>track_interval(n,2) & track_interval(:,1)-track_interval(n,2)<t_dist_thresh);
%     if isempty(cand_idx)
%         continue
%     end
%     cost_vec = zeros(size(cand_idx));
%     for k = 1:length(cand_idx)
%         t2 = find(new_tracklet_mat.xmin_mat(cand_idx(k),:)>=0);
%         det_pts2 = [0.5*(new_tracklet_mat.xmin_mat(cand_idx(k),t2)+...
%             new_tracklet_mat.xmax_mat(cand_idx(k),t2))+1; ...
%             new_tracklet_mat.ymax_mat(cand_idx(k),t2)];
%         det_pts2 = det_pts2';
%         if length(t2)>testing_size
%             t2 = t2(1:testing_size);
%             det_pts2 = det_pts2(1:testing_size,:);
%         end
%         
%         xpred2 = predict(model_set.x{n},t2');
%         ypred2 = predict(model_set.y{n},t2');
%         cost_vec(k) = mean(sqrt((xpred2-det_pts2(:,1)).^2+(ypred2-det_pts2(:,2)).^2));
%     end
%     [min_cost,min_idx] = min(cost_vec);
%     if min_cost>lambda_fit_cost
%         continue
%     end
%     comb_idx = cand_idx(min_idx);
%     
%     [~,min_assign_idx] = min(assign_idx(comb_idx,:));
%     assign_idx(comb_idx,min_assign_idx) = n;
%     assign_cost(comb_idx,min_assign_idx) = min_cost;
end
assign_cost(assign_cost<0) = Inf;
final_assign_idx = zeros(N_tracklet,1);
cnt = 0;
while 1
    cnt = cnt+1;
    [min_v,idx] = min_mat(assign_cost);
    if min_v>lambda_fit_cost && cnt==1
        end_flag = 1;
        return
    end
    if min_v>lambda_fit_cost
        break
    end
    final_assign_idx(idx(1)) = idx(2);
    assign_cost(idx(1),:) = Inf;
    assign_cost(:,idx(1)) = Inf;
    assign_cost(idx(2),:) = Inf;
    assign_cost(:,idx(2)) = Inf;
    final_assign_idx(final_assign_idx==n) = final_assign_idx(n);
end
final_assign_idx(final_assign_idx==(1:N_tracklet)') = 0;


% sum_idx = sum(assign_idx);
% assign_idx(:,sum_idx==0) = [];
% assign_cost(:,sum_idx==0) = [];
% assign_cost(assign_cost==0) = Inf;
% if isempty(assign_cost)
%     end_flag = 1;
%     return
% end
% 
% final_assign_idx = zeros(N_tracklet,1);
% for n = 1:N_tracklet
%     if assign_idx(n,1)==0
%         continue
%     end
%     [~,min_cost_idx] = min(assign_cost(n,:));
%     final_assign_idx(n) = assign_idx(n,min_cost_idx);
%     assign_idx(assign_idx==n) = final_assign_idx(n);
%     final_assign_idx(final_assign_idx==n) = final_assign_idx(n);
% end
% final_assign_idx(final_assign_idx==(1:N_tracklet)') = 0;

for n = 1:N_tracklet
    if final_assign_idx(n)==0
        continue
    end
%     t = find(new_tracklet_mat.xmin_mat(final_assign_idx(n),:)>=0);
%     det_pts = [0.5*(new_tracklet_mat.xmin_mat(final_assign_idx(n),t)+...
%         new_tracklet_mat.xmax_mat(final_assign_idx(n),t))+1; ...
%         new_tracklet_mat.ymax_mat(final_assign_idx(n),t)];
%     det_pts = det_pts';
%     t2 = find(new_tracklet_mat.xmin_mat(n,:)>=0);
%     det_pts2 = [0.5*(new_tracklet_mat.xmin_mat(n,t2)+...
%         new_tracklet_mat.xmax_mat(n,t2))+1; ...
%         new_tracklet_mat.ymax_mat(n,t2)];
%     det_pts2 = det_pts2';
%     figure, plot(t,det_pts(:,1),'k.',t2,det_pts2(:,1),'r.')
%     figure, plot(t,det_pts(:,2),'k.',t2,det_pts2(:,2),'r.')
%     close all
    
    t2 = find(new_tracklet_mat.xmin_mat(n,:)>=0);
    new_tracklet_mat.xmin_mat(final_assign_idx(n),t2) = ...
        new_tracklet_mat.xmin_mat(n,t2);
    new_tracklet_mat.ymin_mat(final_assign_idx(n),t2) = ...
        new_tracklet_mat.ymin_mat(n,t2);
    new_tracklet_mat.xmax_mat(final_assign_idx(n),t2) = ...
        new_tracklet_mat.xmax_mat(n,t2);
    new_tracklet_mat.ymax_mat(final_assign_idx(n),t2) = ...
        new_tracklet_mat.ymax_mat(n,t2);
    track_interval(n,:) = -1; 
end
new_tracklet_mat.xmin_mat(track_interval(:,1)==-1,:) = [];
new_tracklet_mat.ymin_mat(track_interval(:,1)==-1,:) = [];
new_tracklet_mat.xmax_mat(track_interval(:,1)==-1,:) = [];
new_tracklet_mat.ymax_mat(track_interval(:,1)==-1,:) = [];
end_flag = 0;