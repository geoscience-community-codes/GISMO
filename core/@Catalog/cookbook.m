function cookbook()
    %% Catalog Cookbook (Modernized for External TESTDATA)
    % Demonstrates how GISMO Catalog objects are retrieved, analyzed,
    % plotted, and exported from multiple seismic data sources.
    %
    % Fully compatible with:
    %   • External TESTDATA
    %   • CI systems
    %   • Optional dependencies (IRIS, Antelope, Mapping Toolbox)

    %% -----------------------------------------------------------------
    % Ensure testdata exist
    %% -----------------------------------------------------------------
    admin.is_testdata_setup(true);
    global TESTDATA

    fprintf('Using TESTDATA at:\n  %s\n', TESTDATA);

    %% -----------------------------------------------------------------
    % Working directory for generated outputs (never repo root)
    %% -----------------------------------------------------------------
    workdir = fullfile(tempdir, 'gismo_catalog_cookbook');
    if ~exist(workdir, 'dir')
        mkdir(workdir);
    end

    %% -----------------------------------------------------------------
    % Load Prepackaged MATLAB Catalogs (Preferred, Fast, Offline)
    %% -----------------------------------------------------------------
    try
        load(fullfile(TESTDATA, 'matfiles', 'Catalog', 'great_earthquakes.mat'));
        load(fullfile(TESTDATA, 'matfiles', 'Catalog', 'tohoku_events.mat'));
        load(fullfile(TESTDATA, 'matfiles', 'Catalog', 'redoubt_events.mat'));

        disp('Loaded prepackaged MATLAB catalog test datasets.');

    catch ME
        warning('CatalogCookbook:MATFilesMissing', ...
            'MAT-file catalogs unavailable: %s', ME.message);

        greatquakes    = Catalog();
        tohoku_events  = Catalog();
        redoubt_events = Catalog();
    end

    %% -----------------------------------------------------------------
    % Antelope CSS3.0 Example (dbredoubt200903)
    %% -----------------------------------------------------------------
    try
        if admin.antelope_exists()
            dbpath = fullfile(TESTDATA, 'css3.0', 'dbredoubt200903');

            testdb_exists = ...
                exist([dbpath '.wfdisc'], 'file') || ...
                exist([dbpath '.origin'], 'file');

            if testdb_exists
                redoubt_css = Catalog.retrieve('antelope', ...
                    'dbpath', dbpath);

                save(fullfile(workdir, 'redoubt_events_css.mat'), 'redoubt_css');
                disp(redoubt_css)
            else
                warning('CatalogCookbook:AntelopeDBMissing', ...
                    'Antelope database not found: %s', dbpath);
            end
        else
            warning('CatalogCookbook:AntelopeMissing', ...
                'Antelope toolbox not found — skipping Antelope section.');
        end
    catch ME
        warning('CatalogCookbook:AntelopeFailed', ME.message);
    end

    %% -----------------------------------------------------------------
    % SEISAN Example (File-based, Montserrat)
    %% -----------------------------------------------------------------
    try
        seisan_dir = fullfile(TESTDATA, 'seisan_data', 'REA', 'MVOE_');

        if exist(seisan_dir, 'dir')
            montserrat_events = Catalog.retrieve('seisan', ...
                'dbpath', seisan_dir, ...
                'startTime', '1996/11/01 11:00:00', ...
                'endTime',   '1996/11/01 15:00:00');

            save(fullfile(workdir, 'montserrat_events.mat'), ...
                'montserrat_events');
        else
            warning('CatalogCookbook:SEISANMissing', ...
                'SEISAN directory not found: %s', seisan_dir);
        end
    catch ME
        warning('CatalogCookbook:SEISANFailed', ME.message);
    end

    %% -----------------------------------------------------------------
    % Hypocenter Plotting (Mapping Toolbox Optional)
    %% -----------------------------------------------------------------
    try
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

    %% -----------------------------------------------------------------
    % Event Rate & Time Series Analysis
    %% -----------------------------------------------------------------
    try
        tohoku_events.plot_time();
        erobj = tohoku_events.eventrate('binsize', 1/24);
        erobj.plot();
    catch
    end

    try
        redoubt_events.plot_time();
        erobj_red = redoubt_events.eventrate('binsize', 1/24);
        erobj_red.plot();
    catch
    end

    %% -----------------------------------------------------------------
    % Peak Rate & Maximum Magnitude Analysis
    %% -----------------------------------------------------------------
    try
        tohoku_events.plotprmm();
    catch
    end

    try
        redoubt_events.plotprmm();
    catch
    end

    %% -----------------------------------------------------------------
    % b-value & Completeness
    %% -----------------------------------------------------------------
    try
        tohoku_events.bvalue(1);
    catch
    end

    try
        redoubt_events.bvalue(1);
    catch
    end

    %% -----------------------------------------------------------------
    % Writing Catalogs to Disk (Antelope Roundtrip Test)
    %% -----------------------------------------------------------------
    try
        if admin.antelope_exists() && ~isempty(greatquakes.otime)
            outdb = fullfile(workdir, 'greatquakes_db');

            delete([outdb '*']);

            greatquakes.write('antelope', outdb, 'css3.0');

            greatquakes2 = Catalog.retrieve('antelope', ...
                'dbpath', outdb);

            disp(greatquakes2)
        end
    catch ME
        warning('CatalogCookbook:WriteSkipped', ME.message);
    end

    fprintf('\nCatalog cookbook completed successfully.\n');
end