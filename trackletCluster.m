function [new_track_cluster, new_track_class, new_prev_cluster_cost,...
    new_f_mat,new_track_change_set] = trackletCluster(tracklet_mat, track_interval, track_cluster, ...
    track_class, prev_cluster_cost, neighbor_track_idx,cluster_params,f_mat,track_change_set)

new_track_cluster = track_cluster;
new_track_class = track_class;
new_prev_cluster_cost = prev_cluster_cost;
new_f_mat = f_mat;
new_track_change_set = track_change_set;


[~,sort_track_idx] = sort(track_interval(:,2),'ascend');
for n = 1:length(sort_track_idx)
%     tic
    track_id = sort_track_idx(n);
    if new_track_class(track_id)<0
        continue
    end
    
    diff_cost = zeros(5,1);
    new_C = cell(5,1);
    new_set = cell(5,1);
    change_idx = cell(5,1);
    f = cell(1,5);
    [~,diff_cost(1),new_C{1},new_set{1},change_idx{1},f{1}] = ...
        getSplitCost(track_id,new_track_cluster,new_track_class,tracklet_mat,...
        new_prev_cluster_cost(new_track_class(track_id),:),cluster_params);
    
    [~,diff_cost(2),new_C{2},new_set{2},change_idx{2},f{2}] = ...
        getAssignCost(track_id, tracklet_mat, track_interval, ...
        new_track_cluster, new_track_class, neighbor_track_idx, ...
        new_prev_cluster_cost,cluster_params,[]);
    
    [~,diff_cost(3),new_C{3},new_set{3},change_idx{3},f{3}] = ...
        getMergeCost(track_id, tracklet_mat, track_interval, ...
        new_track_cluster, new_track_class, neighbor_track_idx, ...
        new_prev_cluster_cost,cluster_params);
    
    [~,diff_cost(4),new_C{4},new_set{4},change_idx{4},f{4}] = ...
        getSwitchCost(track_id, tracklet_mat, track_interval, ...
        new_track_cluster, new_track_class, neighbor_track_idx, ...
        new_prev_cluster_cost,cluster_params);
    
    [~,diff_cost(5),new_C{5},new_set{5},change_idx{5},f{5}] = ...
        getBreakCost(track_id,new_track_cluster,new_track_class,tracklet_mat,...
        new_prev_cluster_cost(new_track_class(track_id),:),cluster_params);
    
    for k = 1:length(f)
        if diff_cost(k)==Inf
            continue
        end
        cnt_id = length(new_track_change_set)+1;
        if cnt_id>size(new_f_mat,1)
            temp_f = zeros(size(new_f_mat,1)*2,6);
            temp_f(1:size(new_f_mat,1),:) = new_f_mat;
            new_f_mat = temp_f;
        end
        
        temp_f = f{k};
        min_diff = min(sum(abs(bsxfun(@minus,new_f_mat(:,1:5),temp_f)),2));
        if min_diff<1e-6
            continue
        end
        if diff_cost(k)<0
            new_f_mat(cnt_id,1:5) = f{k};
            new_f_mat(cnt_id,6) = -1;
            if change_idx{k}(1)>length(new_track_cluster)
                new_track_change_set{cnt_id}{1}{1} = [];
            else
                new_track_change_set{cnt_id}{1}{1} = new_track_cluster{change_idx{k}(1)};
            end
            if change_idx{k}(2)>length(new_track_cluster)
                new_track_change_set{cnt_id}{1}{2} = [];
            else
                new_track_change_set{cnt_id}{1}{2} = new_track_cluster{change_idx{k}(2)};
            end
            new_track_change_set{cnt_id}{2}{1} = new_set{k}{1};
            new_track_change_set{cnt_id}{2}{2} = new_set{k}{2};
        end
        if diff_cost(k)>0
            new_f_mat(cnt_id,1:5) = f{k};
            new_f_mat(cnt_id,6) = 1;
            if change_idx{k}(1)>length(new_track_cluster)
                new_track_change_set{cnt_id}{1}{1} = [];
            else
                new_track_change_set{cnt_id}{1}{1} = new_track_cluster{change_idx{k}(1)};
            end
            if change_idx{k}(2)>length(new_track_cluster)
                new_track_change_set{cnt_id}{1}{2} = [];
            else
                new_track_change_set{cnt_id}{1}{2} = new_track_cluster{change_idx{k}(2)};
            end
            new_track_change_set{cnt_id}{2}{1} = new_set{k}{1};
            new_track_change_set{cnt_id}{2}{2} = new_set{k}{2};
        end
        
    end
    [min_cost,min_idx] = min(diff_cost);
    if min_cost>=0 
        continue
    end
    
    new_track_cluster{change_idx{min_idx}(1)} = new_set{min_idx}{1};
    new_track_cluster{change_idx{min_idx}(2)} = new_set{min_idx}{2};
    new_prev_cluster_cost(change_idx{min_idx}(1),:) = new_C{min_idx}(1,:);
    new_prev_cluster_cost(change_idx{min_idx}(2),:) = new_C{min_idx}(2,:);
    
    for k = 1:length(new_track_cluster{change_idx{min_idx}(1)})
        new_track_class(new_track_cluster{change_idx{min_idx}(1)}(k)) = change_idx{min_idx}(1);
    end
    for k = 1:length(new_track_cluster{change_idx{min_idx}(2)})
        new_track_class(new_track_cluster{change_idx{min_idx}(2)}(k)) = change_idx{min_idx}(2);
    end
    
end