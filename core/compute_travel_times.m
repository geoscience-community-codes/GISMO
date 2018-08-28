function sites = compute_travel_times(source, sites, seismicspeed, infrasoundspeed)
for c=1:numel(sites)
    thissite = sites(c);


    sites(c).distance = distance(source.lat, source.lon, thissite.lat, thissite.lon) * 111000;  %m
    thischan = get(thissite.channeltag, 'channel');
    if thischan(2)=='D' % infrasound
        sites(c).traveltime = sites(c).distance / infrasoundspeed;
    elseif thischan(2)=='H' % seismic
        sites(c).traveltime = sites(c).distance / seismicspeed;
    else
        sites(c).traveltime = 0;
    end
   
end