function self = zmap(fname_or_data)
%readEvents.zmap Translate a ZMAP-format data matrix into a Catalog object
% ZMAP format is 10 columns: longitude, latitude, decimal year, month, day,
% magnitude, depth, hour, minute, second

    if ischar(fname_or_data(1))
        %% read the data
        data = load(fname_or_data)
    else
        data = fname_or_data;
    end
    lon = data(:,1);
    lat = data(:,2);
    yyyy = data(:,3);
    mm = data(:,4);
    dd = data(:,5);
    hh = data(:,8);
    mi = data(:,9);
    if size(data,2) == 10
        ss = data(:,10);
    else
        ss = zeros(size(mi));
    end
    time = datenum( floor(yyyy), mm, dd, hh, mi, ss );
    mag = data(:,6);
    depth = data(:,7);
    self = Catalog(time, lon, lat, depth, mag, {}, {});
end
