function new_tracklet_mat = updateTrackletMat(tracklet_mat)

new_tracklet_mat = tracklet_mat;
track_interval = tracklet_mat.track_interval;
num_cluster = sum(tracklet_mat.cluster_flag);

new_xmin_mat = -1*ones(num_cluster,size(new_tracklet_mat.xmin_mat,2));
new_ymin_mat = -1*ones(num_cluster,size(new_tracklet_mat.xmin_mat,2));
new_xmax_mat = -1*ones(num_cluster,size(new_tracklet_mat.xmin_mat,2));
new_ymax_mat = -1*ones(num_cluster,size(new_tracklet_mat.xmin_mat,2));
new_color_mat = -1*ones(num_cluster,size(new_tracklet_mat.xmin_mat,2),3);
new_class_mat = cell(num_cluster,size(new_tracklet_mat.xmin_mat,2));
new_det_score_mat = -1*ones(num_cluster,size(new_tracklet_mat.xmin_mat,2));

for n = 1:num_cluster

    for k = 1:length(new_tracklet_mat.track_cluster{n})
        temp_id = new_tracklet_mat.track_cluster{n}(k);
        new_xmin_mat(n,track_interval(temp_id,1):track_interval(temp_id,2)) = ...
            new_tracklet_mat.xmin_mat(temp_id,track_interval(temp_id,1):track_interval(temp_id,2));
        new_ymin_mat(n,track_interval(temp_id,1):track_interval(temp_id,2)) = ...
            new_tracklet_mat.ymin_mat(temp_id,track_interval(temp_id,1):track_interval(temp_id,2));
        new_xmax_mat(n,track_interval(temp_id,1):track_interval(temp_id,2)) = ...
            new_tracklet_mat.xmax_mat(temp_id,track_interval(temp_id,1):track_interval(temp_id,2));
        new_ymax_mat(n,track_interval(temp_id,1):track_interval(temp_id,2)) = ...
            new_tracklet_mat.ymax_mat(temp_id,track_interval(temp_id,1):track_interval(temp_id,2));
        
        new_color_mat(n,track_interval(temp_id,1):track_interval(temp_id,2),:) = ...
            new_tracklet_mat.color_mat(temp_id,track_interval(temp_id,1):track_interval(temp_id,2),:);
        
        new_class_mat(n,track_interval(temp_id,1):track_interval(temp_id,2)) = ...
            new_tracklet_mat.class_mat(temp_id,track_interval(temp_id,1):track_interval(temp_id,2));
        
        new_det_score_mat(n,track_interval(temp_id,1):track_interval(temp_id,2)) = ...
            new_tracklet_mat.det_score_mat(temp_id,track_interval(temp_id,1):track_interval(temp_id,2));
    end
end
new_tracklet_mat.xmin_mat = new_xmin_mat;
new_tracklet_mat.ymin_mat = new_ymin_mat;
new_tracklet_mat.xmax_mat = new_xmax_mat;
new_tracklet_mat.ymax_mat = new_ymax_mat;
new_tracklet_mat.color_mat = new_color_mat;
new_tracklet_mat.class_mat = new_class_mat;
new_tracklet_mat.det_score_mat = new_det_score_mat;