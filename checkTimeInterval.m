function T = checkTimeInterval(tracklet_mat)

track_interval = tracklet_mat.track_interval;
N_tracklet = length(tracklet_mat.track_cluster);
T = zeros(1,N_tracklet);
for n = 1:N_tracklet
    if isempty(tracklet_mat.track_cluster{n})
        continue
    end
    temp_interval = track_interval(tracklet_mat.track_cluster{n},:);
    t_min = min(temp_interval(:,1));
    t_max = max(temp_interval(:,2));
    T(n) = t_max-t_min+1;
end
