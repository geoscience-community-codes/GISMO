function run_all_tests()
clc;
disp('=== RUNNING ALL GISMO UNIT TESTS ===');

% ------------------------------------------------------------
% Detect environment
% ------------------------------------------------------------
G = gismo_guard();

% Pretty-print environment summary
fprintf('\n');
for k = 1:numel(G.summary)
    fprintf('%s\n', G.summary{k});
end
fprintf('\n');

% ------------------------------------------------------------
% Enforce TESTDATA availability (hard requirement)
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

% Re-check after download attempt
if ~admin.is_testdata_setup(false)
    error('TESTDATA is still not correctly configured after download attempt.');
end

global TESTDATA
fprintf('Using TESTDATA at: %s\n\n', TESTDATA);

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