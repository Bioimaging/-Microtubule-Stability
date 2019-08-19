function Idiff=ctrlAccum(pathway,fig,ax_,format,type_proj)
%% Analyse of the dye accumulation
%
% SYNOPSIS : Idiff=ctrlAccum(pathway,fig,ax_,format)
%
% INPUT :   pathway : pathway of the controls videos
%           fig : fig in which display the control accumulation graph
%           ax_ : axe of fig in which display the control accumulation
%                  graph
%           format : the type of microscope used to make the videos
%           type_proj : type of projection, 'MAX' or 'SUM'

    fprintf('\n Analyse of dye accumulation n')

    %Get videos names
    if format=='DelVi'
        files= dir(strcat(pathway,'/*.dv'));
        nvid=length(files);
        if nvid==0
            error('No ".dv" file in control folder')
        end
    else
        files= dir(strcat(pathway,'/*.tif'));
        nvid=length(files);
        if nvid==0
            error('No ".tif" file in control folder')
        end
    end

    I=cell(nvid,1) ; % matrix which will contain every intensities
    %nvid=2; % just to check quickier
     
    col=hsv(nvid);
    plt=zeros(1,nvid);
    
    % Calculte intensity for each image and plot it
    for iv=1:nvid
        name=strcat(pathway,'/',files(iv).name);
        [intensity,time]=analyseIntens(name,type_proj,format,'increase');
        I{iv}=intensity;
        figure(fig)
        axes(ax_)
        plt(iv)=line(time,intensity,'DisplayName',files(iv).name,'color',col(iv,:));
        hold on ;
        set(get(get(plt(iv),'Annotation'),'LegendInformation'),...
            'IconDisplayStyle','off');
    end
    
    ftxt=figure('Name','Select outliers','NumberTitle','off','MenuBar','none',...
    'Position',[1 1 250 90]);
    movegui(ftxt,'northwest');
    axes('Position',[0 0 1 1],'Visible','off');
    desc={'Click on the outliers curves';'from the last graph';...
        ' to exclude them from the analysis';...
        '(if they exists)';'Press <Return> when you have finished'};
    tex=text(0.4,0.7,desc);
    tex.HorizontalAlignment='center';
    set(tex,'Position',[0.5,0.5]);
    
    figure(fig)
    axes(ax_)
    [xOut,yOut]=ginput();
    close(ftxt)
    
    if ~isempty(xOut)
        newI=cell2mat(I);
        newI=newI(:,knnsearch(time',xOut));
        for iOut=1:length(xOut)
            ind=knnsearch(newI(:,iOut),yOut(iOut));
            I{ind}=[];
            set(plt(ind),'Visible','off');
        end
        I=I(~cellfun('isempty',I));
    end
    
    
    if nvid>1
        Av=mean(cell2mat(I));
        Med=median(cell2mat(I));
    else
        Av=I{1};
        Med=I{1};
    end
    
    plot(time,Av,'-r','LineWidth',2);
    plot(time,Med,'-g','LineWidth',2);
    hold off;
    legend('Avg','Med')
    title('Control of dye accumulation')
    xlabel('Time (min)')
    ylabel('Total intensities (%)')
    Idiff=Av-100;

end