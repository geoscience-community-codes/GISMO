function catalogObject = combine(catalogObject1, catalogObject2)
    %CATALOG.COMBINE combine two Catalog objects
    % catalogObject = COMBINE(catalogObject1, catalogObject2)

    catalogObject = [];

    if nargin<2
        help Catalog.combine
        return
    end

    catalogObject = catalogObject1;

    %catalogObject.table = union(catalogObject1.table(), catalogObject2.table());
    otime = [catalogObject1.otime; catalogObject2.otime];
    lon = [catalogObject1.lon; catalogObject2.lon];    
    lat = [catalogObject1.lat; catalogObject2.lat];
    depth = [catalogObject1.depth; catalogObject2.depth];
    mag = [catalogObject1.mag; catalogObject2.mag];
    magtype = [catalogObject1.magtype; catalogObject2.magtype];    
    etype = [catalogObject1.etype; catalogObject2.etype];
    catalogObject = Catalog(otime, lon, lat, depth, mag, magtype, etype);
    catalogObject.detections = [catalogObject1.detections; catalogObject2.detections]; 
    catalogObject.arrivals = [catalogObject1.arrivals; catalogObject2.arrivals];
    catalogObject.waveforms = [catalogObject1.waveforms; catalogObject2.waveforms];
    
end