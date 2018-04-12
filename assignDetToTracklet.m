function new_tracklet_mat = assignDetToTracklet(tracklet_mat)

% get tracklet interval
new_tracklet_mat = tracklet_mat;
N_tracklet = size(new_tracklet_mat.xmin_mat,1);
N_fr = size(new_tracklet_mat.xmin_mat,2);
track_interval = zeros(N_tracklet,2);
cand_idx = find(new_tracklet_mat.xmin_mat>=0);
min_mask = Inf*ones(size(new_tracklet_mat.xmin_mat));
min_mask(cand_idx) = cand_idx;
[min_v,track_interval(:,1)] = min(min_mask,[],2);
track_interval(min_v==Inf,1) = -1;
max_mask = zeros(size(new_tracklet_mat.xmin_mat));
max_mask(cand_idx) = cand_idx;
[max_v,track_interval(:,2)] = max(max_mask,[],2);
track_interval(max_v==0,2) = -1;

% fit gaussian regression model
len_tracklet_thresh = 5;
sigma = 8;
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

% assign det to tracklet
pred_model_x = -1*ones(N_tracklet,N_fr);
pred_model_y = -1*ones(N_tracklet,N_fr);
for n = 1:N_tracklet
    if isempty(model_set.x{n})
        continue
    end
    pred_model_x(n,:) = predict(model_set.x{n},(1:N_fr)')';
    pred_model_y(n,:) = predict(model_set.y{n},(1:N_fr)')';
end

for t = 1:N_fr
%     cand_track = 1:N_tracklet;
    cand_track = find(t>=track_interval(:,1) & t<=track_interval(:,2));
%     cand_track = find(new_tracklet_mat.xmin_mat(:,t)>=0);
    
    remove_idx = [];
    for n = 1:length(cand_track)
        if ~isempty(model_set.x{cand_track(n)})
            remove_idx = [remove_idx,n];
        end
    end
    cand_track(remove_idx) = [];
    if length(cand_track)<2
        continue
    end
    
    det_x = 0.5*(new_tracklet_mat.xmin_mat(cand_track,t)+new_tracklet_mat.xmax_mat(cand_track,t))+1;
    det_y = new_tracklet_mat.ymax_mat(cand_track,t);
    det_pts = [det_x,det_y];
    pred_pts = [pred_model_x(cand_track,t),pred_model_y(cand_track,t)];
    dist_mat = pdist2(det_pts,pred_pts);
    N_cand = length(cand_track);
    for n1 = 1:N_cand
        prev_cost = zeros(1,N_cand);
        cur_cost = zeros(1,N_cand);
        for n2 = 1:N_cand
            if n2==n1
                continue
            end
            prev_cost(n2) = dist_mat(n1,n1)+dist_mat(n2,n2);
            cur_cost(n2) = dist_mat(n1,n2)+dist_mat(n2,n1);
        end
        diff_cost = cur_cost-prev_cost;
        diff_cost(n1) = Inf;
        [min_cost,idx2] = min(diff_cost);
        if min_cost>0
            continue
        end
        vec1 = dist_mat(n1,:);
        dist_mat(n1,:) = dist_mat(idx2,:);
        dist_mat(idx2,:) = vec1;
        vec2 = dist_mat(:,n1);
        dist_mat(:,n1) = dist_mat(:,idx2);
        dist_mat(:,idx2) = vec2;
        
        % update tracklet
        temp_v = new_tracklet_mat.xmin_mat(cand_track(n1),t);
        new_tracklet_mat.xmin_mat(cand_track(n1),t) = new_tracklet_mat.xmin_mat(cand_track(idx2),t);
        new_tracklet_mat.xmin_mat(cand_track(idx2),t) = temp_v;
        temp_v = new_tracklet_mat.ymin_mat(cand_track(n1),t);
        new_tracklet_mat.ymin_mat(cand_track(n1),t) = new_tracklet_mat.ymin_mat(cand_track(idx2),t);
        new_tracklet_mat.ymin_mat(cand_track(idx2),t) = temp_v;
        temp_v = new_tracklet_mat.xmax_mat(cand_track(n1),t);
        new_tracklet_mat.xmax_mat(cand_track(n1),t) = new_tracklet_mat.xmax_mat(cand_track(idx2),t);
        new_tracklet_mat.xmax_mat(cand_track(idx2),t) = temp_v;
        temp_v = new_tracklet_mat.ymax_mat(cand_track(n1),t);
        new_tracklet_mat.ymax_mat(cand_track(n1),t) = new_tracklet_mat.ymax_mat(cand_track(idx2),t);
        new_tracklet_mat.ymax_mat(cand_track(idx2),t) = temp_v;
    end
end