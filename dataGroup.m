function [t,y,y_tr,t_interval,t_tr] = dataGroup(t1,t2,y1,y2,tr_size)

t_max = max(max(t1),max(t2));
t = 1:t_max;
flag_idx = -1*ones(size(t));
flag_idx(t1) = 1;
flag_idx(t2) = 2;
t = t(flag_idx>0);
flag_idx = flag_idx(flag_idx>0);
y = t;
y(flag_idx==1) = y1;
y(flag_idx==2) = y2;
change_flag = zeros(size(flag_idx));
change_flag(1:end-1) = abs(flag_idx(2:end)-flag_idx(1:end-1));
change_flag(2:end) = change_flag(2:end)+change_flag(1:end-1);
change_flag = double(change_flag>0);
change_idx = find(change_flag>0.5);

% get training data
if length(t)<tr_size
    t_tr = t(change_flag<0.5);
    y_tr = y(change_flag<0.5);
else
    t_dist = pdist2(t',t(change_idx)');
    min_dist = min(t_dist,[],2);
    [sort_dist,sort_idx] = sort(min_dist,'ascend');
    sort_idx(sort_dist==0) = [];
    if length(sort_idx)>tr_size
        t_tr = t(sort_idx(1:tr_size));
        y_tr = y(sort_idx(1:tr_size));
    else
        t_tr = t(sort_idx);
        y_tr = y(sort_idx);
    end
end
t_interval = [min(min(t(change_idx)),min(t_tr)),max(max(t(change_idx)),max(t_tr))];    