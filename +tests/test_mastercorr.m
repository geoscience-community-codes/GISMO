function tests = test_mastercorr
% TEST_MASTERCORR
% CI-safe smoke test for mastercorr.cookbook
%
% This test verifies:
%   • Demo data can be loaded
%   • The full mastercorr workflow executes without errors
%   • A correlation object is actually created
%
% Figures are suppressed but the full pipeline is exercised.

tests = functiontests(localfunctions);
end


%% ------------------------------------------------------------------------
function test_runMastercorrCookbook(testCase)

% --- Locate TESTDATA --------------------------------------------
try 
    admin.is_testdata_setup(false); 
catch 
    testCase.assumeFail('TESTDATA not configured — skipping real data test.'); 
end 
global TESTDATA

testCase.assumeTrue(exist(TESTDATA,'dir') == 7, ...
    'GISMO TESTDATA directory not found — skipping test.');

matfile = fullfile(TESTDATA, 'matfiles', 'mastercorr.mat');
testCase.assumeTrue(exist(matfile,'file') == 2, ...
    'mastercorr.mat not found in TESTDATA — skipping test.');

% --- Suppress figures during CI --------------------------------
set(0,'DefaultFigureVisible','off');
cleanup = onCleanup(@() set(0,'DefaultFigureVisible','on'));

% --- Run cookbook ----------------------------------------------
try
    C = mastercorr.cookbook();   % cookbook SHOULD return a correlation object
catch ME
    testCase.verifyFail(sprintf( ...
        'mastercorr.cookbook crashed:\n%s', ME.message));
end

% --- Verify output ---------------------------------------------
testCase.verifyClass(C, 'correlation', ...
    'mastercorr.cookbook did not return a correlation object.');

testCase.verifyGreaterThan(numel(C), 0, ...
    'Correlation object returned by cookbook is empty.');

end
