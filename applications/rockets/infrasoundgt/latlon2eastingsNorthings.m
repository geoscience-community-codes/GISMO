function [easting,northing]=latlon2eastingsNorthings(sourcelat, sourcelon, lat, lon)
% Convert lat,lon to eastings,northings with sourcelat, sourcelon as origin
% inputs are in degrees, output is in metres relative to origin
% [easting,northing]=latlon2eastingsNorthings(sourcelat, sourcelon, lat, lon)
deg2m = deg2km(1) * 1000;   
for c=1:length(lat)
    e = distance(lat(c), lon(c), lat(c), sourcelon) * deg2m;
    easting(c) = e * sign(lon(c)-sourcelon);
    n = distance(lat(c), lon(c), sourcelat, lon(c)) * deg2m;
    northing(c) = n * sign(lat(c)-sourcelat);
end