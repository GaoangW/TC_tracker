function [interp_y,pred_y,t_test] = vInterp(flag_idx,change_idx,vx_pred,t,y)

t_min = t(1)-1;
interp_y = [];
pred_y = [];
t_test = [];
for n = 1:length(change_idx)-1
    if flag_idx(change_idx(n))==flag_idx(change_idx(n+1))
        continue
    end
    t1 = t(change_idx(n));
    t2 = t(change_idx(n+1));
    v1 = vx_pred(t1-t_min);
    v2 = vx_pred(t2-t_min+1);
    
    delta_t = t2-t1;
    v_interp = linspace(v1,v2,delta_t+2);
    temp_interp_y = cumsum([0,v_interp(2:end-1)]);
    temp_pred_y = y(t1-t_min:t2-t_min);
    y_shift = (temp_interp_y(1)-temp_pred_y(1)+temp_interp_y(end)-temp_pred_y(end))/2;
    temp_interp_y = temp_interp_y-y_shift;
    interp_y = [interp_y,temp_interp_y];
    pred_y = [pred_y,temp_pred_y'];
    t_test = [t_test,t1:t2];
end