function run_all_training()
clc;
disp('=== GISMO TRAINING SEQUENCE ===');

% ------------------------------------------------------------
% Ensure testdata are installed
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
% Training scripts list
% ------------------------------------------------------------
trainings = {
    'training/gismo_training_01_waveforms'
    'training/gismo_training_02_event_detection'
    'training/gismo_training_03_rsam'
    'training/gismo_training_04_catalogs'
    'training/gismo_training_05_response'
    'training/gismo_training_06_mastercorr'
    'training/gismo_training_07_waveform_clustering'
};

% ------------------------------------------------------------
% Run training scripts
% ------------------------------------------------------------
for k = 1:numel(trainings)
    T = trainings{k};
    fprintf('\n=== RUNNING %s ===\n', T);

    try
        feval(T);
        fprintf('SUCCESS: %s\n', T);
    catch ME
        warning('TRAINING FAILED: %s\n%s', T, ME.message);
    end
end

disp('=== ALL TRAINING COMPLETE ===');
end
