function pltconf=plot_confIntMed(I_,time,col)
B=bootci(1000,{@nanmedian,I_},'type','percentile');
% lower=quantile(I_,0.25);
% upper=quantile(I_,0.75);
Xplot=[time,fliplr(time)];
Yplot=[B(1,:),fliplr(B(2,:))];
pltconf=fill(Xplot,Yplot,1,'facecolor',col,...
    'LineStyle','- -', 'facealpha', 0.2,...
    'edgecolor',col);
end
