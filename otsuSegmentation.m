%% Create mask using otsu's method segmentation
% INPUT     im : 2D image to segmente
%
% OUTPUT     mask : a binary matrix which, mask to apply to image to only
%                    keep the pixels of interest
function mask=otsuSegmentation(im)
    im=imtophat(im,strel('disk',50));
    im=mat2gray(im);
    lev=graythresh(im);
    mask = im>=lev;
    mask=bwareaopen(mask,50);
end