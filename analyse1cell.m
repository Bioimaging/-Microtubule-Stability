%% Perform the global analyse evolution of intensities of the microtubules
%in ONE video
%
% SYNOPSIS : analyse1cell()

function analyse1cell()
clc %clear command windows
clear all % clear workscape and functions
close all % close every open windows
addpath('bfmatlab-2')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% GUI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
F1=figure('Name','Settings','NumberTitle','off','MenuBar','none',...
    'Position',[1 1 720,260]);
movegui(F1,'center');

%Name video
video='';
name_file='';
uicontrol('Style','text','String',...
        'Select the video  : ','Position', [8 220 240 16]);
edPath=uicontrol('Style','edit','Position', [200 220 400 16],...
        'String',video);
uicontrol('Style','pushbutton','Position', [620 220 64 16],...
        'String','Browser','Callback',@browser);

% Choose to display segmentation
saveSeg=true;
uicontrol('Style','text','String','Do you want to display Segmentation : ',...
    'Position', [180 180 200 16]);
bg=uibuttongroup('Visible','off','Position',[0.55 0.69 0.3 0.07],...
    'SelectionChangedFcn',@selectSeg,'Bordertype','none');
uicontrol(bg,'Style','radiobutton','String','Yes',...
    'Position',[5 1 50 20],'HandleVisibility','off','Value',1);
uicontrol(bg,'Style','radiobutton','String',' No',...
    'Position',[60 1 80 20],'HandleVisibility','off','Value',0);
bg.Visible = 'on';

% Choose kind of projection
type_proj='MAX';
uicontrol('Style','text','String','Kind of projection  : ',...
    'Position', [180 140 200 16]);
bg=uibuttongroup('Visible','off','Position',[0.55 0.52 0.3 0.07],...
    'SelectionChangedFcn',@Projselection,'Bordertype','none');
uicontrol(bg,'Style','radiobutton','String','MAX',...
    'Position',[5 1 50 20],'HandleVisibility','off');
uicontrol(bg,'Style','radiobutton','String','SUM',...
    'Position',[60 1 50 20],'HandleVisibility','off');
bg.Visible = 'on';
% 
% Choose format
format='DelVi';
uicontrol('Style','text','String','Microscope  : ',...
    'Position', [180 100 200 16]);
bg=uibuttongroup('Visible','off','Position',[0.55 0.38 0.3 0.07],...
    'SelectionChangedFcn',@Formatselection,'Bordertype','none');
uicontrol(bg,'Style','radiobutton','String','Nikon',...
    'Position',[5 1 50 20],'HandleVisibility','off','Value',0);
uicontrol(bg,'Style','radiobutton','String','DeltaVision',...
    'Position',[60 1 80 20],'HandleVisibility','off','Value',1);
bg.Visible = 'on';

% Choose increase or not
increase=false;
uicontrol('Style','text','String','Allow intensity increase (> 15%) : ',...
    'Position', [180 60 200 16]);
bg=uibuttongroup('Visible','off','Position',[0.55 0.23 0.3 0.07],...
    'SelectionChangedFcn',@Increaseselection,'Bordertype','none');
uicontrol(bg,'Style','radiobutton','String','Yes',...
    'Position',[5 1 50 20],'HandleVisibility','off','Value',0);
uicontrol(bg,'Style','radiobutton','String',' No',...
    'Position',[60 1 80 20],'HandleVisibility','off','Value',1);
bg.Visible = 'on';

% OK button
uicontrol('Style','pushbutton','String','OK',...
    'Position', [365,20,30,20],'Callback','uiresume(gcbf)');

% Wait for OK button
uiwait;


%%% Get video name
video=edPath.get('String'); % pathway + name

extension=strsplit(video,'.');
extension=extension(length(extension));

% Test if it's the good format
if strcmp(format,'DelVi')
        if ~strcmp(extension,'dv')
            error(strcat('The file is not a ".dv" file'))
        end
else
        if ~strcmp(extension,'ome.tif')
            error(strcat('The file is not a ".ome.tiff" file'))
        end
end



% Get name of the video
if isempty(name_file)
    if ismac
        name_file=strsplit(video,'/');
    else
        name_file=strsplit(video,'\');
    end
    
    name_file=name_file(length(name_file));
    name_file=name_file{1}(1:length(name_file{1})-3);
else
    name_file=name_file(1:length(name_file)-3);
end

if exist('VideoSeg','dir')~=7
    mkdir('VideoSeg')
end
    


if exist(strcat('VideoSeg/',name_file,'.avi'),'file')==2 % check if the file exist
    F2=figure('Name','File Already Exist','NumberTitle','off','MenuBar','none',...
        'Position',[1 1 300 140]);
    movegui(F2,'center');
    sure=false;
    uicontrol('Style','text','String','The file already exists.',...
        'Position', [10 100 280 20]);
    uicontrol('Style','text','String','Do you want to overwrite it? ',...
        'Position', [10 80 280 20]);
    bg=uibuttongroup('Visible','off','Position',[0.33 0.4 0.4 0.12],...
        'SelectionChangedFcn',@Overwrite,'Bordertype','none');
    uicontrol(bg,'Style','radiobutton','String','Yes',...
        'Position',[5 1 50 20],'HandleVisibility','off','Value',0);
    uicontrol(bg,'Style','radiobutton','String',' No',...
        'Position',[60 1 50 20],'HandleVisibility','off','Value',1);
    bg.Visible = 'on';
    % OK button
    uicontrol('Style','pushbutton','String','OK',...
        'Position', [135,20,30,20],'Callback','uiresume(gcbf)');
    
    % Wait for OK button
    uiwait;
    close(F2)
    
    if ~sure
        c=clock;
        c=strsplit(num2str(c));
        date=strjoin(c(1:length(c)-1),'-');
        name_file=strcat('VideoSeg/',name_file,'-',date,'.avi');
    else
        name_file=strcat('VideoSeg/',name_file,'.avi');
    end
else
    name_file=strcat('VideoSeg/',name_file,'.avi');
end
close(F1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MAIN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[I,time]=analyseIntens(video,type_proj,format,increase,saveSeg,name_file);
fInt=figure('Name','Intensities','NumberTitle','off');
plot(time,I)
title('Total intensity along time')
xlabel('Time (min)')
ylabel('Total intensity %')

% Save curve
name_file=strcat(name_file(1:length(name_file)-4),'.fig');
if exist(name_file,'file')==2 % check if the file exist
    F2=figure('Name','File Already Exist','NumberTitle','off','MenuBar','none',...
        'Position',[1 1 300 140]);
    movegui(F2,'center');
    sure=false;
    uicontrol('Style','text','String','The file already exists.',...
        'Position', [10 100 280 20]);
    uicontrol('Style','text','String','Do you want to overwrite it? ',...
        'Position', [10 80 280 20]);
    bg=uibuttongroup('Visible','off','Position',[0.33 0.4 0.4 0.12],...
        'SelectionChangedFcn',@Overwrite,'Bordertype','none');
    uicontrol(bg,'Style','radiobutton','String','Yes',...
        'Position',[5 1 50 20],'HandleVisibility','off');
    uicontrol(bg,'Style','radiobutton','String',' No',...
        'Position',[60 1 50 20],'HandleVisibility','off');
    bg.Visible = 'on';
    % OK button
    uicontrol('Style','pushbutton','String','OK',...
        'Position', [135,20,30,20],'Callback','uiresume(gcbf)');
    
    % Wait for OK button
    uiwait;
    close(F2)
    
    if ~sure
        c=clock;
        c=strsplit(num2str(c));
        date=strjoin(c(1:length(c)-1),'-');
        name_file=name_file(1:length(name_file)-4);
        name_file=strcat(name_file,'-',date,'.fig');
    end
end
savefig(fInt,name_file);
fprintf('END \n')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% GUI functions %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get video name + pathway
    function browser(~,~)   
        [name_file,path,~]=uigetfile('*.*');
        video=strcat(path,name_file);
        edPath.String=video;
    end

% Select to display segmentation
    function selectSeg(~,event)
        if strcmp(event.NewValue.String,'Yes')
            saveSeg=true;
        else
            saveSeg=false;
        end
        
    end

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

% Allow overwrite
    function Overwrite(~,event)
        if strcmp(event.NewValue.String,'Yes')
            sure=true;
        else
            sure=false;
        end
        
    end
end