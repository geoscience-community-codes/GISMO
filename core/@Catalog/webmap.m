function webmap(catalogObject)
    %CATALOG.WEBMAP Plot hypocenters in map view using webmap         

        % Borrow heavily from Loren Shure/Mathworks 'plotEarthquake' example

    if all(isnan(catalogObject.lat))
        warning('No hypocenter data to plot');
        return
    end

    minmag = nanmin(catalogObject.mag);
    maxmag = nanmax(catalogObject.mag);
    if isnan(minmag)
        minmag=0;
    end
    if isnan(maxmag)
        maxmag=0;
    end
    mag = catalogObject.mag;
    mag(isnan(mag))=0;
    % scale icon color by magnitude
    cm = parula(10);
    iconColor = cm(ceil(1+9*(mag-minmag)/(maxmag-minmag)),:);
    % Convert quakeTable to geopint vector to add as info for each quake
    p = geopoint(catalogObject.lat, catalogObject.lon);
    %h1=webmap('Ocean Basemap')
    h1 = webmap();
    for count=1:length(catalogObject.lat)
        desc{count} = sprintf('Longitude: %f<br/>Latitude: %f<br/>Depth (km): %f<br/>Magnitude: %.1f', ...
            catalogObject.lon(count),...
            catalogObject.lat(count),...
            catalogObject.depth(count),...
            catalogObject.mag(count)  );

    end

    iconDir = fullfile(matlabroot,'toolbox','matlab','icons');
    iconFilename = fullfile(iconDir, 'greencircleicon.gif');
    wmmarker(p,'OverlayName','Event',...
    'Color',iconColor,'AutoFit',false,'Icon', iconFilename,'Description',desc);
    % 'FeatureName',names,'Color',iconColor,'AutoFit',false)
%             wmzoom(1)


    %% Load in plate boundaries
    % The data reference for plate
    % boundaries is
    % http://geoscience.wisc.edu/~chuck/MORVEL/PltBoundaries.html
    % Citation: Argus, D. F., Gordon, R. G., and DeMets, C., 2011.
    % Geologically current motion of 56 plates relative to the
    % no-net-rotation reference frame,
    % Geochemistry, Geophysics, Geosystems, accepted for publication,
    % September, 2011.
    %[lat, lon] = plotEarthquakes.importPlates('All_boundaries.txt');
    load Catalog/plotEarthquakes/plates.mat

    %% Make array of geopoints from the plate boundaries
    bounds = geopoint(lat,lon);

    %% Draw plate boundaries on map
    % Center the map on the longitude of largest quake first.
    wmcenter(h1,nanmean(catalogObject.lat),nanmean(catalogObject.lon));
    try
    wmline(bounds,'FeatureName','Plate Boundaries','Color','m','AutoFit',false);
    end
    %wmzoom(1)
    snapnow


end