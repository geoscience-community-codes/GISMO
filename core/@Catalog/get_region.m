function region = get_region(catalogObject, nsigma)
% region Compute the region to plot based on spread of lon,lat data
    medianlat = nanmedian(catalogObject.lat);
    medianlon = nanmedian(catalogObject.lon);
    cosine = cos(medianlat);
    stdevlat = nanstd(catalogObject.lat);
    stdevlon = nanstd(catalogObject.lon);
    rangeindeg = max([stdevlat stdevlon*cosine]) * nsigma;
    region = [(medianlon - rangeindeg/2) (medianlon + rangeindeg/2) (medianlat - rangeindeg/2) (medianlat + rangeindeg/2)];
end