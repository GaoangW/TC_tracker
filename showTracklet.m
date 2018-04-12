function showTracklet(track_ids, tracklet_mat, marker_set, color_flag)

if isempty(track_ids)
    return
end
figure, 
for n = 1:length(track_ids)
    t = find(tracklet_mat.xmin_mat(track_ids(n),:)>=0);
    det_pts = [0.5*(tracklet_mat.xmin_mat(track_ids(n),t)'+tracklet_mat.xmax_mat(track_ids(n),t)')+1,...
        tracklet_mat.ymax_mat(track_ids(n),t)'+1];
    if n>length(marker_set)
        plot(t, det_pts(:,1), marker_set{end});hold on
    else
        plot(t, det_pts(:,1), marker_set{n});hold on
    end
end

figure, 
for n = 1:length(track_ids)
    t = find(tracklet_mat.xmin_mat(track_ids(n),:)>=0);
    det_pts = [0.5*(tracklet_mat.xmin_mat(track_ids(n),t)'+tracklet_mat.xmax_mat(track_ids(n),t)')+1,...
        tracklet_mat.ymax_mat(track_ids(n),t)'+1];
    if n>length(marker_set)
        plot(t, det_pts(:,2),marker_set{end});hold on
    else
        plot(t, det_pts(:,2),marker_set{n});hold on
    end
end

if color_flag==0
    return
end

figure, 
for n = 1:length(track_ids)
    t = find(tracklet_mat.xmin_mat(track_ids(n),:)>=0);
    if n>length(marker_set)
        plot(t, tracklet_mat.color_mat(track_ids(n),t,1),marker_set{end});hold on
    else
        plot(t, tracklet_mat.color_mat(track_ids(n),t,1),marker_set{n});hold on
    end
end

figure, 
for n = 1:length(track_ids)
    t = find(tracklet_mat.xmin_mat(track_ids(n),:)>=0);
    if n>length(marker_set)
        plot(t, tracklet_mat.color_mat(track_ids(n),t,2),marker_set{end});hold on
    else
        plot(t, tracklet_mat.color_mat(track_ids(n),t,2),marker_set{n});hold on
    end
end

figure, 
for n = 1:length(track_ids)
    t = find(tracklet_mat.xmin_mat(track_ids(n),:)>=0);
    if n>length(marker_set)
        plot(t, tracklet_mat.color_mat(track_ids(n),t,3),marker_set{end});hold on
    else
        plot(t, tracklet_mat.color_mat(track_ids(n),t,3),marker_set{n});hold on
    end
end

