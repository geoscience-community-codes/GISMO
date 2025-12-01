function run_all_cookbooks()
clc;
disp('=== RUNNING ALL GISMO COOKBOOKS (SMOKE TEST) ===');

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
% Cookbook list
% ------------------------------------------------------------
cookbooks = {
    'core/@Catalog/cookbook'
    'core/@EventRate/cookbook'
    'core/@Response/cookbook'
    'core/@threecomp/cookbook'
    'core/@correlation/cookbook'
    'core/@waveform/cookbook'
    'core/@drumplot/cookbook'
};

% ------------------------------------------------------------
% Run cookbooks
% ------------------------------------------------------------
for k = 1:numel(cookbooks)
    cb = cookbooks{k};
    fprintf('\n--- Running %s ---\n', cb);

    try
        feval(cb);
        fprintf('SUCCESS: %s\n', cb);
    catch ME
        warning('FAILED: %s\n%s', cb, ME.message);
    end
end

disp('=== COOKBOOK RUN COMPLETE ===');
end
