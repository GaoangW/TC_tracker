function new_tracklet_mat = bboxToPoint(tracklet_mat)

new_tracklet_mat = tracklet_mat;
new_tracklet_mat.det_x = 0.5*(tracklet_mat.xmin_mat+tracklet_mat.xmax_mat)+1;
new_tracklet_mat.det_y = 0.5*(tracklet_mat.ymax_mat+tracklet_mat.ymax_mat)+1;
new_tracklet_mat.det_x(new_tracklet_mat.det_x<0) = -1;
new_tracklet_mat.det_y(new_tracklet_mat.det_y<0) = -1;