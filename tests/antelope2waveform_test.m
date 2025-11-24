function tests = antelope2waveform_test()
% ANTELOPE2WAVEFORM_TEST
% Unit tests for the antelope2waveform() reader.
%
% This test will gracefully skip if:
%   • Antelope MATLAB toolbox is NOT installed
%   • the bundled demo test database is missing
%
% Glenn + ChatGPT (2025)

tests = functiontests(localfunctions);
end

%% ------------------------------------------------------------------------
%  Test: load waveform(s) from demo Antelope database
% -------------------------------------------------------------------------
function testAntelopeRead(testCase)

% --- Check Antelope availability -----------------------------------------
if ~exist('+antelope', 'dir')
    testCase.verifyFail(['Antelope MATLAB toolbox not found. ' ...
        'Skipping Antelope reader tests.']);
    return;
end

% OR use:
% if exist('dbopen','file') ~= 3  % compiled mex
%     testCase.verifyFail('Antelope dbopen() not found – skipping test.');
% end

% --- Locate test database ------------------------------------------------
gismopath = fileparts(which('startup_GISMO'));
dbpath = fullfile(gismopath, 'tests', 'test_data', 'antelope2waveform_testdb');

testCase.verifyTrue(exist(dbpath,'dir') == 7, ...
    sprintf('Antelope test database not found: %s', dbpath));

% --- Query parameters ----------------------------------------------------
sta  = '.*';          % wildcard everything
chan = 'HHZ.*';
starttime = datenum2epoch(datenum('16-Nov-2011 16:29:00'));
endtime   = datenum2epoch(datenum('16-Nov-2011 16:43:24'));

% --- Perform the read ----------------------------------------------------
w = antelope.antelope2waveform(dbpath, sta, chan, starttime, endtime);

% --- Assertions ----------------------------------------------------------
testCase.verifyClass(w, 'waveform');
testCase.verifyGreaterThan(numel(w), 0, 'No waveforms returned.');

% Check waveform metadata looks sane
testCase.verifyTrue(~any(get(w,'freq') <= 0), ...
    'Waveforms have non-positive sampling frequency.');

testCase.verifyTrue(all(arrayfun(@(x) ~isempty(get(x,'data')), w)), ...
    'Some returned waveforms contain no data.');

end

%% ------------------------------------------------------------------------
% Fixtures
% -------------------------------------------------------------------------
function setup(testCase)
close all;
end

function teardown(testCase)
close all;
end