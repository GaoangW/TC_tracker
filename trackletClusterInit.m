function [new_tracklet_mat,flag,cnt] = trackletClusterInit(tracklet_mat,param)

cluster_params.t_dist_thresh = 20;
cluster_params.lambda_time = param.lambda_time;
cluster_params.intersect_ratio_thresh = 0.2;
cluster_params.len_tracklet_thresh = 2;
cluster_params.lambda_split = param.lambda_split;
cluster_params.small_track_cost = 0.1;
cluster_params.sigma = 8;
cluster_params.track_len = 25;
cluster_params.lambda_reg = param.lambda_reg;
cluster_params.lambda_color = param.lambda_color;
cluster_params.color_sample_size = 5;
cluster_params.lambda_grad = param.lambda_grad;

new_tracklet_mat = tracklet_mat;

if ~isfield(new_tracklet_mat,'cluster_params')
    new_tracklet_mat.cluster_params = cluster_params;
end

if ~isfield(new_tracklet_mat,'track_interval')
    new_tracklet_mat.track_interval = getTrackInterval(new_tracklet_mat);
end

if ~isfield(new_tracklet_mat,'track_class')
    new_tracklet_mat.track_class = round(cumsum(new_tracklet_mat.mask_flag));
    new_tracklet_mat.track_class(new_tracklet_mat.mask_flag<0.5) = -1;
end

if ~isfield(new_tracklet_mat,'track_cluster')
    N_cluster = max(new_tracklet_mat.track_class);
    new_tracklet_mat.track_cluster = cell(1,N_cluster);
    for n = 1:N_cluster
        new_tracklet_mat.track_cluster{n} = find(new_tracklet_mat.track_class==n,1);
    end
end

if ~isfield(new_tracklet_mat,'neighbor_track_idx')
    new_tracklet_mat.neighbor_track_idx = getNeighborTrack(new_tracklet_mat.track_interval, ...
        cluster_params.t_dist_thresh, cluster_params.intersect_ratio_thresh);
end

if ~isfield(new_tracklet_mat,'det_x') || ~isfield(new_tracklet_mat,'det_y')
    new_tracklet_mat = bboxToPoint(new_tracklet_mat);
end

if ~isfield(new_tracklet_mat,'cluster_cost')
    N_cluster = max(new_tracklet_mat.track_class);
    new_tracklet_mat.cluster_cost = zeros(N_cluster,5);
    new_tracklet_mat.cluster_cost(:,1) = 1;
end

if ~isfield(new_tracklet_mat,'f_mat') 
    new_tracklet_mat.f_mat = zeros(1000,6);
end

if ~isfield(new_tracklet_mat,'track_change_set') 
    new_tracklet_mat.track_change_set = [];
end

prev_track_cluster = new_tracklet_mat.track_cluster;
[new_tracklet_mat.track_cluster, new_tracklet_mat.track_class, new_tracklet_mat.cluster_cost,...
    new_tracklet_mat.f_mat,new_tracklet_mat.track_change_set] = trackletCluster(new_tracklet_mat, ...
    new_tracklet_mat.track_interval, new_tracklet_mat.track_cluster, ...
    new_tracklet_mat.track_class, new_tracklet_mat.cluster_cost, new_tracklet_mat.neighbor_track_idx, ...
    cluster_params,new_tracklet_mat.f_mat,new_tracklet_mat.track_change_set);

flag = sameCheck(prev_track_cluster,new_tracklet_mat.track_cluster);

cnt = 0;
for n = 1:length(new_tracklet_mat.track_cluster)
    if length(new_tracklet_mat.track_cluster{n})>=1
        cnt = cnt+1;
    end
end