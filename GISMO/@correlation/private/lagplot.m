function lagplot(c);


% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks


% PREP PLOT
figure('Color','w','Position',[50 50 600 500]);
set(gcf,'DefaultAxesFontSize',14);
imagesc(c.L);
title('Lag time for maximum correlation (s)');



% ADD DATES TO AXES
n = length(c.trig);
set(gca,'XTick',[1:round(n/25):n]);
set(gca,'YTick',[1:round(n/25):n]);
yt = get(gca,'YTick');
set(gca,'YTickLabel',datestr(c.trig(yt),'yyyy-mm-dd HH:MM'),'FontSize',6);


% DRESS UP THE FIGURE
cmap = load('colormap_lag.txt');
colormap(cmap);
colorbar;
xlabel('Event number');
ylabel('Event date');


%PRINT OUT FIGURE
set(gcf, 'paperorientation', 'portrait');
set(gcf, 'paperposition', [1.25 2.5 6 6] );
%print(gcf, '-depsc2', 'FIG_tartan.ps')
