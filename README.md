# TC_tracker
Tracklet clustering for 2D tracking.
# 1. Prepare the detection file 
Please prepare the detection file with the format that follows MOT challenge https://motchallenge.net/instructions/.
# 2. Set the directory
Set the directory in demo.m. <br />
Input: <br />
img_path: the directory of the image folder that contains the video sequence. <br />
det_path: the directory of the detection file from the previous step. <br />
seq_name: the name of the video sequence. <br />
ROI_path: the directory of the ROI mask. If no ROI provided, use empty matrix instead. <br />
img_save_path: the directory of the output image after tracking. <br />
result_save_path: the directory of the tracking result. The result follows the UA-Detrac format. https://detrac-db.rit.albany.edu/instructions. <br />
# 3. Set the parameters
Set the parameters in demo.m. <br />
det_score_thresh: detection score threshold between 0 and 1. <br />
IOU_thresh: IOU threshold for detection asscociation across frames between 0 and 1. <br />
color_thresh: color threshold for detection asscociation across frames between 0 and 1. <br />
lambda_time: time interval cost. <br />
lambda_split: tracklet separation cost. <br />
lambda_reg: smoothness cost. <br />
lambda_color: color change cost. <br />
lambda_grad: velocity change cost. <br />
# Citation
Use this bibtex to cite this repository: <br />
```
@inproceedings{tang2018single,
  title={Single-camera and inter-camera vehicle tracking and 3D speed estimation based on fusion of visual and semantic features},
  author={Tang, Zheng and Wang, Gaoang and Xiao, Hao and Zheng, Aotian and Hwang, Jenq-Neng},
  booktitle={Proceedings of the IEEE Conference on Computer Vision and Pattern Recognition Workshops},
  pages={108--115},
  year={2018}
}
```
