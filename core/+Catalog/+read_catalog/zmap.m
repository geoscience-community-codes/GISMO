function self = zmap(zmapdata)
%readEvents.zmap Translate a ZMAP-format data matrix into a Catalog object
% ZMAP format is 10 columns: longitude, latitude, decimal year, month, day,
% magnitude, depth, hour, minute, second
    lon = zmapdata(:,1);
    lat = zmapdata(:,2);
    time = datenum( floor(zmapdata(:,3)), zmapdata(:,4), zmapdata(:,5), ...
        zmapdata(:,8), zmapdata(:,9), zmapdata(:,10) );
    mag = zmapdata(:,6);
    depth = zmapdata(:,7);
    self = Catalog(time, lon, lat, depth, mag, {}, {});
end
