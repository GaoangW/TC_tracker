function [new_track_obj1, new_track_obj2, new_tracklet_mat, new_track_params] = forwardTracking(...
    track_obj1, track_obj2, track_params, fr_idx2, tracklet_mat, img1, img2)

new_track_params = track_params;
new_track_obj1 = track_obj1;
new_track_obj2 = track_obj2;
new_tracklet_mat = tracklet_mat;

if new_track_params.max_track_id==0
    new_track_obj1.track_id = 1:size(new_track_obj1.bbox,1);
    track_params.max_track_id = size(new_track_obj1.bbox,1);
    new_track_params.max_track_id = track_params.max_track_id;
    new_tracklet_mat.xmin_mat = -1*ones(size(new_track_obj1.bbox,1),new_track_params.num_fr);
    new_tracklet_mat.ymin_mat = -1*ones(size(new_track_obj1.bbox,1),new_track_params.num_fr);
    new_tracklet_mat.xmax_mat = -1*ones(size(new_track_obj1.bbox,1),new_track_params.num_fr);
    new_tracklet_mat.ymax_mat = -1*ones(size(new_track_obj1.bbox,1),new_track_params.num_fr);
    new_tracklet_mat.color_mat = -1*ones(size(new_track_obj1.bbox,1),new_track_params.num_fr,3);
    new_tracklet_mat.class_mat = cell(size(new_track_obj1.bbox,1),new_track_params.num_fr);
    new_tracklet_mat.det_score_mat = -1*ones(size(new_track_obj1.bbox,1),new_track_params.num_fr);
    new_tracklet_mat.mask_flag = new_track_obj1.mask_flag;
    for n = 1:size(new_track_obj1.bbox,1)
        new_tracklet_mat.xmin_mat(n,fr_idx2-1) = new_track_obj1.bbox(n,1);
        new_tracklet_mat.ymin_mat(n,fr_idx2-1) = new_track_obj1.bbox(n,2);
        new_tracklet_mat.xmax_mat(n,fr_idx2-1) = new_track_obj1.bbox(n,1)+...
            new_track_obj1.bbox(n,3)-1;
        new_tracklet_mat.ymax_mat(n,fr_idx2-1) = new_track_obj1.bbox(n,2)+...
            new_track_obj1.bbox(n,4)-1;
        
        bbox_img = img1(new_tracklet_mat.ymin_mat(n,fr_idx2-1):new_tracklet_mat.ymax_mat(n,fr_idx2-1),...
            new_tracklet_mat.xmin_mat(n,fr_idx2-1):new_tracklet_mat.xmax_mat(n,fr_idx2-1),:);
        new_tracklet_mat.color_mat(n,fr_idx2-1,1) = mean(mean(bbox_img(:,:,1)));
        new_tracklet_mat.color_mat(n,fr_idx2-1,2) = mean(mean(bbox_img(:,:,2)));
        new_tracklet_mat.color_mat(n,fr_idx2-1,3) = mean(mean(bbox_img(:,:,3)));
        
        new_tracklet_mat.class_mat{n,fr_idx2-1} = new_track_obj1.det_class(n);
        
        new_tracklet_mat.det_score_mat(n,fr_idx2-1) = new_track_obj1.det_score(n);
    end
end

% linear prediction
track_id1 = new_track_obj1.track_id;
pred_bbox1 = zeros(length(track_id1),4);
for n = 1:length(track_id1)
    temp_t = find(new_tracklet_mat.xmin_mat(track_id1(n),:)>=0);
    if length(temp_t)>10
        temp_t = temp_t(end-9:end);
    end
    pred_xmin = linearPred(temp_t,new_tracklet_mat.xmin_mat(track_id1(n),temp_t),fr_idx2);
    pred_xmax = linearPred(temp_t,new_tracklet_mat.xmax_mat(track_id1(n),temp_t),fr_idx2);
    pred_ymin = linearPred(temp_t,new_tracklet_mat.ymin_mat(track_id1(n),temp_t),fr_idx2);
    pred_ymax = linearPred(temp_t,new_tracklet_mat.ymax_mat(track_id1(n),temp_t),fr_idx2);
    pred_bbox1(n,:) = [pred_xmin,pred_ymin,pred_xmax-pred_xmin+1,pred_ymax-pred_ymin+1];
end

out_idx1 = find(new_track_obj1.mask_flag<0.5);
in_idx1 = find(new_track_obj1.mask_flag>0.5);
out_idx2 = find(new_track_obj2.mask_flag<0.5);
in_idx2 = find(new_track_obj2.mask_flag>0.5);
out_bbox1 = new_track_obj1.bbox(out_idx1,:);
in_bbox1 = new_track_obj1.bbox(in_idx1,:);
pred_out_bbox1 = pred_bbox1(out_idx1,:);
pred_in_bbox1 = pred_bbox1(in_idx1,:);
out_bbox2 = new_track_obj2.bbox(out_idx2,:);
in_bbox2 = new_track_obj2.bbox(in_idx2,:);
N_out_bbox1 = size(out_bbox1,1);
N_in_bbox1 = size(in_bbox1,1);
N_out_bbox2 = size(out_bbox2,1);
N_in_bbox2 = size(in_bbox2,1);
out_bbox_color1 = zeros(N_out_bbox1,3);
in_bbox_color1 = zeros(N_in_bbox1,3);
out_bbox_color2 = zeros(N_out_bbox2,3);
in_bbox_color2 = zeros(N_in_bbox2,3);
for n = 1:N_out_bbox1
    bbox_img = img1(out_bbox1(n,2):out_bbox1(n,2)+out_bbox1(n,4)-1,out_bbox1(n,1):out_bbox1(n,1)+out_bbox1(n,3)-1,:);
    out_bbox_color1(n,1) =  mean(mean(bbox_img(:,:,1)));
    out_bbox_color1(n,2) =  mean(mean(bbox_img(:,:,2)));
    out_bbox_color1(n,3) =  mean(mean(bbox_img(:,:,3)));
end
for n = 1:N_in_bbox1
    bbox_img = img1(in_bbox1(n,2):in_bbox1(n,2)+in_bbox1(n,4)-1,in_bbox1(n,1):in_bbox1(n,1)+in_bbox1(n,3)-1,:);
    in_bbox_color1(n,1) =  mean(mean(bbox_img(:,:,1)));
    in_bbox_color1(n,2) =  mean(mean(bbox_img(:,:,2)));
    in_bbox_color1(n,3) =  mean(mean(bbox_img(:,:,3)));
end
for n = 1:N_out_bbox2
    bbox_img = img2(out_bbox2(n,2):out_bbox2(n,2)+out_bbox2(n,4)-1,out_bbox2(n,1):out_bbox2(n,1)+out_bbox2(n,3)-1,:);
    out_bbox_color2(n,1) =  mean(mean(bbox_img(:,:,1)));
    out_bbox_color2(n,2) =  mean(mean(bbox_img(:,:,2)));
    out_bbox_color2(n,3) =  mean(mean(bbox_img(:,:,3)));
end
for n = 1:N_in_bbox2
    bbox_img = img2(in_bbox2(n,2):in_bbox2(n,2)+in_bbox2(n,4)-1,in_bbox2(n,1):in_bbox2(n,1)+in_bbox2(n,3)-1,:);
    in_bbox_color2(n,1) =  mean(mean(bbox_img(:,:,1)));
    in_bbox_color2(n,2) =  mean(mean(bbox_img(:,:,2)));
    in_bbox_color2(n,3) =  mean(mean(bbox_img(:,:,3)));
end
D_r_out = pdist2(out_bbox_color1(:,1),out_bbox_color2(:,1));
D_g_out = pdist2(out_bbox_color1(:,2),out_bbox_color2(:,2));
D_b_out = pdist2(out_bbox_color1(:,3),out_bbox_color2(:,3));
D_max_out = max(max(D_r_out,D_g_out),D_b_out);
D_r_in = pdist2(in_bbox_color1(:,1),in_bbox_color2(:,1));
D_g_in = pdist2(in_bbox_color1(:,2),in_bbox_color2(:,2));
D_b_in = pdist2(in_bbox_color1(:,3),in_bbox_color2(:,3));
D_max_in = max(max(D_r_in,D_g_in),D_b_in);
mask_out = double(D_max_out<new_track_params.color_thresh);
mask_in = double(D_max_in<new_track_params.color_thresh);


track_id2 = zeros(1,N_out_bbox2+N_in_bbox2);

[out_bbox1_idx, out_bbox2_idx, out_overlap_mat] = bboxAssociate(pred_out_bbox1, out_bbox2,...
    new_track_params.overlap_thresh2, new_track_params.lb_thresh, mask_out);
new_track_obj1.out_overlap_mat = out_overlap_mat;
track_id2(out_idx2(out_bbox2_idx)) = track_id1(out_idx1(out_bbox1_idx));

[in_bbox1_idx, in_bbox2_idx, in_overlap_mat] = bboxAssociate(pred_in_bbox1, in_bbox2,...
    new_track_params.overlap_thresh1, new_track_params.lb_thresh, mask_in);
new_track_obj1.in_overlap_mat = in_overlap_mat;
track_id2(in_idx2(in_bbox2_idx)) = track_id1(in_idx1(in_bbox1_idx));

for n = 1:(N_out_bbox2+N_in_bbox2)
    if track_id2(n)==0
        track_id2(n) = new_track_params.max_track_id+1;
        new_track_params.max_track_id = new_track_params.max_track_id+1;
    end
end
new_track_obj2.track_id = track_id2;

if new_track_params.max_track_id>track_params.max_track_id
    new_tracklet_mat.xmin_mat = [new_tracklet_mat.xmin_mat;...
        -1*ones(new_track_params.max_track_id-track_params.max_track_id,size(new_tracklet_mat.xmin_mat,2))];
    new_tracklet_mat.ymin_mat = [new_tracklet_mat.ymin_mat;...
        -1*ones(new_track_params.max_track_id-track_params.max_track_id,size(new_tracklet_mat.ymin_mat,2))];
    new_tracklet_mat.xmax_mat = [new_tracklet_mat.xmax_mat;...
        -1*ones(new_track_params.max_track_id-track_params.max_track_id,size(new_tracklet_mat.xmax_mat,2))];
    new_tracklet_mat.ymax_mat = [new_tracklet_mat.ymax_mat;...
        -1*ones(new_track_params.max_track_id-track_params.max_track_id,size(new_tracklet_mat.ymax_mat,2))];
    new_tracklet_mat.color_mat = [new_tracklet_mat.color_mat;...
        -1*ones(new_track_params.max_track_id-track_params.max_track_id,size(new_tracklet_mat.color_mat,2),3)];
    new_tracklet_mat.class_mat = [new_tracklet_mat.class_mat;...
        cell(new_track_params.max_track_id-track_params.max_track_id,size(new_tracklet_mat.class_mat,2))];
    new_tracklet_mat.det_score_mat = [new_tracklet_mat.det_score_mat;...
        -1*ones(new_track_params.max_track_id-track_params.max_track_id,size(new_tracklet_mat.det_score_mat,2))];
end
for n = 1:(N_out_bbox2+N_in_bbox2)
    new_tracklet_mat.xmin_mat(track_id2(n),fr_idx2) = new_track_obj2.bbox(n,1);
    new_tracklet_mat.ymin_mat(track_id2(n),fr_idx2) = new_track_obj2.bbox(n,2);
    new_tracklet_mat.xmax_mat(track_id2(n),fr_idx2) = new_track_obj2.bbox(n,1)+new_track_obj2.bbox(n,3)-1;
    new_tracklet_mat.ymax_mat(track_id2(n),fr_idx2) = new_track_obj2.bbox(n,2)+new_track_obj2.bbox(n,4)-1;
    
    bbox_img = img2(new_tracklet_mat.ymin_mat(track_id2(n),fr_idx2):new_tracklet_mat.ymax_mat(track_id2(n),fr_idx2),...
        new_tracklet_mat.xmin_mat(track_id2(n),fr_idx2):new_tracklet_mat.xmax_mat(track_id2(n),fr_idx2),:);
    new_tracklet_mat.color_mat(track_id2(n),fr_idx2,1) = mean(mean(bbox_img(:,:,1)));
    new_tracklet_mat.color_mat(track_id2(n),fr_idx2,2) = mean(mean(bbox_img(:,:,2)));
    new_tracklet_mat.color_mat(track_id2(n),fr_idx2,3) = mean(mean(bbox_img(:,:,3)));
    
    new_tracklet_mat.class_mat{track_id2(n),fr_idx2} = new_track_obj2.det_class(n);
    
    new_tracklet_mat.det_score_mat(track_id2(n),fr_idx2) = new_track_obj2.det_score(n);
    
    new_tracklet_mat.mask_flag(track_id2(n)) = new_track_obj2.mask_flag(n);
end





% bbox1 = new_track_obj1.bbox;
% bbox2 = new_track_obj2.bbox;
% N_bbox1 = size(bbox1,1);
% N_bbox2 = size(bbox2,1);
% bbox_color1 = zeros(N_bbox1,3);
% bbox_color2 = zeros(N_bbox2,3);
% for n = 1:N_bbox1
%     bbox_img = img1(bbox1(n,2):bbox1(n,2)+bbox1(n,4)-1,bbox1(n,1):bbox1(n,1)+bbox1(n,3)-1,:);
%     bbox_color1(n,1) =  mean(mean(bbox_img(:,:,1)));
%     bbox_color1(n,2) =  mean(mean(bbox_img(:,:,2)));
%     bbox_color1(n,3) =  mean(mean(bbox_img(:,:,3)));
% end
% for n = 1:N_bbox2
%     bbox_img = img2(bbox2(n,2):bbox2(n,2)+bbox2(n,4)-1,bbox2(n,1):bbox2(n,1)+bbox2(n,3)-1,:);
%     bbox_color2(n,1) =  mean(mean(bbox_img(:,:,1)));
%     bbox_color2(n,2) =  mean(mean(bbox_img(:,:,2)));
%     bbox_color2(n,3) =  mean(mean(bbox_img(:,:,3)));
% end
% D_r = pdist2(bbox_color1(:,1),bbox_color2(:,1));
% D_g = pdist2(bbox_color1(:,2),bbox_color2(:,2));
% D_b = pdist2(bbox_color1(:,3),bbox_color2(:,3));
% D_max = max(max(D_r,D_g),D_b);
% mask = double(D_max<new_track_params.color_thresh);
% 
% track_id1 = new_track_obj1.track_id;
% [bbox1_idx, bbox2_idx, overlap_mat] = bboxAssociate(bbox1, bbox2,...
%     new_track_params.overlap_thresh, new_track_params.lb_thresh, mask);
% new_track_obj1.overlap_mat = overlap_mat;
% track_id2 = zeros(1,size(bbox2,1));
% track_id2(bbox2_idx) = track_id1(bbox1_idx);
% for n = 1:size(bbox2,1)
%     if track_id2(n)==0
%         track_id2(n) = new_track_params.max_track_id+1;
%         new_track_params.max_track_id = new_track_params.max_track_id+1;
%     end
% end
% new_track_obj2.track_id = track_id2;
% 
% 
% if new_track_params.max_track_id>track_params.max_track_id
%     new_tracklet_mat.xmin_mat = [new_tracklet_mat.xmin_mat;...
%         -1*ones(new_track_params.max_track_id-track_params.max_track_id,size(new_tracklet_mat.xmin_mat,2))];
%     new_tracklet_mat.ymin_mat = [new_tracklet_mat.ymin_mat;...
%         -1*ones(new_track_params.max_track_id-track_params.max_track_id,size(new_tracklet_mat.ymin_mat,2))];
%     new_tracklet_mat.xmax_mat = [new_tracklet_mat.xmax_mat;...
%         -1*ones(new_track_params.max_track_id-track_params.max_track_id,size(new_tracklet_mat.xmax_mat,2))];
%     new_tracklet_mat.ymax_mat = [new_tracklet_mat.ymax_mat;...
%         -1*ones(new_track_params.max_track_id-track_params.max_track_id,size(new_tracklet_mat.ymax_mat,2))];
%     new_tracklet_mat.color_mat = [new_tracklet_mat.color_mat;...
%         -1*ones(new_track_params.max_track_id-track_params.max_track_id,size(new_tracklet_mat.color_mat,2),3)];
%     new_tracklet_mat.class_mat = [new_tracklet_mat.class_mat;...
%         cell(new_track_params.max_track_id-track_params.max_track_id,size(new_tracklet_mat.class_mat,2))];
%     new_tracklet_mat.det_score_mat = [new_tracklet_mat.det_score_mat;...
%         -1*ones(new_track_params.max_track_id-track_params.max_track_id,size(new_tracklet_mat.det_score_mat,2))];
% end
% for n = 1:size(bbox2,1)
%     new_tracklet_mat.xmin_mat(track_id2(n),fr_idx2) = bbox2(n,1);
%     new_tracklet_mat.ymin_mat(track_id2(n),fr_idx2) = bbox2(n,2);
%     new_tracklet_mat.xmax_mat(track_id2(n),fr_idx2) = bbox2(n,1)+bbox2(n,3)-1;
%     new_tracklet_mat.ymax_mat(track_id2(n),fr_idx2) = bbox2(n,2)+bbox2(n,4)-1;
%     
%     bbox_img = img2(new_tracklet_mat.ymin_mat(track_id2(n),fr_idx2):new_tracklet_mat.ymax_mat(track_id2(n),fr_idx2),...
%         new_tracklet_mat.xmin_mat(track_id2(n),fr_idx2):new_tracklet_mat.xmax_mat(track_id2(n),fr_idx2),:);
%     new_tracklet_mat.color_mat(track_id2(n),fr_idx2,1) = mean(mean(bbox_img(:,:,1)));
%     new_tracklet_mat.color_mat(track_id2(n),fr_idx2,2) = mean(mean(bbox_img(:,:,2)));
%     new_tracklet_mat.color_mat(track_id2(n),fr_idx2,3) = mean(mean(bbox_img(:,:,3)));
%     
%     new_tracklet_mat.class_mat{track_id2(n),fr_idx2} = new_track_obj2.det_class(n);
%     
%     new_tracklet_mat.det_score_mat(track_id2(n),fr_idx2) = new_track_obj2.det_score(n);
% end