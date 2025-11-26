%% Catalog Cookbook
% Demonstrates how GISMO Catalog objects are retrieved, analyzed, plotted,
% and exported from multiple seismic data sources.

%% ------------------------------------------------------------------------
% Locate bundled demo data
%% ------------------------------------------------------------------------
gismopath = fileparts(which('startup_GISMO'));
TESTDATA  = fullfile(gismopath, 'testdata');

if ~exist(TESTDATA, 'dir')
    warning('CatalogCookbook:NoTestData', ...
        'TESTDATA directory not found. Demo-based sections may be skipped.');
end

%% ------------------------------------------------------------------------
% IRIS / EarthScope Event Retrieval (Internet Required)
%% ------------------------------------------------------------------------
try
    greatquakes = Catalog.retrieve('iris', ...
        'minimumMagnitude', 8.0, ...
        'starttime', '2000-01-01', ...
        'endtime',   '2015-01-01');

    disp(greatquakes)

    % Access a property
    greatquakes.mag;

    % List methods
    methods(greatquakes);

    % Save
    save('great_earthquakes.mat', 'greatquakes');

catch ME
    warning('CatalogCookbook:IRISUnavailable', ...
        'IRIS retrieval skipped: %s', ME.message);
    greatquakes = Catalog(); %#ok<NASGU>
end

%% ------------------------------------------------------------------------
% Tohoku Regional Catalog Example (IRIS)
%% ------------------------------------------------------------------------
try
    mainshocktime = datenum('2011/03/11 05:46:24');
    tohoku_events = Catalog.retrieve('iris', ...
        'radialcoordinates', [38.297 142.372 km2deg(200)], ...
        'starttime', mainshocktime - 1, ...
        'endtime',   mainshocktime + 1);

    tohoku_events.summary();
    save('tohoku_events.mat', 'tohoku_events');

catch ME
    warning('CatalogCookbook:TohokuFailed', ...
        'Tohoku IRIS example skipped: %s', ME.message);
    tohoku_events = Catalog(); %#ok<NASGU>
end

%% ------------------------------------------------------------------------
% Antelope CSS3.0 Example (Requires ATM)
%% ------------------------------------------------------------------------
try
    if admin.antelope_exists()
        dbpath = fullfile(TESTDATA, 'css3.0', 'avodb200903');

        avocatalog = Catalog.retrieve('antelope', 'dbpath', dbpath);

        redoubtLon = -152.7431;
        redoubtLat = 60.4853;
        maxR = km2deg(20.0);

        redoubt_events = Catalog.retrieve('antelope', 'dbpath', dbpath, ...
            'radialcoordinates', [redoubtLat redoubtLon maxR]);

        save('redoubt_events.mat', 'redoubt_events');
    else
        warning('CatalogCookbook:AntelopeMissing', ...
            'Antelope toolbox not found — skipping Antelope examples.');
        redoubt_events = Catalog(); %#ok<NASGU>
    end
catch ME
    warning('CatalogCookbook:AntelopeFailed', ...
        'Antelope example failed: %s', ME.message);
    redoubt_events = Catalog(); %#ok<NASGU>
end

%% ------------------------------------------------------------------------
% SEISAN Example (File-based)
%% ------------------------------------------------------------------------
try
    demodir = fullfile(TESTDATA, 'seisan', 'REA', 'MVOE_');

    montserrat_events = Catalog.retrieve('seisan', ...
        'dbpath', demodir, ...
        'startTime', '1996/11/01 11:00:00', ...
        'endTime',   '1996/11/01 15:00:00');

    save('montserrat_events.mat', 'montserrat_events');

catch ME
    warning('CatalogCookbook:SEISANFailed', ...
        'SEISAN example skipped: %s', ME.message);
end

%% ------------------------------------------------------------------------
% Hypocenter Plotting (Mapping Toolbox Optional)
%% ------------------------------------------------------------------------
try
    load tohoku_events.mat
    tohoku_events.plot();
    tohoku_events.plot3();
catch
end

try
    tohoku_events.webmap();
    wmzoom(7)
catch
    warning('CatalogCookbook:WebmapUnavailable', ...
        'webmap skipped (Mapping Toolbox or internet unavailable).');
end

%% ------------------------------------------------------------------------
% Event Rate & Time Series Analysis
%% ------------------------------------------------------------------------
try
    tohoku_events.plot_time();

    eventrateObject = tohoku_events.eventrate('binsize', 1/24);
    eventrateObject.plot();
catch
end

try
    redoubt_events.plot_time();
    erobj_red = redoubt_events.eventrate('binsize', 1/24);
    erobj_red.plot();
catch
end

%% ------------------------------------------------------------------------
% Peak Rate & Maximum Magnitude Analysis
%% ------------------------------------------------------------------------
try
    tohoku_events.plotprmm();
catch
end

try
    redoubt_events.plotprmm();
catch
end

%% ------------------------------------------------------------------------
% b-value & Completeness
%% ------------------------------------------------------------------------
try
    tohoku_events.bvalue(1);
catch
end

try
    redoubt_events.bvalue(1);
catch
end

%% ------------------------------------------------------------------------
% Writing Catalogs to Disk
%% ------------------------------------------------------------------------
try
    delete greatquakes_db*
    greatquakes.write('antelope', 'greatquakes_db', 'css3.0');
    greatquakes2 = Catalog.retrieve('antelope', 'dbpath', 'greatquakes_db');
    disp(greatquakes2)
catch ME
    warning('CatalogCookbook:WriteSkipped', ME.message);
end

%% End of Catalog Cookbook