function spatial_density(cobj)
%SWARMINESS Determine the running swarminess metric for a Catalog object
%   [swarminess, magstd] = swarminess(cobj, N) where N is number of closest 
%       events in time to include in the calculation. 
% e.g.
%   [swarminess, magstd] = swarminess(redoubt_events, 100)

%     nEvents = cobj.numberOfEvents;
%     secs = cobj.otime * 86400;
    maxlat = ceil(max(cobj.lat)*10)/10;
    minlat = floor(min(cobj.lat)*10)/10;
    maxlon = ceil(max(cobj.lon)*10)/10;
    minlon = floor(min(cobj.lon)*10)/10;  
    latrange = minlat: 0.005: maxlat;
    lonrange = minlon: 0.005: maxlon;
    n = hist3([cobj.lon cobj.lat], {lonrange latrange});
    figure
    pcolor(n)
    xlabel('Longitude')
    ylabel('latitude')
    size(lonrange)
    size(latrange)
    size(n)
    set(gca, 'XTick', lonrange, 'XTickLabel', lonrange)
    set(gca, 'YTick', latrange)
    figure
    surf(lonrange, latrange, n')
    figure
    clusteriness = interp2(lonrange,latrange,n',cobj.lon,cobj.lat);
    plot3(cobj.lon, cobj.lat, clusteriness, '*')
    figure
    plot(cobj.otime, clusteriness, 'x')
    
    figure
    [v_swarminess, magstd] = swarminess(cobj, 100);
    figure
    scariness = clusteriness'.*v_swarminess;
    plot(cobj.otime, cumsum(scariness)/sum(scariness), 'b')
    hold on
    plot(cobj.otime, cumsum(v_swarminess)/sum(v_swarminess), 'r')
    plot(cobj.otime, cumsum(clusteriness)/sum(clusteriness), 'g')
    a = ones(size(cobj.otime));
    plot(cobj.otime, cumsum(a)/sum(a), 'c')
    eng=magnitude.mag2eng(cobj.mag);
    plot(cobj.otime, cumsum(eng)/sum(eng), 'k')
    plot(cobj.otime, cumsum(eng).*v_swarminess/sum(eng.*v_swarminess) , 'm')
    datetick('x')
    legend({'scariness'; 'swarminess'; 'clusteriness'; 'cum_events'; 'energy'; 'craziness'})

    
    figure
    plot(cobj.otime, smooth(scariness/max(scariness)), 'b')
    hold on
    plot(cobj.otime, smooth(v_swarminess/max(v_swarminess)), 'r')
    plot(cobj.otime, smooth(clusteriness/max(clusteriness)), 'g')
%     a = ones(size(cobj.otime));
%     [b,t] = hist(a,100);
%     plot(t, b/max(b), 'c')
    eng=magnitude.mag2eng(cobj.mag);
    plot(cobj.otime, smooth(eng/max(eng)), 'k')
    craziness = eng.*v_swarminess;
    plot(cobj.otime, smooth(craziness/max(craziness)), 'm')
    datetick('x')    
    legend({'scariness'; 'swarminess'; 'clusteriness'; 'energy'; 'craziness'})
    
    figure
    plot(cobj.otime, craziness, 'm')
    
    
    % bin the data
    snum=floor(min(cobj.otime));
    enum=ceil(max(cobj.otime))
    binsize = 1/24; stepsize = 1/1440;
    [time, counts, energy, smallest_energy, ...
        biggest_energy, median_energy, stdev, median_time_interval] = ...
        Catalog.binning.bin_irregular(cobj.otime, ...
        magnitude.mag2eng(cobj.mag), ...
        binsize, snum, enum, stepsize);
 
        [time, counts, cumswarminess, smallest_swarminess, ...
        biggest_swarminess, median_swarminess, stdev_swarminess, median_time_interval] = ...
        Catalog.binning.bin_irregular(cobj.otime, ...
        v_swarminess, ...
        binsize, snum, enum, stepsize);
    
     %%
    figure
    subplot(3,2,1), plot(time, cumswarminess)
    datetick('x');ylabel('swarminess')
    
        [time, counts, cumclusteriness, smallest_clusteriness, ...
        biggest_clusteriness, median_clusteriness, stdev_clusteriness, median_time_interval] = ...
        Catalog.binning.bin_irregular(cobj.otime, ...
        clusteriness, ...
        binsize, snum, enum, stepsize);
     subplot(3,2,2), plot(time, cumclusteriness)
     datetick('x');ylabel('clusteriness')
     
             [time, counts, cumscariness, smallest_scariness, ...
        biggest_scariness, median_scariness, stdev_scariness, median_time_interval] = ...
        Catalog.binning.bin_irregular(cobj.otime, ...
        scariness, ...
        binsize, snum, enum, stepsize);
     subplot(3,2,3), plot(time, cumscariness)
     datetick('x');ylabel('clusteriness * swarminess')
 
                  [time, counts, cumcraziness, smallest_craziness, ...
        biggest_craziness, median_craziness, stdev_craziness, median_time_interval] = ...
        Catalog.binning.bin_irregular(cobj.otime, ...
        craziness', ...
        binsize, snum, enum, stepsize);
     subplot(3,2,4), plot(time, cumcraziness)
     datetick('x');ylabel('craziness = energy * swarminess')
     
                       [time, counts, cumeng, smallest_eng, ...
        biggest_eng, median_eng, stdev_eng, median_time_interval] = ...
        Catalog.binning.bin_irregular(cobj.otime, ...
        eng', ...
        binsize, snum, enum, stepsize);
     subplot(3,2,5), plot(time, cumeng)
     datetick('x');ylabel('energy')
     
     subplot(3,2,6), plot(time, counts)
     datetick('x');ylabel('counts')
     
end