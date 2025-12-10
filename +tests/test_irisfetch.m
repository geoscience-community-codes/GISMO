function tests = test_irisfetch()
% TEST_IRISFETCH
% TRUE INTEGRATION test for GISMO IRIS/FDSN waveform retrieval.
%
% This test is:
%   • EXPECTED TO RUN on MATLAB R2022b and earlier
%   • EXPECTED TO HAVE working internet
%   • EXPECTED TO HAVE irisFetch + Java IRIS-WS installed
%
% This test is automatically SKIPPED only if:
%   • MATLAB version >= R2023a
%
% It FAILS for:
%   • Missing Java libraries
%   • Missing internet
%   • Broken IRIS services
%   • Regressions in GISMO waveform retrieval
%
% Glenn Thompson + ChatGPT (2025)

tests = functiontests(localfunctions);
end


%% ------------------------------------------------------------------------
function testIrisFetchWaveform(testCase)

%% ------------------------------------------------------------
% STRICT MATLAB VERSION GATE
%% ------------------------------------------------------------
v = ver('MATLAB');
rel = regexp(v.Release,'\d{4}[ab]','match','once');

if isempty(rel)
    testCase.assumeFail('Unable to parse MATLAB release.');
end

yr = str2double(rel(1:4));

testCase.assumeTrue(yr <= 2022, ...
    'irisFetch is incompatible with MATLAB R2023a+ — skipping test.');


%% ------------------------------------------------------------
% JVM MUST EXIST (FAIL IF NOT)
%% ------------------------------------------------------------
testCase.assertTrue(usejava('jvm'), ...
    'JVM not available — irisFetch cannot run.');


%% ------------------------------------------------------------
% IRIS JAVA CLASS MUST EXIST (FAIL IF NOT)
%% ------------------------------------------------------------
testCase.assertEqual( ...
    exist('edu.iris.dmc.extensions.fetch.TraceData','class'), 8, ...
    'IRIS Java fetch library not found on classpath.');


%% ------------------------------------------------------------
% TEST PARAMETERS (Redoubt 2009)
%% ------------------------------------------------------------
params.net  = 'AV';
params.sta  = 'REF';
params.loc  = '--';
params.chan = 'EHZ';
params.t1   = '2009-03-22 06:30:00';
params.t2   = '2009-03-22 08:30:00';


%% ------------------------------------------------------------
% ATTEMPT REAL IRIS FETCH (FAIL HARD ON ERROR)
%% ------------------------------------------------------------
ds = datasource('irisdmcws');
CT = ChannelTag(params.net, params.sta, params.loc, params.chan);

try
    w = waveform(ds, CT, params.t1, params.t2);
catch ME
    testCase.verifyFail(sprintf( ...
        'irisFetch waveform retrieval failed:\n%s', ME.message));
end


%% ------------------------------------------------------------
% ASSERTIONS
%% ------------------------------------------------------------
testCase.verifyClass(w, 'waveform');
testCase.verifyGreaterThan(numel(w), 0, ...
    'No waveforms returned from IRIS.');

freqs = get(w,'freq');
testCase.verifyTrue(all(freqs > 0), ...
    'Invalid (non-positive) sampling frequencies returned.');

dataOK = false(size(w));
for i = 1:numel(w)
    d = get(w(i),'data');
    dataOK(i) = ~isempty(d);
end

testCase.verifyTrue(all(dataOK), ...
    'Some traces contain no data.');

end


%% ------------------------------------------------------------------------
function setup(testCase)
close all;
end

function teardown(testCase)
close all;
end
