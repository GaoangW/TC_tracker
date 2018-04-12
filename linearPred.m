function pred_x = linearPred(train_t,train_x,t)

if length(train_t)<=2
    pred_x = train_x(end);
    return
end

A = [train_t',ones(size(train_t'))];
b = train_x';
p = pinv(A)*b;
pred_x = p(1)*t+p(2);