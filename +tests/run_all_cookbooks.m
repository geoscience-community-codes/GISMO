function run_all_cookbooks()
clc;
disp('=== RUNNING ALL GISMO COOKBOOKS (SMOKE TEST) ===');

% ------------------------------------------------------------
% Detect environment
% ------------------------------------------------------------
G = admin.gismo_guard();

fprintf('\n');
for k = 1:numel(G.summary)
    fprintf('%s\n', G.summary{k});
end
fprintf('\n');

% ------------------------------------------------------------
% Enforce TESTDATA availability
% ------------------------------------------------------------
disp('Checking GISMO TESTDATA setup...');

if ~G.TESTDATA.configured
    disp('TESTDATA not configured. Attempting automatic download...');
    try
        admin.download_testdata;
    catch ME
        error('Failed to download GISMO test data:\n%s', ME.message);
    end
end

if ~admin.is_testdata_setup(false)
    error('TESTDATA is still not correctly configured after download attempt.');
end

global TESTDATA
fprintf('Using TESTDATA at: %s\n\n', TESTDATA);

% ------------------------------------------------------------
% Cookbook list + required capabilities
% ------------------------------------------------------------
cookbooks = {
    'core/@Catalog/cookbook',      'basic'
    'core/@EventRate/cookbook',    'basic'
    'core/@Response/cookbook',     'signal'
    'core/@threecomp/cookbook',    'signal'
    'core/@correlation/cookbook',  'signal'
    'core/@waveform/cookbook',     'basic'
    'core/@drumplot/cookbook',     'signal'
};

% ------------------------------------------------------------
% Run cookbooks
% ------------------------------------------------------------
for k = 1:size(cookbooks,1)

    cb   = cookbooks{k,1};
    need = lower(cookbooks{k,2});

    fprintf('\n--- %s ---\n', cb);

    % --------------------------------------------------------
    % Capability guard (explicit, cookbook-style)
    % --------------------------------------------------------
    skipReason = '';

    switch need

        case 'basic'
            % always allowed

        case 'signal'
            if ~G.Toolboxes.SignalProcessing
                skipReason = 'Signal Processing Toolbox not available';
            end

        case 'stats'
            if ~G.Toolboxes.Statistics
                skipReason = 'Statistics Toolbox not available';
            end

        case 'mapping'
            if ~G.Toolboxes.Mapping
                skipReason = 'Mapping Toolbox not available';
            end

        case 'iris'
            if G.MATLAB.Year > 2022
                skipReason = 'irisFetch unsupported on MATLAB R2023a+';
            elseif ~G.IRIS.irisFetchAvailable
                skipReason = 'irisFetch.m not found';
            elseif ~G.IRIS.javaAvailable
                skipReason = 'IRIS Java classes unavailable';
            elseif ~G.Internet
                skipReason = 'No internet connection';
            end

        case 'antelope'
            if ~G.Antelope.exists
                skipReason = 'Antelope MATLAB toolbox not installed';
            end

        otherwise
            error('Unknown cookbook capability: %s', need);
    end

    if ~isempty(skipReason)
        fprintf('SKIPPED: %s\n', skipReason);
        continue
    end

    % --------------------------------------------------------
    % Run cookbook
    % --------------------------------------------------------
    try
        feval(cb);
        fprintf('SUCCESS\n');
    catch ME
        fprintf(2,'FAILED\n%s\n', ME.message);
    end
end

disp('=== COOKBOOK RUN COMPLETE ===');
end