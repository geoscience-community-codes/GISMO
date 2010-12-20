function cookbook_map(TC,W,backAzimuth)

%COOKBOOK_MAP Plots a simple map to accompany cookbook data
% COOKBOOK_MAP(TC,W) plots a simple map of station and origin locations
% for the demo dataset used in the threecomp cookbook. It is intended to be
% used internal to the demo only.
 

% PLOT MAP
figure('Color','w','Position',[50 50 400 400]);
staLat = get(W(:,1),'STATIONLATITUDE');
staLon = get(W(:,1),'STATIONLONGITUDE');
origLat = get(W(:,1),'ORIGINLATITUDE');
origLon = get(W(:,1),'ORIGINLONGITUDE');
staName = get(W(:,1),'STATION');
plot(staLon,staLat,'bo','LineWidth',3,'MarkerSize',7);
hold on; box on; grid on;
plot(origLon,origLat,'ro','LineWidth',3,'MarkerSize',9);
set(gca,'DataAspectRatio',[1 cosd(34) 1]);
if exist('reckon')==2
    for n=1:size(W,1)
        text(staLon(n),staLat(n),['  ' staName{n}],'FontWeight','bold');
        [arrowLat(1) arrowLon(1)] = reckon(staLat(n),staLon(n), -0.3, backAzimuth(n));
        [arrowLat(2) arrowLon(2)] = reckon(staLat(n),staLon(n), 0.3, backAzimuth(n));
        plot(arrowLon,arrowLat,'b-');
    end
else
    disp('** WARNING **');
    disp('Full cookbook example requires the mapping toolbox. It is used to ');
    disp('plot backazimuths. Note thta the mapping toolbox is NOT needed to ');
    disp('use the threecomp object, however.');
end
text(origLon(n),origLat(n),['  origin'],'FontWeight','bold');
xlabel('Longitude');
ylabel('Latitude');
legend('stations','origin','backazimuth','Location','NorthWest');

