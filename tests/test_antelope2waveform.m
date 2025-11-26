function tests = test_antelope2waveform()
% TEST_ANTELOPE2WAVEFORM
% Integration test for the Antelope → waveform reader.
%
% This test is automatically SKIPPED if:
%   • Antelope MATLAB toolbox is not installed
%   • The bundled demo Antelope database is missing
%
% Glenn Thompson + ChatGPT (2025)

tests = functiontests(localfunctions);
end

%% ------------------------------------------------------------------------
function testAntelopeRead(testCase)

% --- Skip if Antelope not available --------------------------------------
if ~(exist('dbopen','file') == 3)
    testCase.assumeFail('Antelope dbopen() not found — skipping test.');
end

% --- Locate test database ------------------------------------------------
gismopath = fileparts(which('startup_GISMO'));
dbpath = fullfile(gismopath, 'tests', 'test_data', 'antelope2waveform_testdb');

testCase.assumeTrue(exist(dbpath,'dir') == 7, ...
    sprintf('Antelope test database not found: %s', dbpath));

% --- Query parameters ----------------------------------------------------
sta  = '.*';
chan = 'HHZ.*';
starttime = datenum2epoch(datenum('16-Nov-2011 16:29:00'));
endtime   = datenum2epoch(datenum('16-Nov-2011 16:43:24'));

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
function setup(testCase)
close all;
end

function teardown(testCase)
close all;
end