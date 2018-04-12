function near_track_mat = associateDetToTrack(tracklet_mat, road_track, max_dist_thresh)

N_road_track = length(road_track);
near_track_mat = cell(1,N_road_track);
for n = 1:N_road_track
    near_track_mat{n} = -1*ones(size(tracklet_mat.xmin_mat));
end

det_idx = find(tracklet_mat.xmin_mat>=0 & tracklet_mat.xmax_mat>=0 &...
                tracklet_mat.ymin_mat>=0 & tracklet_mat.ymax_mat>=0);
det_pts = [0.5*(tracklet_mat.xmin_mat(det_idx)+tracklet_mat.xmax_mat(det_idx)),...
    tracklet_mat.ymax_mat(det_idx)];

for n = 1:N_road_track
    D = pdist2(det_pts,road_track{n});
    [min_dist,min_idx] = min(D,[],2);   
    near_track_mat{n}(det_idx(min_dist<max_dist_thresh)) = min_idx(min_dist<max_dist_thresh);
end

% make near_idx non-decreasing
N_tracklet = size(near_track_mat{1},1);
for n = 1:N_road_track
    for k = 1:N_tracklet
        row_mask = near_track_mat{n}(k,:)>0;
        near_idx = near_track_mat{n}(k,row_mask);
        for kk = 2:length(near_idx)
            near_idx(kk) = max(near_idx(kk),near_idx(kk-1));
        end
        near_track_mat{n}(k,row_mask) = near_idx;
    end
end