function new_tracklet_mat = preprocessing(tracklet_mat, len_thresh)

new_tracklet_mat = tracklet_mat;
N_tracklet = size(tracklet_mat.xmin_mat,1);
remove_idx = [];
for n = 1:N_tracklet
    t = find(tracklet_mat.xmin_mat(n,:)>=0);
    if length(t)<len_thresh
        remove_idx = [remove_idx,n];
    end
end

new_tracklet_mat.mask_flag(remove_idx) = 0;
% new_tracklet_mat.xmin_mat(remove_idx,:) = [];
% new_tracklet_mat.ymin_mat(remove_idx,:) = [];
% new_tracklet_mat.xmax_mat(remove_idx,:) = [];
% new_tracklet_mat.ymax_mat(remove_idx,:) = [];
% new_tracklet_mat.color_mat(remove_idx,:,:) = [];
% new_tracklet_mat.class_mat(remove_idx,:) = [];
% new_tracklet_mat.det_score_mat(remove_idx,:) = [];