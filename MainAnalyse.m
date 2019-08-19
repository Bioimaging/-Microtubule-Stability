
function allI=MainAnalyse()
%% Perform the global analyse evolution of intensities of the microtubules
%in a set of videos
% Can analyse several repetitions of the experiment and compare several
% conditions
%
% SYNOPSIS : MainAnalyse()
%
% See ReadMe file to learn how to use it.


% Clean the workshop and close the open windows
clc
clear all
close all
addpath('bfmatlab-2')

% Get screensize, to adapt the position and size of figures
screensize = get( groot, 'Screensize' );
screensize(3:4)=screensize(3:4)-200;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% GUI, 1rst Figure %%%%%%%%%%%%%%%%%%%%%%%%%%%%
F1=figure('Name','Experimental Plan','NumberTitle','off','MenuBar','none',...
    'Position',[1 1 370 280]);
movegui(F1,'center');

% Choose kind of projection
type_proj='MAX';
uicontrol('Style','text','String','Kind of projection  : ',...
    'Position', [50 225 130 20]);
bg=uibuttongroup('Visible','off','Position',[0.5 0.81 0.31 0.11],...
    'SelectionChangedFcn',@Projselection,'Bordertype','none');
uicontrol(bg,'Style','radiobutton','String','MAX',...
    'Position',[5 1 50 20],'HandleVisibility','off');
uicontrol(bg,'Style','radiobutton','String','SUM',...
    'Position',[60 1 50 20],'HandleVisibility','off');
bg.Visible = 'on';

% Choose format
format='DelVi';
uicontrol('Style','text','String','Microscope  : ',...
    'Position', [50 185 130 20]);
bg=uibuttongroup('Visible','off','Position',[0.5 0.67 0.41 0.11],...
    'SelectionChangedFcn',@Formatselection,'Bordertype','none');
uicontrol(bg,'Style','radiobutton','String','Nikon',...
    'Position',[5 1 50 20],'HandleVisibility','off','Value',0);
uicontrol(bg,'Style','radiobutton','String','DeltaVision',...
    'Position',[60 1 80 20],'HandleVisibility','off','Value',1);
bg.Visible = 'on';

% Choose increase or not
increase=false;
uicontrol('Style','text','String','Allow intensity increase (> 15%) : ',...
    'Position', [50 145 130 28]);
bg=uibuttongroup('Visible','off','Position',[0.5 0.53 0.41 0.11],...
    'SelectionChangedFcn',@Increaseselection,'Bordertype','none');
uicontrol(bg,'Style','radiobutton','String','Yes',...
    'Position',[5 1 50 20],'HandleVisibility','off','Value',0);
uicontrol(bg,'Style','radiobutton','String','No',...
    'Position',[60 1 80 20],'HandleVisibility','off','Value',1);
bg.Visible = 'on';

% Indicate number of repetitions
uicontrol('Style','text','String','Number of repetitions  : ',...
    'Position', [105 100 120 20]);
edRep=uicontrol('Style','edit', 'Position', [230,102,30,20]);

% Indicate number of conditions
uicontrol('Style','text','String','Number of conditions  : ',...
    'Position', [105 60 120 20]);
edCond=uicontrol('Style','edit', 'Position', [230,62,30,20]);

% OK button
uicontrol('Style','pushbutton','String','OK',...
    'Position', [190,20,30,20],'Callback','uiresume(gcbf)');

% Wait for OK button
uiwait;

% Get number of repetitions and conditions
nR=str2double(edRep.get('String'));
nC=str2double(edCond.get('String'));


close(F1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pathway=''; % pathway to the directory of the repeat
legendinfo=cell(1,nC); % name of the conditions

allI=cell(nR,nC); % save intensities of all videos (all repeats, all conditions)
allIcor=cell(nR,nC); % save intensities of all videos with control
allFit=cell(nR,nC); % save fit object of all repeitions and conditions
any_ctrl=false; % test if there's control for at least one repeat
all_names=cell(nR,nC); % save names of all files (all repeats, all conditions)
all_pval=cell(nR); % save pvalues
t_05=cell(nR,nC); % save all half life time

for r=1:nR
    ctrl=false; % test if there's control for this repeat
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%% GUI, Repeat Figure %%%%%%%%%%%%%%%%%%%%%%%%%%
    F2=figure('Name','Intensities ',...
        'Position',[1,1,850,screensize(4)]);
    movegui(F2,'center');
    
    subgrp1=uipanel('Parent',F2,'Units','pixels','Position',...
        [30 screensize(4)-100 780 100]);
    uicontrol('Style','text','String','Settings','Parent',subgrp1,...
        'Units','normalized','Position', [0.01 0.7 0.3 0.2],...
        'Fontweight','bold');
    % Pathway to the folder
    uicontrol('Style','text','String',...
        'Pathway to the folder of this experiment  : ','Parent',subgrp1,...
        'Units','normalized','Position', [0.01 0.4 0.3 0.2]);
    edPath=uicontrol('Style','edit','Parent',subgrp1,...
        'Units','normalized','Position', [0.31 0.4 0.58 0.2],...
        'String',pathway);
    uicontrol('Style','pushbutton','Parent',subgrp1,...
        'Units','normalized','Position', [0.9 0.4 0.08 0.2],...
        'String','Browser','Callback',@browser);
    % Check control for this repeat
    uicontrol('Style','text','Parent',subgrp1,'String',...
        'Do you have videos to controle dye accumulation? ',...
        'Units','normalized','Position', [0 0.1 0.4 0.2]);
    uicontrol('Style','checkbox','Parent',subgrp1,...
        'Units','normalized','Position', [0.38 0.11 0.2 0.2],...
        'CallBack',@globalctrl);
    % Apply settings button
    uicontrol('Style','pushbutton','Parent',subgrp1,...
        'String','Apply settings','Fontweight','bold',...
        'Units','normalized','Position', [0.8 0.11 0.12 0.2],...
        'Callback',@applysettings);
    
    uiwait;
    pathway=edPath.get('String');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ismac
        namerep=strsplit(pathway,'/');
    else
        namerep=strsplit(pathway,'\');
    end
    namerep=namerep(end);
    set(F2,'Name',namerep{1});
    
    if ctrl
        any_ctrl=true;
        outAnalyse=Analysewithcontrol(format,F2,pathway,nC,type_proj,...
            legendinfo,increase);        
        allIcor(r,:)=outAnalyse{8};
        diffI(r,:)=outAnalyse{9};
    else
        outAnalyse=Analysenocontrol(format,F2,pathway,nC,type_proj,...
            legendinfo,increase);
    end
    legendinfo=outAnalyse{1};
    allI(r,:)=outAnalyse{2};
    allFit(r,:)=outAnalyse{3};
    time=outAnalyse{4};
    all_names(r,:)=outAnalyse{5};
    all_pval{r}=outAnalyse{6};
    t_05(r,:)=outAnalyse{7};
end

% Plot synthese of all repeats
%if nR>1

%Check is all videos have same length or cut the longest ones
lensI=cellfun(@length,allI);
if length(unique(lensI))>1
    lenmin=min(unique(lensI));
    for i=1:nR
        for j=1:nC
            if size(allI{i,j},2)>lenmin
                allI{i,j}=allI{i,j}(:,1:lenmin);
            end
        end
    end
    if length(time)>lenmin
        time=time(1:lenmin);
    end
end



% Plot synthese
Ffinal1=figure('Name','Final comparison','NumberTitle','off');
set(subplot(1,3,1),'NextPlot','add')
set(subplot(1,3,2),'NextPlot','add')
set(subplot(1,3,3),'NextPlot','add')

plotFinalComparison(Ffinal1,allI,nC,time,legendinfo);

if any_ctrl %plot the results with control if it exists
    Ffinal2=figure('Name','Final comparison with control','NumberTitle','off');
    set(subplot(1,3,1),'NextPlot','add')
    set(subplot(1,3,2),'NextPlot','add')
    set(subplot(1,3,3),'NextPlot','add')
    plotFinalComparison(Ffinal2,allIcor,nC,time,legendinfo);
end
%end
if ctrl
    saveData(allI,allFit,time,all_names,all_pval,t_05,diffI)
else
    saveData(allI,allFit,time,all_names,all_pval,t_05)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% GUI functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Get the type of projection from radio button
    function Projselection(~,event)
        type_proj=event.NewValue.String;
    end

% Get the type of microscope from radio button
    function Formatselection(~,event)
        if strcmp(event.NewValue.String,'Nikon')
            format='Nikon';
        else
            format='DelVi';
        end
        
    end

% Allow increase >50% from radio button
    function Increaseselection(~,event)
        if strcmp(event.NewValue.String,'Yes')
            increase=true;
        else
            increase=false;
        end
        
    end

% Get pathway of the repeat folder
    function browser(~,~)
        if pathway ~=0
            pathway=uigetdir(pathway);
        else
            pathway=uigetdir();
        end
        edPath.String=pathway;
    end

% Apply the setting when clicking on push button
    function applysettings(~,~)
        uiresume(gcbf);
        subgrp1.set('Visible','off');
    end

% Check if there's a control for this repeat
    function globalctrl(hObject,~,~)
        if (get(hObject,'Value') == get(hObject,'Max'))
            ctrl=true;
        else
            ctrl=false;
        end
    end


end




