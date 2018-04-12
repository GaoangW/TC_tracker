function new_tracklet_mat = sampleSubSet(tracklet_mat, track_id)

new_tracklet_mat.xmin_mat = tracklet_mat.xmin_mat(track_id,:);
new_tracklet_mat.ymin_mat = tracklet_mat.ymin_mat(track_id,:);
new_tracklet_mat.xmax_mat = tracklet_mat.xmax_mat(track_id,:);
new_tracklet_mat.ymax_mat = tracklet_mat.ymax_mat(track_id,:);
new_tracklet_mat.color_mat = tracklet_mat.color_mat(track_id,:,:);