function err = getLoss(track_id, sigma, tracklet_mat)

t = [];
det_x = [];
det_y = [];
for n = 1:length(track_id)
    temp_t = find(tracklet_mat.det_x(track_id(n),:)>0);
    det_x = [det_x,tracklet_mat.det_x(track_id(n),temp_t)];
    det_y = [det_y,tracklet_mat.det_y(track_id(n),temp_t)];
    t = [t,temp_t];
end

model_x = fitrgp(t',det_x','Basis','linear',...
    'FitMethod','exact','PredictMethod','exact','Sigma',sigma,...
    'ConstantSigma',true,'KernelFunction','matern52','KernelParameters',[1000,1000]);
pred_x = predict(model_x,t');

model_y = fitrgp(t',det_y','Basis','linear',...
    'FitMethod','exact','PredictMethod','exact','Sigma',sigma,...
    'ConstantSigma',true,'KernelFunction','matern52','KernelParameters',[1000,1000]);
pred_y = predict(model_y,t');

err = sum(sqrt((pred_x-det_x').^2+(pred_y-det_y').^2));

figure, plot(t,det_x,'k.',t,pred_x,'r.')
figure, plot(t,det_y,'k.',t,pred_y,'r.')
