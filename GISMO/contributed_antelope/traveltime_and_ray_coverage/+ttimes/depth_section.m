function depth_section(dbName)

%DEPTH_SECTION plot depth sections of ray coverage.
% DEPTH_SECTION(dbName) creates depth section views of straight line ray
% coverage, hypocenters and stations for database dbName. There is one
% latitude and one longitude depth section each for P and S wave coverage.
% Postscript version of figure is written utomatically as 
%
% see also ttimes.dbload

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$ 


% LOAD DATABASE
[origin,site,arrival,ray] = ttimes.dbload(dbName);



% PREP MAP PARAMETERS
latmin = min([ray.originLat ;  ray.siteLat]);
latmax = max([ray.originLat ;  ray.siteLat]);
lonmin = min([ray.originLon ;  ray.siteLon]);
lonmax = max([ray.originLon ;  ray.siteLon]);
depthmin = min([ray.originDepth ;  ray.siteElev]);
depthmax = max([ray.originDepth ;  ray.siteElev]);



%% PLOT CROSS SECTIONS
figure('Position',[0 0 850 1100],'Color','w');
set(gcf,'DefaultAxesFontSize',14);
set(gcf,'DefaultAxesLineWidth',0.5);


% P WAVES
f = find(strcmp(arrival.iphase,'P'));
h1 = subplot(2,2,1);
plot([ray.originLat(f) ray.siteLat(f)]',[ray.originDepth(f) ray.siteElev(f)]','-','Color',[0.7 0.7 0.7],'LineWidth',0.5)
hold on;
plot(origin.lat,origin.depth,'ko','MarkerFaceColor','r','MarkerSize',4)
plot(site.lat,site.elev,'kv','MarkerFaceColor','c','MarkerSize',9)
set(gca,'YDir','reverse');
ylim([depthmin depthmax]);
xlabel('Latitude');
ylabel('Depth (km)');
xLim1 = get(gca,'Xlim');
xWidth1 = xLim1(2) - xLim1(1);
title('P wave depth coverage');

%
h2 = subplot(2,2,3);
plot([ray.originLon(f) ray.siteLon(f)]',[ray.originDepth(f) ray.siteElev(f)]','-','Color',[0.7 0.7 0.7],'LineWidth',0.5)
hold on;
plot(origin.lon,origin.depth,'ko','MarkerFaceColor','r','MarkerSize',4)
plot(site.lon,site.elev,'kv','MarkerFaceColor','c','MarkerSize',9)
set(gca,'YDir','reverse');
ylim([depthmin depthmax]);
xlabel('Longitude');
ylabel('Depth (km)');
xLim2 = get(gca,'Xlim');
xWidth2 = (xLim2(2)-xLim2(1)) * cosd(mean(xLim1));
%
if xWidth1>xWidth2
    position = get(gca,'Position');
    position(3) = position(3) * xWidth2/xWidth1;
    position(1) = 0.25 - position(3)/2;
    set(h2,'Position',position);
    set(h2,'xlim',xLim2);
elseif xWidth2>xWidth1
    position = get(gca,'Position');
    position(3) = position(3) * xWidth1/xWidth2;
    position(1) = 0.25 - position(3)/2;
    set(h2,'Position',position);
    set(h2,'xlim',xLim2);
end


% S WAVES
f = find(strcmp(arrival.iphase,'S'));
h1 = subplot(2,2,2);
plot([ray.originLat(f) ray.siteLat(f)]',[ray.originDepth(f) ray.siteElev(f)]','-','Color',[0.7 0.7 0.7],'LineWidth',0.5)
hold on;
plot(origin.lat,origin.depth,'ko','MarkerFaceColor','r','MarkerSize',4)
plot(site.lat,site.elev,'kv','MarkerFaceColor','c','MarkerSize',9)
set(gca,'YDir','reverse');
ylim([depthmin depthmax]);
xlabel('Latitude');
ylabel('Depth (km)');
xLim1 = get(gca,'Xlim');
xWidth1 = xLim1(2) - xLim1(1);
title('S wave depth coverage');
%
h2 = subplot(2,2,4);
plot([ray.originLon(f) ray.siteLon(f)]',[ray.originDepth(f) ray.siteElev(f)]','-','Color',[0.7 0.7 0.7],'LineWidth',0.5)
hold on;
plot(origin.lon,origin.depth,'ko','MarkerFaceColor','r','MarkerSize',4)
plot(site.lon,site.elev,'kv','MarkerFaceColor','c','MarkerSize',9)
set(gca,'YDir','reverse');
ylim([depthmin depthmax]);
xlabel('Longitude');
ylabel('Depth (km)');
xLim2 = get(gca,'Xlim');
xWidth2 = (xLim2(2)-xLim2(1)) * cosd(mean(xLim1));
%
if xWidth1>xWidth2
    position = get(gca,'Position');
    position(3) = position(3) * xWidth2/xWidth1;
    position(1) = 0.75 - position(3)/2;
    set(h2,'Position',position);
    set(h2,'xlim',xLim2);
elseif xWidth2>xWidth1
    position = get(gca,'Position');
    position(3) = position(3) * xWidth1/xWidth2;
    position(1) = 0.75 - position(3)/2;
    set(h2,'Position',position);
    set(h2,'xlim',xLim2);
 end
 %
 set(gcf, 'paperorientation', 'landscape');
 set(gcf, 'paperposition', [.5 .5 10 6.5] );
 print(gcf, '-dpsc2', 'FIG_depth_section.ps');

