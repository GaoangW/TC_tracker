function writeTxt(seq_name,track_struct_path,save_path)

load([track_struct_path,'\',seq_name,'.mat']);

X = track_struct.tracklet_mat.xmin_mat';
Y = track_struct.tracklet_mat.ymin_mat';
W = track_struct.tracklet_mat.xmax_mat'-X+1;
H = track_struct.tracklet_mat.ymax_mat'-Y+1;
W(X<0) = 0;
H(X<0) = 0;
Y(X<0) = 0;
X(X<0) = 0;

fileID = fopen([save_path,'\',seq_name,'_LX.txt'],'w');
for r = 1:size(X,1)
    for c = 1:size(X,2)
        fprintf(fileID,'%f',X(r,c));
        if c~=size(X,2)
            fprintf(fileID,',');
        else
            fprintf(fileID,'\n');
        end
    end
end
fclose(fileID);

fileID = fopen([save_path,'\',seq_name,'_LY.txt'],'w');
for r = 1:size(X,1)
    for c = 1:size(X,2)
        fprintf(fileID,'%f',Y(r,c));
        if c~=size(X,2)
            fprintf(fileID,',');
        else
            fprintf(fileID,'\n');
        end
    end
end
fclose(fileID);

fileID = fopen([save_path,'\',seq_name,'_W.txt'],'w');
for r = 1:size(X,1)
    for c = 1:size(X,2)
        fprintf(fileID,'%f',W(r,c));
        if c~=size(X,2)
            fprintf(fileID,',');
        else
            fprintf(fileID,'\n');
        end
    end
end
fclose(fileID);

fileID = fopen([save_path,'\',seq_name,'_H.txt'],'w');
for r = 1:size(X,1)
    for c = 1:size(X,2)
        fprintf(fileID,'%f',H(r,c));
        if c~=size(X,2)
            fprintf(fileID,',');
        else
            fprintf(fileID,'\n');
        end
    end
end
fclose(fileID);