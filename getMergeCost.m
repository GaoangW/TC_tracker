function [cost,diff_cost,new_cluster_cost,new_cluster_set,change_cluster_idx,f] = ...
    getMergeCost(track_id, tracklet_mat, track_interval, ...
    track_cluster, track_class, neighbor_track_idx, ...
    prev_cluster_cost,cluster_params)

intersect_ratio_thresh = cluster_params.intersect_ratio_thresh;

cluster1 = track_cluster{track_class(track_id)};
if length(cluster1)==1
    cost = Inf;
    diff_cost = Inf;
    new_cluster_cost = [];
    new_cluster_set = [];
    change_cluster_idx = [];
    f = [];
    return
end

N_cluster = length(track_cluster);
new_cluster_cost_vec = Inf*ones(N_cluster,5);
prev_cost_vec = zeros(N_cluster,5);
for n = 1:N_cluster
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
    for k1 = 1:length(cluster1)
        for k2 = 1:cluster_size
            overlap_ratio = overlapCheck(track_interval(track_cluster{n}(k2),:),track_interval(cluster1(k1),:));
            if overlap_ratio>intersect_ratio_thresh
                break
            end
        end
        if overlap_ratio>intersect_ratio_thresh
            break
        end
    end
    if overlap_ratio>intersect_ratio_thresh
        continue
    end
    
    % get cost
    new_cluster_cost_vec(n,:) = combCost([cluster1,track_cluster{n}], tracklet_mat, cluster_params);
    prev_cost_vec(n,:) = prev_cluster_cost(track_class(track_id),:)+prev_cluster_cost(n,:);
end

diff_cost_vec = (new_cluster_cost_vec-prev_cost_vec)*[cluster_params.lambda_split,cluster_params.lambda_reg,...
    cluster_params.lambda_color,cluster_params.lambda_grad,cluster_params.lambda_time]';
[~,min_idx] = min(diff_cost_vec);
cost = new_cluster_cost_vec(min_idx,:);
if cost==Inf
    diff_cost = Inf;
    new_cluster_cost = [];
    new_cluster_set = [];
    change_cluster_idx = [];
    f = [];
    return
end
diff_cost = diff_cost_vec(min_idx);
f = new_cluster_cost_vec(min_idx,:)-prev_cost_vec(min_idx,:);
new_cluster_cost = zeros(2,5);
new_cluster_cost(1,:) = cost;

change_cluster_idx = [track_class(track_id),min_idx];
new_cluster_set = cell(1,2);
new_cluster_set{1} = [cluster1,track_cluster{min_idx}];