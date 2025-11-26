function dbpath = demodb(name)
% DEMODB  Locate bundled GISMO demo databases for automated testing.
%
%   dbpath = demodb('avo')
%   dbpath = demodb('rt')
%   dbpath = demodb('antelope')
%
% This function is a TEST FIXTURE used by the GISMO automated test suite.
% It does NOT download data and does NOT access the network.
%
% Behavior:
%   • If Antelope is installed and name='antelope', return the Antelope demo DB.
%   • Otherwise return the CSS3.0 demo DB inside GISMODATAPATH/test_data.
%   • If paths cannot be constructed, return [] with a warning

    arguments
        name (1,:) char
    end

    name = lower(strtrim(name));
    dbpath = [];

    % --- Case 1: Antelope demo database requested ---
    if strcmp(name, 'antelope')
        if admin.antelope_exists()
            % Standard Antelope demo path
            demo_path = '/opt/antelope/data/db/demo/demo';
            if isfolder(demo_path)
                dbpath = demo_path;
            else
                warning('DEMODB:MissingAntelopeDemo', ...
                        'Antelope is installed but demo DB not found at %s', demo_path);
            end
        else
            warning('DEMODB:NoAntelope', ...
                    'Antelope not installed; returning empty path.');
        end
        return
    end

    % --- Case 2: CSS3.0 test database under GISMO test data ---
    gismoDataPath = getenv('GISMODATAPATH');

    if isempty(gismoDataPath)
        warning('DEMODB:NoGISMODataPath', ...
                'GISMODATAPATH environment variable not set; returning empty path.');
        return
    end

    % Typical directory structure:
    % $GISMODATAPATH/css3.0/avodb200903
    % $GISMODATAPATH/css3.0/rtdb200903
    cssName = sprintf('%sdb200903', name);
    candidate = fullfile(gismoDataPath, 'css3.0', cssName);

    if isfolder(candidate)
        dbpath = candidate;
    else
        warning('DEMODB:MissingCSSDB', ...
                'CSS3.0 demo DB not found at %s', candidate);
    end
end
