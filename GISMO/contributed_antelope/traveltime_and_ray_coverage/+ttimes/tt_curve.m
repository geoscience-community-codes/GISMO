function traveltime(dbName,varargin)

%TRAVELTIME make travel time plots.
% TRAVELTIME(dbName) creates travel time plots for database dbName. The top
% plot for P and S plots ditance vs. traveltime in seconds adjusted by a
% velocity reduction.
%
% TRAVELTIME(dbName,[Vp Vs]) use the specified velocities to reduce the
% times on the travel time plots. The default values are Vp = 7 and Vs = 4.
%
% see also ttimes.dbload
 

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date: 2010-07-02 14:24:55 -0800 (Fri, 02 Jul 2010) $
% $Revision: 242 $ 


% GET ARGUMENTS
if length(varargin)==1
    VpVs = varargin{1};
else
    VpVs = [7 4];
end



% LOAD DATABASE
[origin,site,arrival,ray] = ttimes.dbload(dbName);



% TRAVEL TIME PLOTS
figure('Position',[0 0 1100 850],'Color','w');
set(gcf,'DefaultAxesFontSize',14);
set(gcf,'DefaultAxesLineWidth',0.25);


% P WAVES
f = find(strcmp(arrival.iphase,'P'));
h1 = subplot(2,2,1);
scatter(ray.flatDist(f),arrival.travelTime(f)-ray.flatDist(f)/VpVs(1),30,ray.originDepth(f),'filled','MarkerEdgeColor','k');
hold on; box on; grid on;
xlabel('Distance (km)');
ylabel(['Traveltime - distance/' num2str(VpVs(1)) 'km/s (s)']);
title('P wave travel times');
xlim1 = get(gca,'xlim');
ylim1 = get(gca,'ylim');
%
h3 = subplot(2,2,3);
scatter(ray.flatDist(f),arrival.timeres(f),30,ray.originDepth(f),'filled','MarkerEdgeColor','k');
hold on; box on; grid on;
xlabel('Distance (km)');
ylabel('Time residual (s)');
title('P wave travel time residuals');
xlim3 = get(gca,'xlim');
ylim3 = get(gca,'ylim');


% S WAVES
f = find(strcmp(arrival.iphase,'S'));
h2 = subplot(2,2,2);
scatter(ray.flatDist(f),arrival.travelTime(f)-ray.flatDist(f)/VpVs(2),30,ray.originDepth(f),'filled','MarkerEdgeColor','k');
hold on; box on; grid on;
xlabel('Distance (km)');
ylabel(['Traveltime - distance/' num2str(VpVs(2)) 'km/s (s)']);
title('S wave travel times');
xlim2 = get(gca,'xlim');
ylim2 = get(gca,'ylim');
%
h4 = subplot(2,2,4);
scatter(ray.flatDist(f),arrival.timeres(f),30,ray.originDepth(f),'filled','MarkerEdgeColor','k');
hold on; box on; grid on;
xlabel('Distance (km)');
ylabel('Time residual (s)');
title('S wave travel time residuals');
xlim4 = get(gca,'xlim');
ylim4 = get(gca,'ylim');
%
h = colorbar('Location','east');
cmap = hot;
%colormap(flipud(cmap));
colormap(cmap);
position = get(h,'Position');
position(3) = position(3)/2;
position(4) = position(4)/2;
set(h,'Position',position);
set(h,'YDir','reverse');
set(h,'FontSize',9);
hh = get(h,'YLabel');
set(hh,'String','Depth (km)');
%
xLim = [0 max(ray.flatDist)];
yLim12 = [ min([ylim1 ylim2]) max([ylim1 ylim2])];
yLim34 = [ min([ylim3 ylim4]) max([ylim3 ylim4])];
set(h1,'xlim',xLim,'ylim',yLim12);
set(h2,'xlim',xLim,'ylim',yLim12);
set(h3,'xlim',xLim,'ylim',yLim34);
set(h4,'xlim',xLim,'ylim',yLim34);
%
set(gcf, 'paperorientation', 'landscape');
set(gcf, 'paperposition', [.5 .5 10 7.5] );
print(gcf, '-dpsc2', 'FIG_tt_curve.ps');


