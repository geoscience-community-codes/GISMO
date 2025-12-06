function run_all_training()

clc;
disp('=== GISMO TRAINING SEQUENCE ===');

% ------------------------------------------------------------
% Detect environment once
% ------------------------------------------------------------
G = gismo_guard();
disp(G.summary);

% ------------------------------------------------------------
% Ensure TESTDATA is installed (mandatory)
% ------------------------------------------------------------
disp('Checking GISMO test data setup...');

if ~admin.is_testdata_setup(false)
    disp('TESTDATA not configured. Attempting automatic download...');
    try
        admin.download_testdata
    catch ME
        error('Failed to download GISMO test data:\n%s', ME.message);
    end
end

if ~admin.is_testdata_setup(false)
    error('TESTDATA is still not correctly configured after download attempt.');
end

global TESTDATA
disp(['Using TESTDATA at: ', TESTDATA]);

% ------------------------------------------------------------
% Training scripts + required capability
% ------------------------------------------------------------
trainings = {
    'training/gismo_training_01_waveforms',           'basic'
    'training/gismo_training_02_event_detection',     'signal'
    'training/gismo_training_03_rsam',                'signal'
    'training/gismo_training_04_iris_events',         'iris'
    'training/gismo_training_05_volcano_monitoring',  'basic'
    'training/gismo_training_06_mastercorr',          'stats'
    'training/gismo_training_07_waveform_clustering', 'stats'
};

% ------------------------------------------------------------
% Run training scripts
% ------------------------------------------------------------
for k = 1:size(trainings,1)

    script = trainings{k,1};
    need   = lower(trainings{k,2});

    fprintf('\n=== %s ===\n', script);

    % ------------------------------------------------------------
    % Capability guard (training-style)
    % ------------------------------------------------------------
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

        case 'iris'
            if G.MATLAB.Year > 2022
                skipReason = 'irisFetch unsupported on MATLAB R2023a+';
            elseif ~G.IRIS.irisFetchAvailable
                skipReason = 'irisFetch.m not on path';
            elseif ~G.IRIS.javaAvailable
                skipReason = 'IRIS Java classes unavailable';
            elseif ~G.Internet
                skipReason = 'No internet connection';
            end

        otherwise
            error('Unknown training capability: %s', need);
    end

    if ~isempty(skipReason)
        fprintf('SKIPPED: %s\n', skipReason);
        continue
    end

    % ------------------------------------------------------------
    % Execute training script
    % ------------------------------------------------------------
    try
        feval(script);
        fprintf('SUCCESS: %s\n', script);
    catch ME
        fprintf(2,'FAILED: %s\n%s\n', script, ME.message);
    end
end

disp('=== ALL TRAINING COMPLETE ===');

end