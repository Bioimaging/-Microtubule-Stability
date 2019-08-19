function saveData(allI,allFit,time,all_names,all_pval,t_05,varargin)
%% Save datas in excel file
%
% SYNOPSIS : saveData(allI,allFit,time,all_names,all_pval,t_05)
%            saveData(allI,allFit,time,all_names,all_pval,t_05,ictrl)
%
% INPUT :   allI : nR x nC, intensities of all the cells of all repeats and
%                   conditions
%           allFit : nR x nC, Fit objects of all repeats and conditions
%           time : global time (for x axis)
%           all_names : nR x nC, name of the videos files for each
%                        repeat and condition
%           all_pval : nR, pvalues to compare two conditions for each
%                       repeat
%           t_05 : nR x nC, all half-life time
%           ictrl : nR x nC, control intensity for each repeat and
%                    conditions




[nR,nC]=size(allI);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% Save the data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
F3=figure('Name','Saving','Position',[1,1,800,200],'MenuBar','none');
movegui(F3,'center');
pathway_save='';
saveFig=false;
subgrp1=uipanel('Parent',F3,'Units','pixels','Position',...
    [0 0 780 200],'Bordertype','none');

% Pathway to the folder
uicontrol('Style','text','String',...
    'Pathway to the folder to save the data  : ','Parent',subgrp1,...
    'Units','normalized','Position', [0.01 0.80 0.3 0.08]);
edPath=uicontrol('Style','edit','Parent',subgrp1,...
    'Units','normalized','Position', [0.31 0.80 0.58 0.08],...
    'String',pathway_save);
uicontrol('Style','pushbutton','Parent',subgrp1,...
    'Units','normalized','Position', [0.9 0.80 0.08 0.08],...
    'String','Browser','Callback',@browser2);

% Name of the experiment
uicontrol('Style','text','String',...
    'Name of the experiment  : ','Parent',subgrp1,...
    'Units','normalized','Position', [0.01 0.60 0.3 0.08]);
edName=uicontrol('Style','edit','Parent',subgrp1,...
    'Units','normalized','Position', [0.31 0.60 0.58 0.08],...
    'String',pathway_save);

% Do you want to save figure
uicontrol('Style','text','Parent',subgrp1,'String',...
    'Do you want to save figures ? ',...
    'Units','normalized','Position', [0.01 0.40 0.3 0.08]);
bg=uibuttongroup('Visible','off','Parent',subgrp1,'Position',...
    [0.35 0.40 0.3 0.08],'SelectionChangedFcn',@Savefigure,...
    'Bordertype','none');
uicontrol(bg,'Style','radiobutton','String','Yes',...
    'Position',[5 1 50 20],'HandleVisibility','off','Value',0);
uicontrol(bg,'Style','radiobutton','String','No',...
    'Position',[60 1 80 20],'HandleVisibility','off','Value',1);
bg.Visible = 'on';

% OK button
uicontrol('Style','pushbutton','Parent',subgrp1,...
    'String','Save','Fontweight','bold',...
    'Units','normalized','Position', [0.40 0.20 0.08 0.08],...
    'Callback','uiresume(gcbf)');

% Quit button
quitOK=false;
uicontrol('Style','pushbutton','Parent',subgrp1,...
    'String','Quit','Fontweight','bold',...
    'Units','normalized','Position', [0.55 0.20 0.08 0.08],...
    'Callback',@quit);

uiwait;
pathway_save=edPath.get('String');
expname=edName.get('String');
close(F3)

if ~quitOK
    mkdir(strcat(pathway_save,'/',expname))
    if saveFig
        hold off
        figs=get(0,'Children');
        for f=1:length(figs)
            savefig(figs(f),strcat(pathway_save,'/',expname,'\Figure',num2str(f),'.fig'),'compact');
        end
    end
    
    if ispc
        
        fprintf('Saving data ... \n');
        
        namexlsfile=strcat(pathway_save,'/',expname,'/',expname,'.xls');
        
        xlswrite(namexlsfile,nan)
        
        e = actxserver('Excel.Application'); % # open Activex server
        ewb = e.Workbooks.Open(namexlsfile); % # open file (enter full path!)
        for r=1:nR
            for c=1:nC
                if (r-1)*nC+c >ewb.Worksheets.Count
                    ewb.Worksheets.Add([],ewb.Worksheets.Item(ewb.Worksheets.Count));
                end
                ewb.Worksheets.Item((r-1)*nC+c).Name = strcat('R',num2str(r),'C',num2str(c));
            end
        end
        ewb.Save % # save to the same file
        ewb.Close(false)
        e.Quit
        
        
        for r=1:nR
            for c=1:nC
                sheet=strcat('R',num2str(r),'C',num2str(c));
                xlswrite(namexlsfile,['Name', num2cell(time),'min'],sheet)
                nv=length(all_names{r,c});
                % Save all intensities
                for iv=1:nv
                    vidname=all_names{r,c}{iv};
                    xlswrite(namexlsfile,...
                        [vidname, num2cell(allI{r,c}(iv,:)),'%'],sheet,...
                        strcat('A',num2str(iv+1)));
                end
                
                %Save Mean
                xlswrite(namexlsfile,...
                    ['Mean', num2cell(nanmean(allI{r,c})),'%'],sheet,...
                    strcat('A',num2str(nv+3)));
                
                %Save Median
                xlswrite(namexlsfile,...
                    ['Median', num2cell(nanmedian(allI{r,c})),'%'],sheet,...
                    strcat('A',num2str(nv+4)));
                
                %Save Fit info
                f=allFit{r,c};
                coeff=num2cell(coeffvalues(f));
                xlswrite(namexlsfile,...
                    ['2-Exp Model', num2cell(f(time)'),'%'],sheet,...
                    strcat('A',num2str(nv+5)));
                txt=['Model',nan,'a=',coeff(1),nan,'b=',coeff(2),...
                    nan,'c=',coeff(3),nan,'d=',coeff(4)];
                xlswrite(namexlsfile,txt,sheet,strcat('A',num2str(nv+7)));
                
                xlswrite(namexlsfile,['t1/2=',nan,num2cell(t_05{r,c}),'min'],...
                    sheet,strcat('A',num2str(nv+8)));
                
                %Save pval
                xlswrite(namexlsfile,...
                    ['P value', num2cell(all_pval{r})],sheet,...
                    strcat('A',num2str(nv+10)));
                
                % Save accumulation
                if ~isempty(varargin)
                    xlswrite(namexlsfile,...
                        ['Correction', num2cell(varargin{1}{r,c})],sheet,...
                        strcat('A',num2str(nv+12)));
                end
            end
        end
    end
end
fprintf('END \n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% GUI functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get pathway to the saving folder
    function browser2(~,~)
        if pathway_save ~=0
            pathway_save=uigetdir(pathway_save);
        else
            pathway_save=uigetdir();
        end
        edPath.String=pathway_save;
    end

% Define if we have to save figures
    function Savefigure(~,event)
        if strcmp(event.NewValue.String,'Yes')
            saveFig=true;
        else
            saveFig=false;
        end
        
    end

% Quit without saving
    function quit(~,~)
        quitOK=true;
        uiresume(gcbf);
    end

end