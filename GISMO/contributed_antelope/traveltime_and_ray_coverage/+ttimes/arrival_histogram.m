function arrival_histogram(dbName)

%ARRIVAL_HISTOGRAM compare the number of arrivals to each station.
% ARRIVAL_HISTOGRAM(dbName) creates plot comparing the number of P and S
% phase arrivals at each station.
%
% see also ttimes.dbload


% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$ 



% LOAD DATABASE
[origin,site,arrival,ray] = ttimes.dbload(dbName);


% ADD STATION NUMBERS
site.stationNum = 1:numel(site.sta);
for n = 1:numel(site.stationNum)
    f = find(strcmp(site.sta(n),arrival.sta));
   arrival.stationNum(f) = site.stationNum(n); 
end
arrival.stationNum =  arrival.stationNum';
 

% ARRIVAL HISTOGRAMS
figure('Position',[0 0 1100 850],'Color','w');
set(gcf,'DefaultAxesFontSize',14);
set(gcf,'DefaultAxesLineWidth',0.25);
%
f = find(strcmp(arrival.iphase,'P'));
nP = hist(arrival.stationNum(f),site.stationNum);
f = find(strcmp(arrival.iphase,'S'));
nS = hist(arrival.stationNum(f),site.stationNum);
h = bar(site.stationNum,[nP' nS'],1.8)
set(h(1),'FaceColor','r');
set(h(2),'FaceColor',[0.7 0.7 0.7]);
legend('P wave arrivals','S wave arrivals')
%xlabel('Station name');
ylabel('No. of phase arrivals');

% place rotated x-axis labels
set(gca,'XTick',1:12,'XTickLabel','') 
xAxisHandle = get(gca,'XLabel'); 
set(xAxisHandle,'Units','data'); 
pos = get(xAxisHandle,'Position'); 
y = pos(2); 
for n = 1:size(site.sta,1) 
t(n) = text(site.stationNum(n),y,site.sta(n,:)); 
end 
set(t,'Rotation',90,'HorizontalAlignment','right') 

set(gcf, 'paperorientation', 'landscape');
set(gcf, 'paperposition', [.5 .5 10 6.5] );
print(gcf, '-dpsc2', 'FIG_arrival_histogram.ps');




