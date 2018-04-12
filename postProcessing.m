function [new_tracklet_mat,new_tracklet_mat2] = postProcessing(tracklet_mat, track_params)

new_tracklet_mat = tracklet_mat;

% update track clusters
N_cluster = length(tracklet_mat.track_cluster);
remove_idx = [];
for n = 1:N_cluster
    if isempty(tracklet_mat.track_cluster{n})
        remove_idx = [remove_idx,n];
        continue
    end
    cnt = 0;
    temp_ids = zeros(1,length(tracklet_mat.track_cluster{n}));
    for k = 1:length(tracklet_mat.track_cluster{n})
        track_id = tracklet_mat.track_cluster{n}(k);
        temp_ids(k) = track_id;
        cnt = cnt+tracklet_mat.track_interval(track_id,2)-tracklet_mat.track_interval(track_id,1)+1;
    end
    if cnt<track_params.const_fr_thresh
        remove_idx = [remove_idx,n];
        new_tracklet_mat.mask_flag(temp_ids) = 0;
    end
end
new_tracklet_mat.track_cluster(remove_idx) = [];
new_tracklet_mat.cluster_cost(remove_idx) = [];
new_tracklet_mat.cluster_flag = zeros(size(new_tracklet_mat.track_class));
new_tracklet_mat.cluster_flag(1:length(new_tracklet_mat.track_cluster)) = 1;

% update track class
new_tracklet_mat.track_class = -1*ones(size(new_tracklet_mat.track_class));
N_cluster = length(new_tracklet_mat.track_cluster);
for n = 1:N_cluster
    for k = 1:length(new_tracklet_mat.track_cluster{n})
        track_id = new_tracklet_mat.track_cluster{n}(k);
        new_tracklet_mat.track_class(track_id) = n;
    end
end

for n = 1:length(new_tracklet_mat.track_class)
    if new_tracklet_mat.track_class(n)>0
        continue
    end
    new_tracklet_mat.track_cluster{length(new_tracklet_mat.track_cluster)+1} = n;
    new_tracklet_mat.track_class(n) = length(new_tracklet_mat.track_cluster);
end


% assign tracklet
N_id = round(sum(new_tracklet_mat.cluster_flag));
N_cluster = length(new_tracklet_mat.track_cluster);
N_fr = track_params.num_fr;
N_tracklet = length(new_tracklet_mat.track_class);
new_track_cluster = new_tracklet_mat.track_cluster;
new_track_class = new_tracklet_mat.track_class;
cluster_params = new_tracklet_mat.cluster_params;
track_interval = new_tracklet_mat.track_interval;
neighbor_track_idx = new_tracklet_mat.neighbor_track_idx;

new_tracklet_mat.track_cluster(N_id+1:end) = [];
new_tracklet_mat2 = updateTrackletMat(new_tracklet_mat);
return

tic
ex_track_idx = cell(1,N_tracklet);
for n = 1:N_tracklet
    t_min = max(track_interval(n,1),track_interval(:,1));
    t_max = min(track_interval(n,2),track_interval(:,2));
    ex_track_idx{n} = find(t_max>=t_min);
    ex_track_idx{n}(ex_track_idx{n}==n) = [];
end
toc

tic
dist_thresh = 0.2;
t_dist_thresh = 15;
sigma = 16;
cluster_map = -1*ones(N_id,N_fr);
pred_map = -1*ones(N_id,N_fr);
pred_x_map = -1*ones(N_id,N_fr);
pred_y_map = -1*ones(N_id,N_fr);
for n = 1:N_id
    t = [];
    x = [];
    y = [];
    for k = 1:length(new_track_cluster{n})
        track_id = new_track_cluster{n}(k);
        temp_t = track_interval(track_id,1):track_interval(track_id,2);
        cluster_map(n,temp_t) = 1;
        temp_t = uniformSample(temp_t, cluster_params.track_len);
        temp_x = new_tracklet_mat.det_x(track_id,temp_t);
        temp_y = new_tracklet_mat.det_y(track_id,temp_t);
        t = [t,temp_t];
        x = [x,temp_x];
        y = [y,temp_y];
    end
    [uniq_t,idx] = unique(t);
    uniq_x = x(idx);
    uniq_y = y(idx);
    t_min = max(min(uniq_t)-t_dist_thresh,1);
    t_max = min(max(uniq_t)+t_dist_thresh,N_fr);
    
    model_x = fitrgp(uniq_t',uniq_x','Basis','linear',...
        'FitMethod','exact','PredictMethod','exact','Sigma',sigma,...
        'ConstantSigma',true,'KernelFunction','matern52','KernelParameters',[1000,1000]);
    pred_x_map(n,t_min:t_max) = (predict(model_x,[t_min:t_max]'))';
    
    model_y = fitrgp(uniq_t',uniq_y','Basis','linear',...
        'FitMethod','exact','PredictMethod','exact','Sigma',sigma,...
        'ConstantSigma',true,'KernelFunction','matern52','KernelParameters',[1000,1000]);
    pred_y_map(n,t_min:t_max) = (predict(model_y,[t_min:t_max]'))';
end
pred_x_map(cluster_map>0) = -1;
pred_y_map(cluster_map>0) = -1;
pred_map(pred_x_map~=-1) = 1;
toc

% tic
% left_id = find(new_tracklet_mat.mask_flag<0.5);
% D = Inf*ones(N_id,N_cluster-N_id);
% parfor n = 1:length(left_id)
%     track_id = left_id(n);
%     temp_interval = track_interval(track_id,:);
%     for k = 1:N_id
%         if ~isempty(intersect(ex_track_idx{track_id},new_track_cluster{k}))
%             continue
%         end
%         if isempty(intersect(neighbor_track_idx{track_id},new_track_cluster{k}))
%             continue
%         end
%         D(k,n) = combCost(track_set, new_tracklet_mat, new_tracklet_mat.cluster_params);
%     end
% end
% toc

tic
left_id = find(new_tracklet_mat.mask_flag<0.5);
D = Inf*ones(N_id,N_cluster-N_id);
parfor n = 1:length(left_id)
    track_id = left_id(n);
    temp_interval = track_interval(track_id,:);
    for k = 1:N_id
        if ~isempty(intersect(ex_track_idx{track_id},new_track_cluster{k}))
            continue
        end
        if isempty(intersect(neighbor_track_idx{track_id},new_track_cluster{k}))
            continue
        end
        temp_t = zeros(1,N_fr);
        temp_t(temp_interval(1):temp_interval(2)) = 1;
        t_idx = (temp_t>0.5 & pred_map(k,:)>0.5);
        if sum(t_idx)<0.5
            continue
        end
        delta_x = new_tracklet_mat.det_x(track_id,t_idx)-pred_x_map(k,t_idx);
        delta_y = new_tracklet_mat.det_y(track_id,t_idx)-pred_y_map(k,t_idx);
        w = new_tracklet_mat.xmax_mat(track_id,t_idx)-new_tracklet_mat.xmin_mat(track_id,t_idx);
        h = new_tracklet_mat.ymax_mat(track_id,t_idx)-new_tracklet_mat.ymin_mat(track_id,t_idx);
        D(k,n) = mean(sqrt(delta_x.^2+delta_y.^2)./sqrt(w.^2+h.^2));
    end
end
toc



tic
update_flag = zeros(1,length(left_id));
while 1
    cluster_change_idx = zeros(1,N_id);
    while 1
        D(:,update_flag==1) = Inf;
        [min_v,idx] = min_mat(D);
        if min_v>dist_thresh
            break
        end
        new_track_cluster{idx(1)} = [new_track_cluster{idx(1)},left_id(idx(2))];
        cluster_change_idx(idx(1)) = 1;
        update_flag(idx(2)) = 1;
        D(:,idx(2)) = Inf;
        
        %%%%%%%%%%%%%%%%%%%%%%%
        for n = 1:length(left_id)
            if update_flag(n)==1 || D(idx(1),n)==Inf
                continue
            end
            track_id = left_id(n);

            if ~isempty(intersect(ex_track_idx{track_id},new_track_cluster{idx(1)}))
                D(idx(1),n) = Inf;
                continue
            end
            
        end
    end
    
    if sum(cluster_change_idx)==0
        break
    end
    
    % update model
    for n = 1:N_id
        if cluster_change_idx(n)==0
            continue
        end
        
        pred_x_map(n,:) = -1;
        pred_y_map(n,:) = -1;
        cluster_map(n,:) = -1;
        t = [];
        x = [];
        y = [];
        for k = 1:length(new_track_cluster{n})
            track_id = new_track_cluster{n}(k);
            temp_t = track_interval(track_id,1):track_interval(track_id,2);
            cluster_map(n,temp_t) = 1;
            temp_t = uniformSample(temp_t, cluster_params.track_len);
            temp_x = new_tracklet_mat.det_x(track_id,temp_t);
            temp_y = new_tracklet_mat.det_y(track_id,temp_t);
            t = [t,temp_t];
            x = [x,temp_x];
            y = [y,temp_y];
        end
        [uniq_t,t_idx] = unique(t);
        uniq_x = x(t_idx);
        uniq_y = y(t_idx);
        t_min = max(min(uniq_t)-t_dist_thresh,1);
        t_max = min(max(uniq_t)+t_dist_thresh,N_fr);
        
        model_x = fitrgp(uniq_t',uniq_x','Basis','linear',...
            'FitMethod','exact','PredictMethod','exact','Sigma',sigma,...
            'ConstantSigma',true,'KernelFunction','matern52','KernelParameters',[1000,1000]);
        pred_x_map(n,t_min:t_max) = (predict(model_x,[t_min:t_max]'))';
        
        model_y = fitrgp(uniq_t',uniq_y','Basis','linear',...
            'FitMethod','exact','PredictMethod','exact','Sigma',sigma,...
            'ConstantSigma',true,'KernelFunction','matern52','KernelParameters',[1000,1000]);
        pred_y_map(n,t_min:t_max) = (predict(model_y,[t_min:t_max]'))';
        pred_map(n,pred_x_map(n,:)~=-1) = 1;
    end
     
    tic
    parfor n = 1:length(left_id)
        if update_flag(n)==1
            continue
        end
        
        track_id = left_id(n);
        temp_interval = track_interval(track_id,:);
        for k = 1:N_id
            if cluster_change_idx(k)==0
                continue
            end
            
            if ~isempty(intersect(ex_track_idx{track_id},new_track_cluster{k}))
                continue
            end
            if isempty(intersect(neighbor_track_idx{track_id},new_track_cluster{k}))
                continue
            end
            temp_t = zeros(1,N_fr);
            temp_t(temp_interval(1):temp_interval(2)) = 1;
            t_idx = (temp_t>0.5 & pred_map(k,:)>0.5);
            delta_x = new_tracklet_mat.det_x(track_id,t_idx)-pred_x_map(k,t_idx);
            delta_y = new_tracklet_mat.det_y(track_id,t_idx)-pred_y_map(k,t_idx);
            w = new_tracklet_mat.xmax_mat(track_id,t_idx)-new_tracklet_mat.xmin_mat(track_id,t_idx);
            h = new_tracklet_mat.ymax_mat(track_id,t_idx)-new_tracklet_mat.ymin_mat(track_id,t_idx);
            D(k,n) = mean(sqrt(delta_x.^2+delta_y.^2)./sqrt(w.^2+h.^2));
        end
    end
    toc
end
new_tracklet_mat.track_cluster = new_track_cluster(1:N_id);
toc

new_tracklet_mat2 = updateTrackletMat(new_tracklet_mat);