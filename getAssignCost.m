function [cost,diff_cost,new_cluster_cost,new_cluster_set,change_cluster_idx,f] = ...
    getAssignCost(track_id, tracklet_mat, track_interval, ...
    track_cluster, track_class, neighbor_track_idx, ...
    prev_cluster_cost,cluster_params, cluster_flag)

intersect_ratio_thresh = cluster_params.intersect_ratio_thresh;

cluster1 = track_cluster{track_class(track_id)};
new_cluster_cost = zeros(2,5);
new_cluster_set = cell(1,2);
new_cluster_set{1} = cluster1;
new_cluster_set{1}(new_cluster_set{1}==track_id) = [];

% get cost
if ~isempty(new_cluster_set{1})    
    new_cluster_cost(1,:) = combCost(new_cluster_set{1}, tracklet_mat, cluster_params);
end

N_cluster = length(track_cluster);
if isempty(cluster_flag)
    N_cand = length(track_cluster);
else
    N_cand = round(sum(cluster_flag));
end
temp_new_cluster_cost = Inf*ones(N_cluster,5);
prev_cost_vec = zeros(N_cluster,5);
for n = 1:N_cand
    % the original cluster
    if track_class(track_id)==n
        continue
    end
    
    % no neighbor track
    neighbor_track = intersect(neighbor_track_idx{track_id},track_cluster{n});
    if isempty(neighbor_track)
        continue
    end
    
    % check overlap
    cluster_size = length(track_cluster{n});
    if cluster_size==0
        continue
    end
    for k = 1:cluster_size
        overlap_ratio = overlapCheck(track_interval(track_cluster{n}(k),:),track_interval(track_id,:));
        if overlap_ratio>intersect_ratio_thresh
            break
        end
    end
    if overlap_ratio>intersect_ratio_thresh
        continue
    end
    
    % get cost
    temp_set = [track_id,track_cluster{n}];
    temp_new_cluster_cost(n,:) = combCost(temp_set, tracklet_mat, cluster_params);
    prev_cost_vec(n,:) = prev_cluster_cost(track_class(track_id),:)+prev_cluster_cost(n,:);
end
cost_vec = bsxfun(@plus,temp_new_cluster_cost,new_cluster_cost(1,:));
diff_cost_vec = (cost_vec-prev_cost_vec)*[cluster_params.lambda_split,cluster_params.lambda_reg,...
    cluster_params.lambda_color,cluster_params.lambda_grad,cluster_params.lambda_time]';
[~,min_idx] = min(diff_cost_vec);
cost = cost_vec(min_idx);
if cost==Inf
    diff_cost = Inf;
    new_cluster_cost = [];
    new_cluster_set = [];
    change_cluster_idx = [];
    f = [];
    return
end
diff_cost = diff_cost_vec(min_idx);
f = cost_vec(min_idx,:)-prev_cost_vec(min_idx,:);
new_cluster_cost(2,:) = temp_new_cluster_cost(min_idx,:);

change_cluster_idx = [track_class(track_id),min_idx];
new_cluster_set{2} = [track_id,track_cluster{min_idx}];