
function toreturn=Analysenocontrol(format,fig,pathway,nC,type_proj,...
    legendinfo,increase)
%% Main analyse evolution of intensities of the microtubules
%in a set of videos of one repeat when there's no control videos
%
%
% SYNOPSIS : output=Analysenocontrol(format,fig,pathway,nC,type_proj,...
%    legendinfo,increase)
%
% INPUT :   format : the format of the files to open, 
%               'Nikon' for video from Nikon microscope
%               'DelVi' for video from DeltaVision microscope
%           fig : the main fig of the repetiton
%           pathway : string, the pathway to the folder of this repeat
%           nC : int, number of conditions compared
%           type_proj : type of projection to apply, 'MAX' or 'AVG'
%           legendinfo : the list of the conditions' names
%           increase : boolean, if true allow intensity icnrease >15%
%
% OUTPUT :  toreturn : 1 x 2 cell,
%                toreturn{1} = legendinfo uploaded 
%                toreturn{2} = 1x nC cell, intensities of all the cells
%                               of this repeat
%                toreturn{3} = 1x nC cell, Fit objects of this repeat
%                toreturn{4} = global time (for x axis)
%                toreturn{5} = 1x nC cell, name of the videos files for
%                               this repeat
%                toreturn{6} = pvalues to compare two conditions 
%                toreturn{7} = 1x nC cell, half-life times for this repeat


colors=prism(nC); % Define plot colors for each condition
listSubplot=nan*(1:nC+3);

% Get name of subfolders in the main folder
d=dir(pathway);
isub=[d(:).isdir];
namesFoldsCond={d(isub).name};
namesFoldsCond(ismember(namesFoldsCond,{'.','..'}))=[];

% Preallocation for graph list
p=nan*(1:2*nC);
p2=nan*(1:2*nC);
p3=nan*(1:2*nC);


% Preallocation for intensities list
allI=cell(1,nC); % Intensities preallocation
allFit=cell(1,nC); % fitness object preallocation
Fit=cell(1,nC); % fitness curves preallocation
filesname=cell(1,nC); %names of files preallocation
t0_5=cell(1,nC);
pval=nan;

figure(fig)
for c=1:nC

    % Check if there's enough subfolders in the main folder
    if length(namesFoldsCond)<nC
        if nC==1
            pathway_complete=pathway;
            if ismac
                s=strsplit(pathway_complete,'/');
            else
                s=strsplit(pathway_complete,'\');
            end
            namesFoldsCond{1}=s{length(s)};
        else
            error('No subfolders')
        end
    else
        pathway_complete=strcat(pathway,'/',namesFoldsCond{c});
    end
    
    fprintf(['\n', namesFoldsCond{c},'\n'])
    
    %Get videos names
    if strcmp(format,'DelVi')
        files= dir(strcat(pathway_complete,'/*.dv'));
        nV=length(files);
        if nV==0
            error(strcat('No ".dv" file in ',pathway))
        end
    else
        files= dir(strcat(pathway_complete,'/*.tif'));
        nV=length(files);
        if nV==0
            error(strcat('No ".ome.tif" file in ',pathway))
        end
    end
    
    %nV=3; % just to check quicklier
    I=cell(nV,1); % matrix which will contain every intensities for 1 condition
    
    filesname{c}=cell(nV,1);
    
    % Calculte intensity for each image and plot it
    col=hsv(nV);
    figure(fig)
    subplot(3,nC+1,[c c+nC+1 c+2*(nC+1)])
    hold on ;
    pltcurv=zeros(1,nV);
    for iv=1:nV
        filesname{c}{iv}=files(iv).name;
        fprintf(['\n Image ',files(iv).name,'\n']);
        name=strcat(pathway_complete,'/',files(iv).name);
        [intensity,time]=analyseIntens(name,type_proj,format,increase);
        I{iv}=intensity;
        pltcurv(iv)=line(time,intensity,'DisplayName',files(iv).name,'color',col(iv,:));
        set(get(get(pltcurv(iv),'Annotation'),'LegendInformation'),...
            'IconDisplayStyle','off');
    end
    listSubplot(c)=subplot(3,nC+1,[c c+nC+1 c+2*(nC+1)]);
    

    %Allow to suppress outliers
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
    subplot(3,nC+1,[c c+nC+1 c+2*(nC+1)])
    [xOut,yOut]=ginput();
    close(ftxt)
    
    if ~isempty(xOut)
        newI=cell2mat(I);
        newI=newI(:,knnsearch(time',xOut));
        for iOut=1:length(xOut)
            ind=knnsearch(newI(:,iOut),yOut(iOut));
            I{ind}=[];
            fprintf([files(ind).name,' ignored \n']);
            filesname{c}{ind}=[];
            set(pltcurv(ind),'Visible','off');
        end
        I=I(~cellfun('isempty',I));
        filesname{c}=filesname{c}(~cellfun('isempty',filesname{c}));
    end
    
    
    
    %Check if all videos have same length or cut the longest ones
    lensI=cellfun(@length,I);
    if length(unique(lensI))>1
        lenmin=min(lensI);
         for i=1:size(I,1)
             if length(I{i})>lenmin
                 I{i}=I{i}(1:lenmin);
             end
         end
         if length(time)>lenmin
             time=time(1:lenmin);
         end
    end
    
    
    % Plot average and median on existant graph
    subplot(3,nC+1,[c c+nC+1 c+2*(nC+1)])
    if size(I,1)>1
        Av=nanmean(cell2mat(I));
        Med=nanmedian(cell2mat(I));
        line(time,Av,'color',[1 0 0],'LineWidth',2);
        line(time,Med,'color',[0 1 0],'LineWidth',2);
    else
        Av=I{1};
        Med=I{1};
    end
    hold off;
    title(namesFoldsCond{c})
    legend('Avg','Med')
    
    
    % Plot average + confidence interval on a new graph
    subplot(3,nC+1,nC+1)
    p(c)=line(time,Av,'color',colors(c,:));
    hold on
    p(c+nC)=plot_confIntAvg(cell2mat(I),time,colors(c,:));
    
    % Plot median + confidence interval on a new graph
    subplot(3,nC+1,2*nC+2)
    p2(c)=line(time,Med,'color',colors(c,:));
    hold on
    p2(c+nC)=plot_confIntMed(cell2mat(I),time,colors(c,:));
    
    % Plot 2 exponential model + confidence interval on a new graph
    subplot(3,nC+1,3*nC+3)
    I2=cell2mat(I);
    I2(any(isnan(I2), 2),:)=[];
    x=sort(repmat(time',size(I2,1),1));
    f=fit(x,I2(:),'exp2');
    allFit{c}=f;
    predict=f(time);
    hold on
    p3(c)=line(time,predict,'color',colors(c,:));
    P=predint(f,time,0.95,'functional','on');
    Xplot=[time,fliplr(time)];
    Yplot=[P(:,1)',fliplr(P(:,2)')];
    p3(c+nC)=fill(Xplot,Yplot,1,'facecolor',colors(c,:),...
        'LineStyle','- -', 'facealpha', 0.2,...
        'edgecolor',colors(c,:));
    Fit{c}=predict;
    
    % Plot half-life time
    syms t
    coeff=coeffvalues(f);
    eq=coeff(1)*exp(coeff(2)*t)+coeff(3)*exp(coeff(4)*t)==50; % equation of the model
    t0_5{c}=double(vpasolve(eq,t)); % get half-life time
    text(time(length(time))-5,80-10*(c-1),strcat('t1/2= ',num2str(t0_5{c}),' min'),...
        'color',colors(c,:));
    if isempty(legendinfo{c})
        legendinfo{c}=[namesFoldsCond{c}];
    end
    allI{c}=cell2mat(I);
end

figure(fig)
listSubplot(nC+1:nC+3)=[subplot(3,nC+1,nC+1),subplot(3,nC+1,2*nC+2),...
    subplot(3,nC+1,3*nC+3)]; % list of all subplots to link after

%Set axis labels and title
for ax=listSubplot
    set(get(ax,'xlabel'),'String','Time (min)')
    set(get(ax,'Ylabel'),'String','Total intensities (%)')
end

axAvg=subplot(3,nC+1,nC+1);
title('Average curves')
legend(axAvg,p(1:nC),legendinfo)

axMed=subplot(3,nC+1,2*nC+2);
title('Median curves')
legend(axMed,p2(1:nC),legendinfo)

axFit=subplot(3,nC+1,3*nC+3);
title('Two Exponential Model')
legend(axFit,p3(1:nC),legendinfo)

% Plot stat difference for each time
if nC==2
    Fit=cell2mat(Fit);
    pval=zeros(1,length(time));
    cond1=cell2mat(allI(:,1));
    cond2=cell2mat(allI(:,2));
    for t=1:length(time)
        pval(t)=ranksum(cond1(:,t),cond2(:,t));
    end
    fprintf('P-value : \n')
    pval
    for t=2:length(time)
        if pval(t)<0.001
            text(time(t)-0.2,max(Fit(t,:))+5,'***');
        else
            if pval(t)<0.01
                text(time(t)-0.2,max(Fit(t,:))+5,'**');
            else
                if pval(t) <0.05
                    text(time(t)-0.2,max(Fit(t,:))+5,'*');
                end
            end
        end
    end
end

linkaxes(listSubplot)
xlim([0 floor(max(time))+1])

toreturn={legendinfo,allI,allFit,time,filesname,pval,t0_5};

end




