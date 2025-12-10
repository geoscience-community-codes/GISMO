function tests = test_antelope2waveform()
% TEST_ANTELOPE2WAVEFORM
% Integration test for the Antelope → waveform reader.
%
% Uses real CSS3.0 Antelope database:
%   testdata/css3.0/dbredoubt200903
%
% Automatically SKIPPED if:
%   • Antelope MATLAB toolbox is not installed
%   • GISMO testdata are not configured
%
% Glenn Thompson + ChatGPT (2025)

tests = functiontests(localfunctions);
end

%% ------------------------------------------------------------------------
function testAntelopeRead(testCase)

% --- Ensure testdata are available --------------------------------------
admin.is_testdata_setup(true);
global TESTDATA

% --- Skip if Antelope not available --------------------------------------
if ~(exist('dbopen','file') == 3)
    testCase.assumeFail('Antelope dbopen() not found — skipping test.');
end

% --- Locate real test database ------------------------------------------
dbpath = fullfile(TESTDATA, 'css3.0', 'dbredoubt200903');

testCase.assumeTrue(isfolder(dbpath), ...
    sprintf('Antelope test database not found: %s', dbpath));

% --- Query parameters ----------------------------------------------------
sta  = '.*';
chan = '.*Z.*';   % be permissive across vertical channels

starttime = datenum2epoch(datenum('20-Mar-2009 00:00:00'));
endtime   = datenum2epoch(datenum('25-Mar-2009 00:00:00'));

% --- Perform the read ----------------------------------------------------
w = antelope.antelope2waveform(dbpath, sta, chan, starttime, endtime);

% --- Assertions ----------------------------------------------------------
testCase.verifyClass(w, 'waveform');
testCase.verifyGreaterThan(numel(w), 0, 'No waveforms returned.');

% Sampling rates must be positive
testCase.verifyTrue(~any(get(w,'freq') <= 0), ...
    'Waveforms have non-positive sampling frequency.');

% All waveforms must contain data
testCase.verifyTrue(all(arrayfun(@(x) ~isempty(get(x,'data')), w)), ...
    'Some returned waveforms contain no data.');

end

%% ------------------------------------------------------------------------
function setup(testCase) %#ok<INUSD>
close all;
end

function teardown(testCase) %#ok<INUSD>
close all;
end
