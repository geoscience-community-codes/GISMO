%% GISMO Training 03: Importing a Text / CSV Event Catalog
%
% This training script demonstrates how to:
%
%   1. Import an earthquake catalog from a text or CSV file
%   2. Convert it into a GISMO Catalog object
%   3. Plot hypocenters in map and time
%   4. Compute and plot b-values
%   5. Save the Catalog for downstream workflows
%
% This script does NOT require:
%   • Antelope
%   • IRIS web services
%
% Input file is assumed to contain columns:
%   time(or epoch), latitude, longitude, depth, magnitude
%
% Time may be:
%   • MATLAB datenums
%   • UNIX epoch seconds
%   • ISO text timestamps
%
% ------------------------------------------------------------

clc;
close all;
warning off; %#ok<WNOFF>

%% 1. Select Input File --------------------------------------------------

% Option A: environment variable
catalogFile = getenv('GISMO_TRAINING_CATALOG');

% Option B: fallback default (repo-safe)
if isempty(catalogFile)
    catalogFile = fullfile( ...
        fileparts(mfilename('fullpath')), ...
        'example_event_catalog.csv');
end

if ~exist(catalogFile,'file')
    error(['Catalog file not found: ', catalogFile, ...
           '\nSet environment variable GISMO_TRAINING_CATALOG or ', ...
           'place a CSV in the training folder.']);
end

fprintf('Loading catalog file: %s\n', catalogFile);

%% 2. Read the Text / CSV File ------------------------------------------

T = readtable(catalogFile);

requiredVars = {'time','lat','lon','depth','mag'};
for k = 1:numel(requiredVars)
    if ~ismember(requiredVars{k}, lower(T.Properties.VariableNames))
        error(['Missing required column: ', requiredVars{k}]);
    end
end

% Normalize column names
T.Properties.VariableNames = lower(T.Properties.VariableNames);

%% 3. Convert Time Column to MATLAB datenums ----------------------------

if isnumeric(T.time)

    if max(T.time) > 1e9
        % Likely UNIX epoch time
        otime = epoch2datenum(T.time);
        fprintf('Time interpreted as UNIX epoch.\n');
    else
        % Already MATLAB datenums
        otime = T.time;
        fprintf('Time interpreted as MATLAB datenum.\n');
    end

else
    % ISO timestamp strings
    otime = datenum(T.time);
    fprintf('Time interpreted as ISO timestamps.\n');
end

%% 4. Build GISMO Catalog Object ----------------------------------------

cobj = Catalog( ...
    'otime', otime, ...
    'lat',   T.lat, ...
    'lon',   T.lon, ...
    'depth', T.depth, ...
    'mag',   T.mag);

fprintf('Catalog created with %d events\n', cobj.numberOfEvents);

%% 5. Basic Visualization -----------------------------------------------

figure;
cobj.plot_time();
title('Event Times');

figure;
cobj.plot3();
title('3D Hypocenter Distribution');

figure;
cobj.plot();
title('Map View of Hypocenters');

%% 6. Gutenberg–Richter b-Value ------------------------------------------

figure;
bv = cobj.bvalue(1);
title(sprintf('b-value = %.2f', bv));

fprintf('Computed b-value: %.3f\n', bv);

%% 7. Event Rate ---------------------------------------------------------

erobj = cobj.eventrate('binsize',1);

figure;
erobj.plot();
title('Event Rate from Imported Catalog');

%% 8. Save for Downstream Training --------------------------------------

save('training_imported_catalog.mat','cobj');

fprintf('Catalog saved to training_imported_catalog.mat\n');

%% 9. Suggested Student Extensions --------------------------------------
%
%   • Subclassify by magnitude:
%         c2 = cobj.subset('mag', [2 4]);
%
%   • Compare shallow vs deep seismicity
%
%   • Combine with RSAM data
%
%   • Train ML classifiers on catalog-only features
%
%   • Compare b-values through time:
%         cobj.bvalue('sliding',10)
%
% ------------------------------------------------------------

disp('GISMO Training 03 complete.');