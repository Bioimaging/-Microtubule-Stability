function plotFinalComparison(fig,allI,nC,time,legendinfo)
%% Display synthese of all repetitions
%
% SYNOPSIS : plotFinalComparison(fig,allI,nC,time,legendinfo)
%
% INPUT :   fig : the fig to display synthese
%           allI : nR x nC, intensities of all the cells of all repeats and
%                   conditions
%           nC : int, number of conditions compared
%           time : global time (for x axis)
%           legendinfo : the list of the conditions' names

    figure(fig)
    plc=nan*(1:nC);
    colors=prism(nC);
    
    % Test difference
    if nC==2
        pval=zeros(1,length(time));
        cond1=cell2mat(allI(:,1));
        cond2=cell2mat(allI(:,2));
        for t=1:length(time)
          pval(t)=ranksum(cond1(:,t),cond2(:,t));  
        end  
        fprintf('P-value : \n');
        pval
    end
    
    % Mean
    axAvg=subplot(1,3,1);
    Avg=cell(nC,1);
    for c=1:nC
        Avg{c}=nanmean(cell2mat(allI(:,c)));
        B=bootci(1000,{@nanmean,cell2mat(allI(:,c))},'type','percentile');
        plc(c)=errorbar(time,Avg{c},...
            abs(B(1,:)-Avg{c}),...
            abs(B(2,:)-Avg{c}),'color',colors(c,:));
    end
    
     % Plot stat difference for each time
    if nC==2
        Avg2=cell2mat(Avg);
        for t=2:length(time)
            if pval(t)<0.001
                text(time(t)-0.2,max(Avg2(:,t))+5,'***');
            else
                if pval(t)<0.01
                    text(time(t)-0.2,max(Avg2(:,t))+5,'**');
                else
                    if pval(t) <0.05
                        text(time(t)-0.2,max(Avg2(:,t))+5,'*');
                    end
                end
            end         
        end
    end
    
    hold off
    title('Average curves for each condition')
    xlabel('Time (min)')
    ylabel('Total intensities (%)')
    legend(axAvg,plc(1:nC),legendinfo)
    
    
    % Median
    axMed=subplot(1,3,2);
    Med=cell(nC,1);
    for c=1:nC
        Med{c}=nanmedian(cell2mat(allI(:,c)));
        B=bootci(1000,{@nanmedian,cell2mat(allI(:,c))},'type','percentile');
        plc(c)=errorbar(time,Med{c},...
            abs(B(1,:)-Med{c}),...
            abs(B(2,:)-Med{c}),'color',colors(c,:));
    end
    
    % Plot stat difference for each time
    if nC==2
        Med2=cell2mat(Med);
        for t=2:length(time)
            if pval(t)<0.001
                text(time(t)-0.2,max(Med2(:,t))+5,'***');
            else
                if pval(t)<0.01
                    text(time(t)-0.2,max(Med2(:,t))+5,'**');
                else
                    if pval(t) <0.05
                        text(time(t)-0.2,max(Med2(:,t))+5,'*');
                    end
                end
            end         
        end
    end
    
    
    hold off
    title('Median curves for each condition')
    xlabel('Time (min)')
    ylabel('Total intensities (%)')
    legend(axMed,plc(1:nC),legendinfo)
    
    % Two Exponential Model
    axFit=subplot(1,3,3);
    Fit=cell(1,nC);
    text(time(length(time))-5,83,'Half life time (min) :')
    for c=1:nC
        I2=cell2mat(allI(:,c));
        I2(any(isnan(I2), 2),:)=[];
        x=sort(repmat(time',size(I2,1),1));
        f=fit(x,I2(:),'exp2');
        Fit{c}=f(time);
        P=predint(f,time,0.95,'functional','on');
        plc(c)=errorbar(time,Fit{c},...
            abs(P(:,1)-Fit{c}),'color',colors(c,:),'Marker','.');
       
        % Plot half-life time
        syms t
        coeff=coeffvalues(f);
        eq=coeff(1)*exp(coeff(2)*t)+coeff(3)*exp(coeff(4)*t)==50;
        t0_5=double(vpasolve(eq,t));
        text(time(length(time))-5,80-3*(c-1),strcat('t1/2= ',num2str(t0_5),' min'),...
            'color',colors(c,:));
        line([t0_5,t0_5],[0,f(t0_5)],'LineStyle','--','color',colors(c,:))
        line([0,t0_5],[f(t0_5),f(t0_5)],'LineStyle','--','color',colors(c,:))
    end
    
    % Plot stat difference for each time
    if nC==2
        F2=cell2mat(Fit);
        for t=2:length(time)
            if pval(t)<0.001
                text(time(t)-0.2,max(F2(t,:))+5,'***');
            else
                if pval(t)<0.01
                    text(time(t)-0.2,max(F2(t,:))+5,'**');
                else
                    if pval(t) <0.05
                        text(time(t)-0.2,max(F2(t,:))+5,'*');
                    else
                        text(time(t)-0.2,max(F2(t,:))+5,'ns');
                    end
                end
            end         
        end
    end
    
    hold off
    title('Two-Exponential model for each condition')
    xlabel('Time (min)')
    ylabel('Total intensities (%)')
    legend(axFit,plc(1:nC),legendinfo)
    
    linkaxes([subplot(1,3,1),subplot(1,3,2),subplot(1,3,3)])
    xlim([0 floor(max(time))+1])
    
end