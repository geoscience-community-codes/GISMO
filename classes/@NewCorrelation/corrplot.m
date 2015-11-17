function corrplot(c)
%corrplot   plot the correlation matrix
% Called internally by correlation/plot to plot correlation matrix.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


% PREP PLOT
figure('Color','w','Position',[50 50 600 500]);
set(gcf,'DefaultAxesFontSize',14);
imagesc(c.corrmatrix);
title('Maximum correlation coefficient');


% ADD DATES TO AXES
n = length(c.trig);
ticvalues = 1:round(n/25):n;
set(gca,'XTick',ticvalues);
set(gca,'YTick',ticvalues);
yt = get(gca,'YTick');
set(gca,'YTickLabel',datestr(c.trig(yt),'yyyy-mm-dd HH:MM'),'FontSize',6);

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
