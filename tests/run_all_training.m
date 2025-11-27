function run_all_training()
clc;
disp('=== GISMO TRAINING SEQUENCE ===');

trainings = {
    'training/gismo_training_01_waveforms'
    'training/gismo_training_02_event_detection'
    'training/gismo_training_03_rsam'
    'training/gismo_training_04_catalogs'
    'training/gismo_training_05_response'
    'training/gismo_training_06_mastercorr'
    'training/gismo_training_07_waveform_clustering'
};

for k = 1:numel(trainings)
    T = trainings{k};
    fprintf('\n=== RUNNING %s ===\n', T);
    try
        feval(T);
    catch ME
        warning('TRAINING FAILED:\n%s', ME.message);
    end
end

disp('=== ALL TRAINING COMPLETE ===');
end