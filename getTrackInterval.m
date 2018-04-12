function track_interval = getTrackInterval(tracklet_mat)

N_tracklet = size(tracklet_mat.xmin_mat,1);
track_interval = zeros(N_tracklet,2);
cand_idx = find(tracklet_mat.xmin_mat>=0);
min_mask = Inf*ones(size(tracklet_mat.xmin_mat));
min_mask(cand_idx) = cand_idx;
[min_v,track_interval(:,1)] = min(min_mask,[],2);
track_interval(min_v==Inf,1) = -1;
max_mask = -1*ones(size(tracklet_mat.xmin_mat));
max_mask(cand_idx) = cand_idx;
[max_v,track_interval(:,2)] = max(max_mask,[],2);
track_interval(max_v==0,2) = -1;