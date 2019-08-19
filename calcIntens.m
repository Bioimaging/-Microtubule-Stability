%% Calculate intensity by summing all intensities of the image
% INPUT         im_masked : 3D matrix, images after segmentation, 
%                           for each time
%               dim : 1 x 3, dimensions of the images
%                     dim(1) = nb of row, dim(2)= number of column
%                       dim(3) = number of time step
%
% OUTPUT        I_percent : 1 x dim(3) vector,
%                           the intensity normalized in percentage
function I_percent=calcIntens(im_masked,dim,varargin)
    I=zeros(1,dim(3));
    for i=1:dim(3)
        I(i)=sum(reshape(im_masked(:,:,i),dim(1)*dim(2),1));
    end
    I_percent=I*100/I(1); % convertion to percentage
    if isempty(varargin)
        Imoins=I_percent(2:dim(3))-I_percent(1:dim(3)-1);
        ind=find(Imoins>15);
        I_percent(ind:dim(3))=nan;   
    end
end