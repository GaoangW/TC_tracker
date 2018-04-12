function [new_tracklet_mat,end_flag] = mergeTrack_v2(tracklet_mat)

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

det_x = 0.5*(new_tracklet_mat.xmin_mat+new_tracklet_mat.xmax_mat)+1;
det_y = new_tracklet_mat.ymax_mat;

% merge track
len_tracklet_thresh = 10;
sigma = 8;
intersect_ratio = 0.2;
t_dist_thresh = 30;
lambda_fit_cost = 10;
testing_size = 10;
% data_cost_thresh = 10;
tr_size = 50;
assign_cost = -1*ones(N_tracklet,N_tracklet);
assign_cost_data = -1*ones(N_tracklet,N_tracklet);
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
        if (cand_idx(k)==59 && n==9) || (cand_idx(k)==9 && n==59)
            aa = 0;
        end
        t_2 = find(new_tracklet_mat.xmin_mat(cand_idx(k),:)>=0);
        t_3 = intersect(t_1,t_2);
        t1 = setdiff(t_1,t_3);
        t2 = setdiff(t_2,t_3);
        det_x1 = det_x(n,t1);
        det_y1 = det_y(n,t1);
        det_x2 = det_x(cand_idx(k),t2);
        det_y2 = det_y(cand_idx(k),t2);
        
        [t,det_x_t,det_x_tr,t_interval,t_tr] = dataGroup(t1,t2,det_x1,det_x2,tr_size);        
        %%%%%%%%%%%%%%%%%%%%%update tr set
        model_x = fitrgp(t_tr',det_x_tr','Basis','linear',...
            'FitMethod','exact','PredictMethod','exact','Sigma',sigma,...
            'ConstantSigma',true,'KernelFunction','matern52','KernelParameters',[1000,1000]);        
        xpred = predict(model_x,(t_interval(1)-2:t_interval(end)+2)');
        vx_pred = (xpred(2:end)-xpred(1:end-1));
        choose_idx = (t>=t_interval(1) & t<=t_interval(2));
        sub_t = t(choose_idx);
        sub_x = det_x_t(choose_idx);
        [t_test,interp_x,pred_x] = vInterp_v2(sub_t,sub_x,xpred(2:end-1)',vx_pred',t_tr,det_x_tr);
        
        [t,det_y_t,det_y_tr,t_interval,t_tr] = dataGroup(t1,t2,det_y1,det_y2,tr_size);
        model_y = fitrgp(t_tr',det_y_tr','Basis','linear',...
            'FitMethod','exact','PredictMethod','exact','Sigma',sigma,...
            'ConstantSigma',true,'KernelFunction','matern52','KernelParameters',[1000,1000]);        
        ypred = predict(model_y,(t_interval(1)-2:t_interval(end)+2)');
        vy_pred = (ypred(2:end)-ypred(1:end-1));
        sub_t = t(choose_idx);
        sub_y = det_y_t(choose_idx);
        [t_test,interp_y,pred_y] = vInterp_v2(sub_t,sub_y,ypred(2:end-1)',vy_pred',t_tr,det_y_tr);
        
        err = sqrt((pred_x-interp_x).^2+(pred_y-interp_y).^2);
%         mean_err = mean(err);
        if length(err)>testing_size
            err = sort(err,'descend');
            err = err(1:testing_size);
            mean_err = mean(err);
        else
            mean_err = mean(err);
        end
        
%         if mean(sqrt((pred_x-interp_x).^2+(pred_y-interp_y).^2))<5
%             figure, plot(t_test,interp_x,'r.',t_tr,det_x_tr,'k.',t_test,pred_x,'b.');
%             
%             figure, plot(t_test,interp_y,'r.',t_tr,det_y_tr,'k.',t_test,pred_y,'b.');
%             mean_err
%             
%             %         mean(sqrt((xpred(change_idx)-det_x_t(change_idx)').^2+(ypred(change_idx)-det_y_t(change_idx)').^2))
%             close all
%         end
%         assign_cost(cand_idx(k),n) = mean(sqrt((pred_x-interp_x).^2+(pred_y-interp_y).^2));
%         assign_cost(n,cand_idx(k)) = assign_cost(cand_idx(k),n);
        
        if length(t1)>length(t2) 
            assign_cost(cand_idx(k),n) = mean_err;
%             assign_cost_data(cand_idx(k),n) = mean(sqrt((xpred(change_idx)-det_x_t(change_idx)').^2+(ypred(change_idx)-det_y_t(change_idx)').^2));
        else
            assign_cost(n,cand_idx(k)) = mean_err;
%             assign_cost_data(n,cand_idx(k)) = mean(sqrt((xpred(change_idx)-det_x_t(change_idx)').^2+(ypred(change_idx)-det_y_t(change_idx)').^2));
        end
    end
end
assign_cost(assign_cost<0) = Inf;
% assign_cost_data(assign_cost_data<0) = Inf;

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
% for n = 1:N_tracklet
%     [min_cost,min_cost_idx] = min(assign_cost(n,:));
%     if min_cost<lambda_fit_cost %&& assign_cost_data(n,min_cost_idx)<data_cost_thresh
%         final_assign_idx(n) = min_cost_idx;
%         final_assign_idx(final_assign_idx==n) = final_assign_idx(n);
%     end
% end
final_assign_idx(final_assign_idx==(1:N_tracklet)') = 0;

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