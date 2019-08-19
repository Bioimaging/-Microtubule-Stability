% Display image segmented (with mask)
% INPUT         im_masked : 3D matrix containing the image after
%                           segmentation
%               T : max time 
%               nameToSave : name to save video
% OUTPUT        Display and save the images after segmentation
function dispImSeg(im_masked,T,nameToSave)
    figure('Name','Video Segmented','NumberTitle','off');
    % Show the image with mask / not needed, only to check
    disp(['Video after segmentation will be saved in ',nameToSave])
    vseg=VideoWriter(nameToSave);
    vseg.FrameRate=5;
    open(vseg)
    for i=1:T
       res=zeros(size(im_masked(:,:,i),1),size(im_masked(:,:,i),2),3);
       res(:,:,1)=mat2gray(im_masked(:,:,i));
       imshow(res,[]);
       title ('Image after segmentation')
       drawnow;
       currentFrame=getframe;
       writeVideo(vseg,currentFrame);
    end
    close(vseg)
end
