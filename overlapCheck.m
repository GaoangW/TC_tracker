function overlap_ratio = overlapCheck(track_interval1,track_interval2)

t_min = max(track_interval1(1),track_interval2(1));
t_max = min(track_interval1(2),track_interval2(2));
if t_min>t_max
    overlap_ratio = 0;
    return
else
    min_len = min(track_interval1(2)-track_interval1(1)+1,track_interval2(2)-track_interval2(1)+1);
    overlap_ratio = (t_max-t_min+1)/min_len;
end