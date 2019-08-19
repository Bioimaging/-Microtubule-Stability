
function toreturn=Analysewithcontrol(format,fig,pathway,nC,type_proj,...
    legendinfo,increase)
%% Main analyse evolution of intensities of the microtubules
%in a set of videos of one repeat when there is control videos
%
% SYNOPSIS : output=Analysewithcontrol(format,fig,pathway,nC,type_proj,...
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
% OUTPUT :  toreturn : 1 x 3 cell,
%                toreturn{1} = legendinfo uploaded 
%                toreturn{2} = 1x nC cell, intensities of all the cells
%                               of this repeat without correction
%                toreturn{3} = 1x nC cell, Fit objects of this repeat
%                               without correction
%                toreturn{4} = global time (for x axis)
%                toreturn{5} = 1x nC cell, name of the videos files for
%                               this repeat
%                toreturn{6} = pvalues to compare two conditions
%                toreturn{7} = 1x nC cell, half-life times for this repeat
%                toreturn{8} = 1x nC cell, intensities of all the cells
%                               of this repeat with correction
%                toreturn{9} = 1x nC cell, control intensity for this repeat 


colors=prism(nC); % Define plot colors for each condition
pathway_ctrl=''; % pathway of the control files
listSubplot=nan*(1:2*nC);
listSubCtrl=nan*(1:nC);

samectrl=false; % test if the control is the same between different conditions

% Get name of subfolders in the main folder  
d=dir(pathway);
isub=[d(:).isdir];
namesFoldsCond={d(isub).name};
namesFoldsCond(ismember(namesFoldsCond,{'.','..'}))=[];

% Open a new windows to display synthesis of this repeat
fig2=figure('Name','Synthesis ','NumberTitle','off');

% Preallocation for graph list   
p1=nan*(1:2*nC);
pcor1=nan*(1:2*nC);
p2=nan*(1:2*nC);
pcor2=nan*(1:2*nC);
p3=nan*(1:2*nC);
pcor3=nan*(1:2*nC);

% Preallocation for intensities list  
allI=cell(1,nC);
allIcor=cell(1,nC);
allFit=cell(1,nC); % fitness object preallocation
Fit=cell(1,nC); % fitness curves preallocation
filesname=cell(1,nC); %names of files preallocation
t0_5=cell(1,nC); %half life time preallocation
diffIctrl=cell(1,nC); % control intensity preallocation
pval=nan;

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
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%% GUI, Choose Control %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    F22=figure('Name',namesFoldsCond{c},...
        'NumberTitle','off','MenuBar','none');
    F22.set('Position',[450 450 820 200]);
    
    uicontrol('Style','text','String',...
        strcat('Control for condition /  ',namesFoldsCond{c}),...
        'Position', [35 160 250 20],'Visible','on',...
        'Fontweight','bold');
    
    % Pathway for the control files
    txtCtrl=uicontrol('Style','text','String',...
        'Pathway to the folder of control files  : ',...
        'Position', [35 80 250 20],'Visible','on');
    edPathctrl=uicontrol('Style','edit', 'Position', [270,82,390,20],...
        'String',pathway_ctrl,'Visible','on');
    browctrl=uicontrol('Style','pushbutton','Position',[675,82,80,20],...
        'String','Browser','Callback',@browser_ctrl,'Visible','on');
    tools=[txtCtrl,edPathctrl,browctrl]; % list of uicontrols linked to browser
    
    % Check if same control as for previous condition
    if c>1
        uicontrol('Style','text','String',...
            'Same as precedent condition  : ',...
            'Position', [105 120 250 20],'Visible','on');
        uicontrol('Style','checkbox', 'Position', [415,122,30,20],...
            'CallBack',@singlectrl,'Visible','on');
    end
    
    % OK button
    uicontrol('Style','pushbutton','String','OK',...
        'Position', [410,40,30,20],'Callback','uiresume(gcbf)');
    
    uiwait;
    pathway_ctrl=edPathctrl.get('String');

    close(F22)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    figure(fig)
    % Calculate dye accumulation
    if samectrl==false
        diffI=ctrlAccum(pathway_ctrl,fig,subplot(nC,3,3*c),format,type_proj)
        listSubCtrl(c)=subplot(nC,3,3*c);
        diffIctrl{c}=diffI;
    else
        diffIctrl{c}=diffIctrl{c-1};
    end
    
    % Get videos names
    fprintf(['\n', namesFoldsCond{c},'\n'])    
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

    %nV=3; % just to check quickier
    I=cell(nV,1); % matrix which will contain every intensities for 1 condition
    Icor=cell(nV,1); %intensity after correction
    
    % Calculte intensity for each image and plot it
    col=hsv(nV);
    
    figure(fig)
    set(subplot(nC,3,3*c-2),'NextPlot','add')
    set(subplot(nC,3,3*c-1),'NextPlot','add')
       
    pltcurv=zeros(1,nV);
    pltcurvCor=zeros(1,nV);
    
    for iv=1:nV
        fprintf(['\n Image ',files(iv).name,'\n']);
        filesname{c}{iv}=files(iv).name;
        name=strcat(pathway_complete,'/',files(iv).name);
        [intensity,time]=analyseIntens(name,type_proj,format,increase);
        I{iv}=intensity;
        Icor{iv}=intensity-diffI;     
        figure(fig)
        subplot(nC,3,3*c-2)
        pltcurv(iv)=line(time,intensity,'DisplayName',files(iv).name,'color',col(iv,:));
        set(get(get(pltcurv(iv),'Annotation'),'LegendInformation'),...
            'IconDisplayStyle','off');
        subplot(nC,3,3*c-1)
        pltcurvCor(iv)=line(time,Icor{iv},'DisplayName',files(iv).name,'color',col(iv,:));
        set(get(get(pltcurvCor(iv),'Annotation'),'LegendInformation'),...
            'IconDisplayStyle','off');
        
    end
    listSubplot(2*c-1:2*c)=[subplot(nC,3,3*c-1),subplot(nC,3,3*c-2)];
    
    %Allow to suppress outliers
    ftxt=figure('Name','Select outliers','NumberTitle','off','MenuBar','none',...
    'Position',[1 1 250 90]);
    movegui(ftxt,'northwest');
    axes('Position',[0 0 1 1],'Visible','off');
    desc={'Click on the outliers curves';'from the last graph (without control)';...
        ' to exclude them from the analysis';...
        '(if they exists)';'Press <Return> when you have finished'};
    tex=text(0.4,0.7,desc);
    tex.HorizontalAlignment='center';
    set(tex,'Position',[0.5,0.5]);
    
    figure(fig)
    subplot(nC,3,3*c-2)
    [xOut,yOut]=ginput();
    close(ftxt)
    
    if ~isempty(xOut)
        newI=cell2mat(I);
        newI=newI(:,knnsearch(time',xOut));
        for iOut=1:length(xOut)
            ind=knnsearch(newI(:,iOut),yOut(iOut));
            I{ind}=[];
            Icor{ind}=[];
            set(pltcurv(ind),'Visible','off');
            set(pltcurvCor(ind),'Visible','off');
            fprintf([files(ind).name,' ignored \n']);
        end
        I=I(~cellfun('isempty',I));
        Icor=Icor(~cellfun('isempty',Icor));
    end
    
    %Check is all videos have same length or cut the longest ones
    lensI=cellfun(@length,I);
    if length(unique(lensI))>1
        lenmin=min(lensI);
         for i=1:size(I,1)
             if length(I{i})>lenmin
                 I{i}=I{i}(1:lenmin);
                 Icor{i}=Icor{i}(1:lenmin);
             end
         end
         if length(time)>lenmin
             time=time(1:lenmin);
         end
    end
    
    
    
    figure(fig)
    % Plot average and median on existant graph
    subplot(nC,3,3*c-2)
    if nV>1
        Av=nanmean(cell2mat(I));
        Med=nanmedian(cell2mat(I));
        line(time,Av,'color',[1 0 0],'LineWidth',2);
        line(time,Med,'color',[0 1 0],'LineWidth',2);
    else
        Av=I{1};
        Med=I{1};
    end
    hold off;
    title(strcat(namesFoldsCond{c},' without correction'))
    legend('Avg','Med')
    
    subplot(nC,3,3*c-1)
    if nV>1
        Avcor=nanmean(cell2mat(Icor));
        Medcor=nanmedian(cell2mat(Icor));
        line(time,Avcor,'color',[1 0 0],'LineWidth',2);
        line(time,Medcor,'color',[0 1 0],'LineWidth',2);
    else
        Avcor=Icor;
        Medcor=Icor;
    end
    hold off;
    title(strcat(namesFoldsCond{c},' with correction'))
    legend('Avg','Med')
    
    figure(fig2)
    % Plot average + confidence interval in a new graph
    subplot(3,2,1)
    p1(c)=line(time,Av,'color',colors(c,:));
    hold on
    p1(c+nC)=plot_confIntAvg(cell2mat(I),time,colors(c,:));
    
    subplot(3,2,2)
    pcor1(c)=line(time,Avcor,'color',colors(c,:));
    hold on
    pcor1(c+nC)=plot_confIntAvg(cell2mat(Icor),time,colors(c,:));
    
    % Plot median + confidence interval in a new graph
    subplot(3,2,3)
    p2(c)=line(time,Med,'color',colors(c,:));
    hold on
    p2(c+nC)=plot_confIntMed(cell2mat(I),time,colors(c,:));
    
    subplot(3,2,4)
    pcor2(c)=line(time,Medcor,'color',colors(c,:));
    hold on
    pcor2(c+nC)=plot_confIntMed(cell2mat(Icor),time,colors(c,:));

    % Plot 2 exponential model + confidence interval on a new graph
    subplot(3,2,5)
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
    eq=coeff(1)*exp(coeff(2)*t)+coeff(3)*exp(coeff(4)*t)==50;
    t0_5{c}=double(vpasolve(eq,t));
    text(time(length(time))-5,80-5*(c-1),strcat('t1/2= ',num2str(t0_5{c}),' min'),...
        'color',colors(c,:));
   
     % Plot 2 exponential model + confidence interval on a new graph
    subplot(3,2,6)
    Icor2=cell2mat(Icor);
    Icor2(any(isnan(Icor2), 2),:)=[];
    x=sort(repmat(time',size(I2,1),1));
    f=fit(x,Icor2(:),'exp2');
    predictcor=f(time);
    hold on
    pcor3(c)=line(time,predictcor,'color',colors(c,:));
    P=predint(f,time,0.95,'functional','on');
    Xplot=[time,fliplr(time)];
    Yplot=[P(:,1)',fliplr(P(:,2)')];
    pcor3(c+nC)=fill(Xplot,Yplot,1,'facecolor',colors(c,:),...
    'LineStyle','- -', 'facealpha', 0.2,...
    'edgecolor',colors(c,:));
    Fitcor{c}=predictcor;

    % Plot half-life time
    syms t
    coeff=coeffvalues(f);
    eq=coeff(1)*exp(coeff(2)*t)+coeff(3)*exp(coeff(4)*t)==50;
    t0_5cor=double(vpasolve(eq,t));
    text(time(length(time))-5,80-10*(c-1),strcat('t1/2= ',num2str(t0_5cor),' min'),...
        'color',colors(c,:));
   
    if isempty(legendinfo{c})
        legendinfo{c}=[namesFoldsCond{c}];
    end
    
    allI{c}=cell2mat(I);
    allIcor{c}=cell2mat(Icor);
end

figure(fig)
for ax=listSubplot
    set(get(ax,'xlabel'),'String','Time (min)')
    set(get(ax,'Ylabel'),'String','Total intensities (%)')
end
listSubCtrl=listSubCtrl(~isnan(listSubCtrl));
linkaxes(listSubCtrl)

linkaxes(listSubplot)

figure(fig2)
listSubSynth=[subplot(3,2,1),subplot(3,2,2),...
    subplot(3,2,3),subplot(3,2,4),...
    subplot(3,2,5),subplot(3,2,6)]; % list of all subplots to link after

%Set axis labels and title  
for ax=listSubSynth
    set(get(ax,'xlabel'),'String','Time (min)')
    set(get(ax,'Ylabel'),'String','% intensities')
end

axAvg=subplot(3,2,1);
title('Average curves without correction')
legend(axAvg,p1(1:nC),legendinfo)

axAvgcor=subplot(3,2,2);
title('Average curves with correction')
legend(axAvgcor,pcor1(1:nC),legendinfo)

axMed= subplot(3,2,3);
title('Median curves without correction')
legend(axMed,p2(1:nC),legendinfo)

axMedcor= subplot(3,2,4);
title('Median curves with correction')
legend(axMedcor,pcor2(1:nC),legendinfo)

axFit= subplot(3,2,5);
title('Two-Exponential Model without correction')
legend(axFit,p3(1:nC),legendinfo)
% Plot stat difference for each time
if nC==2
    Fit=cell2mat(Fit);
    fprintf('P-value : \n')
    pval=zeros(1,length(time));
    cond1=cell2mat(allI(:,1));
    cond2=cell2mat(allI(:,2));
    for t=1:length(time)
        pval(t)=ranksum(cond1(:,t),cond2(:,t));
    end
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
axFitcor= subplot(3,2,6);
title('Two-Exponential Model with correction')
legend(axFitcor,pcor3(1:nC),legendinfo)
% Plot stat difference for each time
if nC==2
    Fitcor=cell2mat(Fitcor);
    for t=2:length(time)
        if pval(t)<0.001
            text(time(t)-0.2,max(Fitcor(t,:))+5,'***');
        else
            if pval(t)<0.01
                text(time(t)-0.2,max(Fitcor(t,:))+5,'**');
            else
                if pval(t) <0.05
                    text(time(t)-0.2,max(Fitcor(t,:))+5,'*');
                end
            end
        end
    end
end


linkaxes(listSubSynth)

toreturn={legendinfo,allI,allFit,time,filesname,pval,t0_5,allIcor,diffIctrl};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% GUI functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Set the control identical as previous one
    function singlectrl(hObject,~,~)
        if (get(hObject,'Value') == get(hObject,'Max'))
            samectrl=true;
            for tobj=1:3
                tools(tobj).set('Visible','off');
            end
        else
            samectrl=false;
            for tobj=1:3
                tools(tobj).set('Visible','on');
            end
        end
        
    end

    % Get control pathway
    function browser_ctrl(~,~)
        if pathway_ctrl ~=0
            pathway_ctrl=uigetdir(pathway_ctrl);
        else
            if pathway~=0
                pathway_ctrl=uigetdir(pathway);
            else
                pathway_ctrl=uigetdir();
            end
        end
        edPathctrl.String=pathway_ctrl;
    end
end




