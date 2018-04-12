function [t_test,interp_y,pred_y] = vInterp_v2(t,y,y_pred,v,t_tr,y_tr)

t_test = [];
interp_y = [];
pred_y = [];
t_min = t(1)-1;
t_max = t(end)+1;
[~,sort_idx] = sort(t_tr,'ascend');
t_tr = t_tr(sort_idx);
y_tr = y_tr(sort_idx);
t_tr_add = t_tr;
t_tr_add = [t_min,t_tr_add];
t_tr_add = [t_tr_add,t_max];

change_flag = double(t_tr_add(2:end)-t_tr_add(1:end-1)>1.5);
change_idx = find(change_flag>0.5);
for n = 1:length(change_idx)
    t_start = t_tr_add(change_idx(n));
    t_end = t_tr_add(change_idx(n)+1);
    v1 = v(t_start-t_min+1);
    v2 = v(t_end-t_min+2);
    delta_t = t_end-t_start;
    v_interp = linspace(v1,v2,delta_t+2);
    temp_interp_y = cumsum([0,v_interp(2:end-1)]);
    if ismember(t_start,t)
        y1 = y(t==t_start);
    else
        y1 = y_pred(t_start-t_min+1);
    end
    if ismember(t_end,t)
        y2 = y(t==t_end);
    else
        y2 = y_pred(t_end-t_min+1);
    end
    y_shift = (temp_interp_y(1)-y1+temp_interp_y(end)-y2)/2;
    temp_interp_y = temp_interp_y-y_shift;
    
    t_test = [t_test,t_start+1:t_end-1];
    interp_y = [interp_y,temp_interp_y(2:end-1)];
end

for n = 1:length(t_test)
    if ismember(t_test(n),t)
        pred_y = [pred_y,y(t==t_test(n))];
    else
        pred_y = [pred_y,y_pred(t_test(n)-t_min+1)];
    end
end