function [cost,diff_cost,new_cluster_cost,new_cluster_set,change_cluster_idx,f] = ...
    getBreakCost(track_id,track_cluster,track_class,tracklet_mat,...
    prev_cost,cluster_params)

new_cluster_cost = zeros(2,5);
if length(track_cluster{track_class(track_id)})<=2
    cost = Inf;
    diff_cost = Inf;
    new_cluster_cost = [];
    new_cluster_set = [];
    change_cluster_idx = [];
    f = [];
    return
end

% get cost
track_ids = track_cluster{track_class(track_id)};
track_interval = tracklet_mat.track_interval;
after_ids = track_ids(track_interval(track_ids,2)>track_interval(track_id,2));
if isempty(after_ids)
    cost = Inf;
    diff_cost = Inf;
    new_cluster_cost = [];
    new_cluster_set = [];
    change_cluster_idx = [];
    f =[];
    return
else
    before_ids = setdiff(track_ids,after_ids);
    if length(before_ids)<=1
        cost = Inf;
        diff_cost = Inf;
        new_cluster_cost = [];
        new_cluster_set = [];
        change_cluster_idx = [];
        f = [];
        return
    end
    change_cluster_idx = [length(track_cluster)+1,track_class(track_id)];
    new_cluster_set = cell(1,2);
    new_cluster_set{1} = before_ids;
    remain_tracks = after_ids;
    new_cluster_set{2} = remain_tracks;
    new_cluster_cost(1,:) = combCost(new_cluster_set{1}, tracklet_mat, cluster_params);
    new_cluster_cost(2,:) = combCost(new_cluster_set{2}, tracklet_mat, cluster_params);
    cost = sum(new_cluster_cost);
    f = cost-prev_cost;
    diff_cost = f*[cluster_params.lambda_split,cluster_params.lambda_reg,...
        cluster_params.lambda_color,cluster_params.lambda_grad,cluster_params.lambda_time]';
end
