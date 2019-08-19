%% Make Z projection of an image in 3D
% INPUT      im: an image_height x image_width x Z x T matrix
%                   which contains every image at every time and every slice
%
%            type_proj: type of projection to do among 'MAX', 'AVG' 
%
% OUTPUT     im_zproj: an image_height x image_width x T matrix
%                       which contains the Z projection at every time
function im_zproj=zProjection(im,type_proj)
    for i=1:size(im,2)
        switch type_proj
            case 'MAX'
                im_zproj=reshape(max(im,[],3), ...
                    size(im,1),size(im,2),size(im,4));
            case 'SUM'
                im_zproj=reshape(sum(im,3), ...
                    size(im,1),size(im,2),size(im,4));
        end       
    end
end