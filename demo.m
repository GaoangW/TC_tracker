% Copyright (C)2018, Gaoang Wang, All rights reserved.

close all
clear
clc
dbstop if error

%% dataset path
img_path = 'D:\Data\UA-Detrac\DETRAC-test-data\Insight-MVT_Annotation_Test\MVI_39031';
det_path = 'D:\Data\UA-Detrac\CompACT-test\CompACT\MVI_39031_Det_CompACT.txt';
seq_name = 'MVI_39031';
ROI_path = [];
img_save_path = 'D:\Data\UA-Detrac\tracking_frames\MVI_39031';
result_save_path = 'D:\Data\UA-Detrac\test_result';
video_save_path = 'D:\Data\UA-Detrac\tracking_video';

%% parameter setting
param.det_score_thresh = 0.1;   % detection score threshold, [0,1]
param.IOU_thresh = 0.5;         % IOU threshold for detection asscociation 
                                % across frames, [0,1]
param.color_thresh = 0.15;      % color threshold for detection asscociation 
                                % across frames, [0,1]                              
param.lambda_time = 25;         % time interval cost
param.lambda_split = 0.35;      % tracklet separation cost
param.lambda_reg = 0.2;         % smoothness cost
param.lambda_color = 0.25;      % color change cost
param.lambda_grad = 8;          % velocity change cost

%% tracklet clustering tracking
TC_tracker(img_path,det_path,ROI_path,param,img_save_path,seq_name,...
    result_save_path,video_save_path);