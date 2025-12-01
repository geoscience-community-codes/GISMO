function run_all_tests()
clc;
disp('=== RUNNING ALL GISMO UNIT TESTS ===');

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
% Run unit tests
% ------------------------------------------------------------
disp('Running unit tests...');
results = runtests('tests');

disp(table(results));
disp('=== UNIT TESTS COMPLETE ===');

% ------------------------------------------------------------
% Enforce pass/fail status
% ------------------------------------------------------------
if any([results.Failed])
    error('Some GISMO unit tests FAILED.');
end

end
