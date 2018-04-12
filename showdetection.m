
img_folder = 'D:\Data\UA-Detrac\DETRAC-train-data\Insight-MVT_Annotation_Train\MVI_20011';
txt_file = 'D:\Data\UA-Detrac\CompACT-train\CompACT\MVI_20011_Det_CompACT.txt';
fr_idx = 203;
detection_thresh = 0.0;

fileID = fopen(txt_file,'r');
A = textscan(fileID,'%f %f %f %f %f %f %f %f %f %f %s','Delimiter',',');
fclose(fileID);
M = zeros(size(A{1},1),10);
for n = 1:10
    M(:,n) = A{n};
end

idx = find(M(:,1)==fr_idx);
img_name = fileName(fr_idx,4);
img_list = dir([img_folder,'\*.jpg']);
img = imread([img_folder,'\',img_list(fr_idx).name]);

figure, 
imshow(img); hold on
for n = 1:length(idx)
    if M(idx(n),7)<detection_thresh
        continue
    end
    bbox = M(idx(n),3:6);
    xmin = bbox(1);
    ymin = bbox(2);
    xmax = bbox(1)+bbox(3)-1;
    ymax = bbox(2)+bbox(4)-1;
    plot([xmin,xmin],[ymin,ymax],'r'); hold on
    plot([xmax,xmax],[ymin,ymax],'r'); hold on
    plot([xmin,xmax],[ymin,ymin],'r'); hold on
    plot([xmin,xmax],[ymax,ymax],'r'); hold on
end