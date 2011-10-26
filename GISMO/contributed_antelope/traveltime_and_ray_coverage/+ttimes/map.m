function map(dbName)

%MAP plot a map of ray coverage.
% MAP(dbName) creates map view plots of straight line ray coverage,
% hypocenters and stations for database dbName. Requires the mapping
% toolbox. There is one plot each for P and S wave coverage.
%
% see also ttimes.dbload


% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date: 2010-07-02 14:24:55 -0800 (Fri, 02 Jul 2010) $
% $Revision: 242 $ 


% LOAD DATABASE
[origin,site,arrival,ray] = ttimes.dbload(dbName);



% PREP MAP PARAMETERS
latmin = min([ray.originLat ;  ray.siteLat]);
latmax = max([ray.originLat ;  ray.siteLat]);
lonmin = min([ray.originLon ;  ray.siteLon]);
lonmax = max([ray.originLon ;  ray.siteLon]);
depthmin = min([ray.originDepth ;  ray.siteElev]);
depthmax = max([ray.originDepth ;  ray.siteElev]);


% PLOT MAP VIEW
figure('Position',[0 0 1100 850],'Color','w');
set(gcf,'DefaultAxesFontSize',14);
set(gcf,'DefaultAxesLineWidth',0.5);
%
subplot(1,2,1)
f = find(strcmp(arrival.iphase,'P'));
h = worldmap([latmin latmax],[lonmin lonmax]);
load coast
plotm(lat, long)
geoshow('landareas.shp', 'FaceColor', [1 1 0.8])
geoshow('worldlakes.shp', 'FaceColor', [.9 .9 1])
geoshow('worldrivers.shp', 'Color', 'blue')
plotm([ray.originLat(f) ray.siteLat(f)]',[ray.originLon(f) ray.siteLon(f)]','-','Color',[0.7 0.7 0.7],'LineWidth',0.5)
plotm(origin.lat,origin.lon,'ko','MarkerFaceColor','r','MarkerSize',4)
plotm(site.lat,site.lon,'kv','MarkerFaceColor','c','MarkerSize',9)
title('P wave ray coverage');
%
subplot(1,2,2)
f = find(strcmp(arrival.iphase,'S'));
h = worldmap([latmin latmax],[lonmin lonmax]);
load coast
plotm(lat, long)
geoshow('landareas.shp', 'FaceColor', [1 1 0.8])
geoshow('worldlakes.shp', 'FaceColor', [.9 .9 1])
geoshow('worldrivers.shp', 'Color', 'blue')
plotm([ray.originLat(f) ray.siteLat(f)]',[ray.originLon(f) ray.siteLon(f)]','-','Color',[0.7 0.7 0.7],'LineWidth',0.5)
plotm(origin.lat,origin.lon,'ko','MarkerFaceColor','r','MarkerSize',4)
plotm(site.lat,site.lon,'kv','MarkerFaceColor','c','MarkerSize',9)
title('S wave ray coverage');
%
set(gcf, 'paperorientation', 'landscape');
set(gcf, 'paperposition', [.5 .5 10 7.5] );
print(gcf, '-dpsc2', 'FIG_map.ps');

