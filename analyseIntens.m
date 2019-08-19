%% Analyse evolution of intensities of the microtubules in a video along
%       time making Z projection
% SYNOPSIS : analyseIntens(name_file,type_proj,increase) 
%            analyseIntens(name_file,type_proj,increase,saveSeg) : allow
%            saving segmentation
%
% INPUT     name_file : name of the file to analyse
%           type_proj : type of projection to apply
%                       'MAX', 'AVG' or 'SUM'
%           format : the format of the files to open, 
%               'Nikon' for video from Nikon microscope
%               'DelVi' for video from DeltaVision microscope
%           increase : string, if indicate, allow intensity increase
%           saveSeg : boolean, if true, ask for saving segmentation saving 
%                       (when only one video is analysed) 
% OUTPUT    I - vector containing intensities along time
%           time - vector, time scale


function [I,time]=analyseIntens(name_file,type_proj,format,increase,varargin)
    % Charge all data
    if format=='DelVi'
        v=bfopendv(name_file);
    else
        v=opennd2(name_file);
    end
    
    % Dimensions
    dim=v{2};
    
    % Time Scale
    time=v{3};

    % Create matrix image
    im=v{1};

    %Z projection
    im_zproj=zProjection(im,'MAX');
    newdim=dim;
    newdim(3)=[];

    %%% Segmentation
    fprintf('Segmentation \n')

    % Create first mask
    mask=zeros(newdim);
    for i=1:newdim(3)
        mask(:,:,i)=otsuSegmentation(im_zproj(:,:,i)); 
    end
    
    % Create the marker (for next reconstruction)
    marker=mask(:,:,1);
    cc = bwconncomp(marker, 4);
    labeled = labelmatrix(cc);
    RGB_label = label2rgb(labeled, @spring, 'c', 'shuffle');
    f=figure('Name','Selection','NumberTitle','off');
    ax1=axes('Position',[0 0 1 1],'Visible','off');
    ax2=axes('Position',[0.025 0.025 0.95 0.85]);
    axes(ax2)
    imshow(RGB_label);
    axes(ax1)
    desc={'Click on the shapes corresponding to part of the cell';
        'Press <Return> when you have finished'};
    tex=text(0.27,0.925,desc);
    tex.HorizontalAlignment='center';
    set(tex,'Position',[0.5,0.925]);
    axes(ax2)
    [x,y]=ginput();
    close(f);
    marker = zeros(size(marker));
    inderror=0;
    
    lab=zeros(1,length(x));
    % Check if there are shapes selected
    if ~isempty(x)
        if min(int16(x))>0 && min(int16(y))>0 ...
            && max(int16(x))<dim(2) && min(int16(y))<dim(1) 
            for i=1:length(x)
                lab(i)=labeled(int16(y(i)),int16(x(i)));
            end
        else
           lab=0; 
        end
    else
        lab=0;
    end
    
    while (min(lab)==0 && inderror<5) 
        f=figure('Name','Selection','NumberTitle','off');
        ax1=axes('Position',[0 0 1 1],'Visible','off');
        ax2=axes('Position',[0.025 0.025 0.95 0.85]);
        axes(ax2)
        imshow(RGB_label);
        axes(ax1)
        desc={'You did not select cells.';' Do it again '};
        tex=text(0.27,0.925,desc);
        tex.HorizontalAlignment='center';
        set(tex,'Position',[0.5,0.925]);
        [x,y]=ginput;
        close(f);
        inderror=inderror+1;	
        lab=zeros(1,length(x));
        if ~isempty(x)
            if min(int16(x))>0 && min(int16(y))>0 ...
                && max(int16(x))<dim(2) && min(int16(y))<dim(1) 
                for i=1:length(x)
                    lab(i)=labeled(int16(y(i)),int16(x(i)));
                end
            else
               lab=0; 
            end
        else
            lab=0;
        end
    end
    if inderror==5
        error('Error, no cell selecting too many times. Check the video. ')
    end 
    
    % Conserve only shapes selecting
    for i=1:length(x)
        marker(cc.PixelIdxList{lab(i)}) = 1;
    end
    
    % Dilatation Reconstruction
    mask(:,:,1)=imreconstruct(marker,mask(:,:,1),4);
    for i=2:newdim(3)
       m=imreconstruct(marker,mask(:,:,i),4);
       if sum(sum(m))>sum(sum(mask(:,:,i-1)))/2
           mask(:,:,i)=m;
       end
       marker=mask(:,:,i);
    end
    
    if ~strcmp(type_proj,'MAX')
        im_zproj=zProjection(im,type_proj);
    end
    
    % Applicate the mask to the image
    im_masked=im_zproj.*mask; 
    
    % Show the image with segmentation
    if ~isempty(varargin)
        if varargin{1}
            dispImSeg(im_masked,newdim(3),varargin{2})
        end
    end
   
    % Calculate intensity by sum
    if increase
        I=calcIntens(im_masked,newdim,increase);
    else
        I=calcIntens(im_masked,newdim);
    end
end  



