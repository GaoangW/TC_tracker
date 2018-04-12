# TC_tracker
Tracklet clustering for 2D tracking.
# 1. Prepare the detection file 
Please prepare the detection file with the format that follows MOT challenge https://motchallenge.net/instructions/.
# 2. Run the demo.m
Input: <br />
img_path: the directory of the image folder that contains the video sequence. <br />
det_path: the directory of the detection file from the previous step. <br />
seq_name: the name of the video sequence. <br />
ROI_path: the directory of the ROI mask. If no ROI provided, use empty matrix instead. <br />
img_save_path: the directory of the output image after tracking. <br />
result_save_path: the directory of the tracking result. The result follows the UA-Detrac format. https://detrac-db.rit.albany.edu/instructions. <br />
