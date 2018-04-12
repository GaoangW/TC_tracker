function [t_sample,idx] = uniformSample(t, len)

if length(t)<=len
    t_sample = t;
    idx = 1:length(t);
    return
end
t_min = min(t);
t_max = max(t);
idx = round(linspace(1,length(t),len));
t_sample = t(idx);