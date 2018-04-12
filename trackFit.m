function fit_cost = trackFit(tracklet_mat, road_track, max_dist_thresh)

N_road_track = length(road_track);
near_track_mat = associateDetToTrack(tracklet_mat, road_track, max_dist_thresh);
N_tracklet = size(near_track_mat{1},1);

mask = tracklet_mat.xmin_mat>=0;
tracklet_center_x = zeros(size(mask));
tracklet_center_y = zeros(size(mask));
tracklet_center_x(mask) = 0.5*(tracklet_mat.xmin_mat(mask)+tracklet_mat.xmax_mat(mask));
tracklet_center_y(mask) = tracklet_mat.ymax_mat(mask);
Dx = cell(1,N_road_track);
Dy = cell(1,N_road_track);
fit_cost = -1*ones(N_tracklet,N_road_track);
for n = 1:N_road_track
    temp_mask = near_track_mat{n}>0;
    track_fr_num = sum(temp_mask,2);
    cand_idx = track_fr_num>0;
    
    Dx{n} = zeros(size(near_track_mat{n}));
    Dy{n} = zeros(size(near_track_mat{n}));
    Dx{n}(temp_mask) = tracklet_center_x(temp_mask)-road_track{n}(near_track_mat{n}(temp_mask),1);
    Dy{n}(temp_mask) = tracklet_center_y(temp_mask)-road_track{n}(near_track_mat{n}(temp_mask),2);
    
    mean_x = sum(Dx{n}(cand_idx,:),2)./track_fr_num(cand_idx);
    mean_y = sum(Dy{n}(cand_idx,:),2)./track_fr_num(cand_idx);
    mean_x = min(max(mean_x,-100),100);
    mean_y = min(max(mean_y,-100),100);
    Dx{n}(cand_idx,:) = bsxfun(@minus,Dx{n}(cand_idx,:),mean_x);
    Dy{n}(cand_idx,:) = bsxfun(@minus,Dy{n}(cand_idx,:),mean_y);
    
    Dx{n}(~temp_mask) = 0;
    Dy{n}(~temp_mask) = 0;
    fit_cost(cand_idx,n) = sum(sqrt(Dx{n}(cand_idx,:).^2+Dy{n}(cand_idx,:).^2),2);
end
fit_cost(fit_cost<0) = Inf;
