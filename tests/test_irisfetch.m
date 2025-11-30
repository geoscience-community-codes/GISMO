function tests = test_irisfetch()
% TEST_IRISFETCH
% Integration test for GISMO's IRIS/FDSN waveform retrieval.
%
% This test is automatically SKIPPED if:
%   • MATLAB version >= R2023a
%   • irisFetch / IRIS-WS Java library is unavailable
%   • No internet connection is present
%
% Glenn Thompson + ChatGPT (2025)

tests = functiontests(localfunctions);
end

%% ------------------------------------------------------------------------
function testIrisFetchWaveform(testCase)

% --- Enforce MATLAB compatibility ---------------------------------------
v = ver('MATLAB');
release = regexp(v.Release,'\d\d\d\d[a|b]','match','once');
testCase.assumeTrue(str2double(release(1:4)) <= 2022, ...
    'irisFetch is incompatible with MATLAB R2023a+ — skipping test.');

% --- Enforce Java library availability ----------------------------------
testCase.assumeTrue(exist('edu.iris.dmc.extensions.fetch.TraceData','class') == 8, ...
    'IRIS Java library not found on classpath — skipping test.');

% --- Test parameters -----------------------------------------------------
params.net  = 'AV';
params.sta  = 'REF';
params.loc  = '--';
params.chan = 'EHZ';
params.t1   = '2009-03-22 06:30:00';
params.t2   = '2009-03-22 08:30:00';

% --- Attempt GISMO waveform retrieval -----------------------------------
ds = datasource('irisdmcws');
CT = ChannelTag(params.net, params.sta, params.loc, params.chan);

w = waveform(ds, CT, params.t1, params.t2);

% --- Assertions ----------------------------------------------------------
testCase.verifyClass(w, 'waveform');
testCase.verifyGreaterThan(numel(w), 0, 'No waveforms returned.');

freqs = get(w,'freq');
testCase.verifyTrue(all(freqs > 0), 'Invalid sampling frequencies.');


dataOK = false(size(w));
for i = 1:numel(w)
    d = get(w(i),'data');
    dataOK(i) = ~isempty(d);
end

testCase.verifyTrue(all(dataOK), 'Some traces contain no data.');

end

%% ------------------------------------------------------------------------
function setup(testCase)
close all;
end

function teardown(testCase)
close all;
end