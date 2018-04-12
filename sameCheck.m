function flag = sameCheck(struct1,struct2)

if length(struct1)~=length(struct2)
    flag = 0;
    return
end
for n = 1:length(struct1)
    temp_flag = isequal(struct1{n},struct2{n});
    if ~temp_flag
        flag = 0;
        return
    end 
end
flag = 1;