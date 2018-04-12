function [cost,diff_cost,new_cluster_cost,new_cluster_set,change_cluster_idx,f] = ...
    getSwitchCost(track_id, tracklet_mat, track_interval, ...
    track_cluster, track_class, neighbor_track_idx, ...
    prev_cluster_cost,cluster_params)

cluster1 = track_cluster{track_class(track_id)};
S1 = [];
S2 = [];
for k = 1:length(cluster1)
    temp_id = cluster1(k);
    if track_interval(temp_id,2)<=track_interval(track_id,2)
        S1 = [S1,temp_id];
    else
        S2 = [S2,temp_id];
    end
end


N_cluster = length(track_cluster);
cost_vec = Inf*ones(N_cluster,5);
prev_cost_vec = zeros(N_cluster,5);
new_cluster_cost_vec1 = Inf*ones(N_cluster,5);
new_cluster_cost_vec2 = Inf*ones(N_cluster,5);
track_id_set = cell(N_cluster,5);
t_max_fr = size(tracklet_mat.xmin_mat,2);
for n = 1:N_cluster
    % swich availability check
    stop_flag = 1;
    cluster_size = length(track_cluster{n});
    if cluster_size==0
        continue
    end
    for k = 1:cluster_size
        if ismember(track_cluster{n}(k),neighbor_track_idx{track_id})
            stop_flag = 0;
            break
        end
    end
    if stop_flag==1
        continue
    end
    
    cand_track_invertal = track_interval(track_cluster{n},:);
    t_min = min(cand_track_invertal(:,1));
    t_max = max(cand_track_invertal(:,2));
    t_check = -1*ones(1,t_max_fr);
    for k = 1:cluster_size
        t_check(cand_track_invertal(k,1):cand_track_invertal(k,2)) = 1;
    end
    if t_check(track_interval(track_id,2))==1
        continue
    end
    %%%%%%%%%%%%%%%%
%     if (track_interval(track_id,2)<t_min || track_interval(track_id,2)>t_max) 
%         continue
%     end
    
    % get cost    
    S3 = [];
    S4 = [];   
    
    for k = 1:cluster_size
        temp_id = track_cluster{n}(k);
        if track_interval(temp_id,2)<=track_interval(track_id,2)
            S3 = [S3,temp_id];
        else
            S4 = [S4,temp_id];
        end
    end
    
    S_1 = [S1,S4];
    S_2 = [S3,S2];
    
    neighbor_set1 = [];
    for k = 1:length(S1)
        neighbor_set1 = [neighbor_set1;neighbor_track_idx{S1(k)}];
    end
    neighbor_set1 = unique(neighbor_set1);
    if isempty(intersect(neighbor_set1,S4'))
        continue
    end
    
    neighbor_set2 = [];
    for k = 1:length(S3)
        neighbor_set2 = [neighbor_set2;neighbor_track_idx{S3(k)}];
    end
    neighbor_set2 = unique(neighbor_set2);
    if isempty(intersect(neighbor_set2,S2'))
        continue
    end
    
    
    new_cluster_cost_vec1(n,:) = combCost(S_1, tracklet_mat, cluster_params);
    new_cluster_cost_vec2(n,:) = combCost(S_2, tracklet_mat, cluster_params);
    cost_vec(n,:) = new_cluster_cost_vec1(n,:)+new_cluster_cost_vec2(n,:);
    
    track_id_set{n} = cell(1,2);
    track_id_set{n}{1} = S_1;
    track_id_set{n}{2} = S_2;
    
    prev_cost_vec(n,:) = prev_cluster_cost(track_class(track_id),:)+prev_cluster_cost(n,:);
end

diff_cost_vec = (cost_vec-prev_cost_vec)*[cluster_params.lambda_split,cluster_params.lambda_reg,...
    cluster_params.lambda_color,cluster_params.lambda_grad,cluster_params.lambda_time]';
[~,min_idx] = min(diff_cost_vec);
f = cost_vec(min_idx,:)-prev_cost_vec(min_idx,:);
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
new_cluster_cost = zeros(2,5);
new_cluster_cost(1,:) = new_cluster_cost_vec1(min_idx,:);
new_cluster_cost(2,:) = new_cluster_cost_vec2(min_idx,:);
% new_cluster_cost = new_cluster_cost_vec(:,min_idx);

change_cluster_idx = [track_class(track_id), min_idx];
new_cluster_set = cell(1,2);
new_cluster_set{1} = track_id_set{min_idx}{1};
new_cluster_set{2} = track_id_set{min_idx}{2};