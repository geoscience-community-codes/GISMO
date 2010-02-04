function corrplot(c)

% Called internally by correlation/plot to plot correlation matrix.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


% PREP PLOT
figure('Color','w','Position',[50 50 600 500]);
set(gcf,'DefaultAxesFontSize',14);
imagesc(c.C);
title('Maximum correlation coefficient');


% ADD DATES TO AXES
n = length(c.trig);
set(gca,'XTick',[1:round(n/25):n]);
set(gca,'YTick',[1:round(n/25):n]);
yt = get(gca,'YTick');
set(gca,'YTickLabel',datestr(c.trig(yt),'yyyy-mm-dd HH:MM'),'FontSize',6);

%xt = get(gca,'XTick');
%set(gca,'XTickLabel',datestr(c.trig(xt),'yyyy-mm-dd HH:MM'),'FontSize',6,'Rotation',90);


% DRESS UP THE FIGURE
caxis([0 1]);
cmap = load('colormap_corr.txt');
colormap(cmap);
colorbar;
xlabel('Event number');
ylabel('Event date');


%PRINT OUT FIGURE
set(gcf, 'paperorientation', 'portrait');
set(gcf, 'paperposition', [1.25 2.5 6 6] );
%print(gcf, '-depsc2', 'FIG_tartan.ps');
