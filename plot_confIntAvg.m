function pltconf=plot_confIntAvg(I_,time,col)
B=bootci(1000,{@nanmean,I_},'type','percentile');
Xplot=[time,fliplr(time)];
Yplot=[B(1,:),fliplr(B(2,:))];
pltconf=fill(Xplot,Yplot,1,'facecolor',col,...
    'LineStyle','- -', 'facealpha', 0.2,...
    'edgecolor',col);
end
