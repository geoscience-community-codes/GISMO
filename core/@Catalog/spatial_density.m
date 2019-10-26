function clusteriness = spatial_density(cobj)
%SPATIAL_DENSITY Determine the running swarminess metric for a Catalog object
%   clusteriness = SPATIAL_DENSITY(cobj, N) where N is number of closest 
%       events in time to include in the calculation. 
% e.g.
%   clusteriness = SPATIAL_DENSITY(redoubt_events, 100)

%     nEvents = cobj.numberOfEvents;
%     secs = cobj.otime * 86400;
    maxlat = ceil(max(cobj.lat)*10)/10;
    minlat = floor(min(cobj.lat)*10)/10;
    maxlon = ceil(max(cobj.lon)*10)/10;
    minlon = floor(min(cobj.lon)*10)/10;  
    latrange = minlat: 0.005: maxlat;
    lonrange = minlon: 0.005: maxlon;
    n = hist3([cobj.lon cobj.lat], {lonrange latrange});
    
%     figure
%     pcolor(n)
%     xlabel('Longitude')
%     ylabel('latitude')
%     size(lonrange)
%     size(latrange)
%     size(n)
%     set(gca, 'XTick', lonrange, 'XTickLabel', lonrange)
%     set(gca, 'YTick', latrange)
    
    figure
    surf(lonrange, latrange, n')
    
    figure
    clusteriness = interp2(lonrange,latrange,n',cobj.lon,cobj.lat);
    plot3(cobj.lon, cobj.lat, clusteriness, '*')
    
    figure
    plot(cobj.otime, clusteriness, 'x')    

     
end