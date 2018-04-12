function neighbor_idx = getNeighborTrack(track_interval, t_dist_thresh, intersect_ratio)

N_tracklet = size(track_interval,1);
neighbor_idx = cell(1,N_tracklet);
for n = 1:N_tracklet
    cand_idx = find(track_interval(n,1)-track_interval(:,2)<t_dist_thresh & track_interval(:,1)-track_interval(n,2)<t_dist_thresh);
    if isempty(cand_idx)
        continue
    end
    remove_idx = [];
    vec_idx1 = track_interval(n,1):track_interval(n,2);
    for k = 1:length(cand_idx)
        vec_idx2 = track_interval(cand_idx(k),1):track_interval(cand_idx(k),2);
        vec_idx3 = intersect(vec_idx1,vec_idx2);
        if length(vec_idx3)/min(length(vec_idx1),length(vec_idx3))>intersect_ratio
            remove_idx = [remove_idx,k];
        end
    end
    cand_idx(remove_idx) = [];
    if isempty(cand_idx)
        continue
    end
    neighbor_idx{n} = cand_idx;
end