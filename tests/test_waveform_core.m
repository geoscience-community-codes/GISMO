function tests = test_waveform_core()
%TEST_WAVEFORM_CORE
% CI-safe unit tests for core waveform functionality.
%
% These tests:
%   - do NOT require external datasources (IRIS, Winston, Antelope, etc.)
%   - do NOT require TESTDATA env var
%   - only use synthetic data, plus any local test files if present
%
% Run with:
%   runtests('test_waveform_core')
%
% Glenn / Heather refactor 2025-11

tests = functiontests(localfunctions);
end

%% ------------------------------------------------------------------------
function setup(testCase)
close all
testCase.TestData.originalDir = pwd;

% Ensure GISMO is on path (if startup exists)
gismopath = fileparts(which('startup_GISMO'));
if ~isempty(gismopath)
    addpath(genpath(gismopath));
end

% Reproducible synthetic data for most tests
rng(0);
Dt = rand(1,1001) .* 1000 - 500;
testCase.TestData.Dt = Dt(:);  % column
testCase.TestData.ctag = ChannelTag('IU.ANMO.00.BHZ');
testCase.TestData.fs = 20;
testCase.TestData.start = fix(now);
testCase.TestData.units = 'm / sec';
testCase.TestData.wf = waveform(testCase.TestData.ctag, ...
                                testCase.TestData.fs, ...
                                testCase.TestData.start, ...
                                testCase.TestData.Dt, ...
                                testCase.TestData.units);
end

function teardown(testCase)
close all
cd(testCase.TestData.originalDir);
end

%% ------------------------------------------------------------------------
function testConstructors(testCase)
% Default constructor
w0 = waveform;
verifyInstanceOf(testCase, w0, 'waveform');
verifyTrue(testCase, isempty(w0));

% Preferred modern constructor: ChannelTag, fs, start, data, units
fs = testCase.TestData.fs;
st = testCase.TestData.start;
Dt = testCase.TestData.Dt;
ctag = testCase.TestData.ctag;
w1 = waveform(ctag, fs, st, Dt);
verifyInstanceOf(testCase, w1, 'waveform');
verifyEqual(testCase, get(w1,'freq'), fs);
verifyEqual(testCase, get(w1,'start'), st);
verifyEqual(testCase, double(w1), Dt);

% Copy semantics
w2 = w1;
s1 = struct(w1); s2 = struct(w2);
fn = fieldnames(s1);
for k = 1:numel(fn)
    switch class(s1.(fn{k}))
        case {'char','double','logical'}
            verifyEqual(testCase, s1.(fn{k}), s2.(fn{k}));
    end
end
end

%% ------------------------------------------------------------------------
function testSetGetBasics(testCase)
w = testCase.TestData.wf;

% Station/channel/tag retrieval
verifyEqual(testCase, get(w,'channelinfo'), string(testCase.TestData.ctag));

% Data length
n = numel(testCase.TestData.Dt);
verifyEqual(testCase, get(w,'data_length'), n);

% Setting/Getting data
newdata = (1:50)';
w2 = set(w,'data',newdata);
verifyEqual(testCase, double(w2), newdata);

% Units
w3 = set(w,'units','Counts');
verifyEqual(testCase, get(w3,'units'), 'Counts');
end

%% ------------------------------------------------------------------------
function testBasicMathOps(testCase)
w = testCase.TestData.wf;
D = testCase.TestData.Dt;

% Identities
verifyEqual(testCase, w + 0, w);
verifyEqual(testCase, w - 0, w);
verifyEqual(testCase, w .* 1, w);
verifyEqual(testCase, w ./ 1, w);
verifyEqual(testCase, w .^ 1, w);

% Comparisons / algebraic consistency
verifyEqual(testCase, w + w, w * 2);
verifyEqual(testCase, w - w, w .* 0);
verifyEqual(testCase, w ./ 2, w .* 0.5);
verifyEqual(testCase, w .^ 2, w .* w);

% Mixed waveform/scalar order
verifyEqual(testCase, w + 100, 100 + w);
verifyEqual(testCase, w .* 5, 5 .* w);

% Compare to raw data
verifyEqual(testCase, double(w .* D), D .* D);
verifyEqual(testCase, double((7.*w) + (w./5) - w.^3), (D.*7) + (D./5) - D.^3);
end

%% ------------------------------------------------------------------------
function testAdvancedMathOps(testCase)
w = testCase.TestData.wf;
D = testCase.TestData.Dt;

verifyEqual(testCase, double(sign(w)), sign(D));
verifyEqual(testCase, double(abs(w)), abs(D));
verifyEqual(testCase, abs(w), sign(w).*w);
end

%% ------------------------------------------------------------------------
function testDiffAndIntegrate(testCase)
w = testCase.TestData.wf;
D = testCase.TestData.Dt;
fs = testCase.TestData.fs;

% diff scales by Fs internally
dw = diff(w);
dd_expected = diff(D) * fs;
verifyEqual(testCase, double(dw), dd_expected);

expectedUnits = [get(w,'units') ' / sec'];
verifyEqual(testCase, get(dw,'units'), expectedUnits);

% integrate (compare cumsum default)
d = sin(1:0.01:1000) .* 100;
d = d(:);                      % ensure column
d = d + randn(size(d));        % matching shape, no huge expansion
w2 = waveform('NW.STA.LO.CHA', fs, fix(now), d, 'Counts');

verifyEqual(testCase, double(integrate(w2)), cumsum(d)./fs);
verifyEqual(testCase, get(integrate(w2),'units'), 'Counts * sec');

verifyEqual(testCase, double(integrate(w2,'cumsum')), cumsum(d)./fs);
verifyEqual(testCase, double(integrate(w2,'trapz')), cumtrapz(d)./fs);
end


%% ------------------------------------------------------------------------
function testStatisticalMath(testCase)
w = testCase.TestData.wf;
D = testCase.TestData.Dt;

verifyEqual(testCase, min(w), min(D));
verifyEqual(testCase, max(w), max(D));
verifyEqual(testCase, mean(w), mean(D));
verifyEqual(testCase, median(w), median(D));
verifyEqual(testCase, std(w), std(D));
verifyEqual(testCase, var(w), var(D));
end

%% ------------------------------------------------------------------------
function testTransforms(testCase)
w = testCase.TestData.wf;
D = testCase.TestData.Dt;

% rms
verifyEqual(testCase, rms(w), sqrt(sum(D.^2)/(numel(D)-1)));

% detrend / demean
verifyEqual(testCase, double(detrend(w)), detrend(D));
verifyEqual(testCase, double(demean(w)), D - mean(D));

% hilbert (compare magnitudes)
verifyEqual(testCase, double(hilbert(w)), abs(hilbert(D)));

% fix_data_length
w5k = fix_data_length(w, 5001);
verifyEqual(testCase, get(w5k,'data_length'), 5001);

w301 = fix_data_length(w, 301);
verifyEqual(testCase, get(w301,'data_length'), 301);

w2 = set(w,'data',2:100);
twoWs = fix_data_length([w, w2]);
verifyEqual(testCase, get(twoWs,'data_length'), get([w w],'data_length'));
end

%% ------------------------------------------------------------------------
function testUserDefinedFields(testCase)
w = testCase.TestData.wf;

w = addfield(w,'ABCD','hello');
verifyEqual(testCase, get(w,'abcd'), 'hello');

w = set(w,'ABcD',5);
verifyEqual(testCase, get(w,'AbCD'), 5);

w = delfield(w,'abcd');
verifyFalse(testCase, ismember('ABCD', get(w,'misc_fields')));
verifyError(testCase, @() get(w,'ABCD'), 'Waveform:get:unrecognizedProperty');
end

%% ------------------------------------------------------------------------
function testHistory(testCase)
w = testCase.TestData.wf;

w = addhistory(w,'StringTest');
w = addhistory(w,'[%s]<%02d>','ABCDEFG',3);
w = addhistory(w,{3});
fullhist = get(w,'history');

verifyEqual(testCase, size(fullhist,1), 4);
verifyEqual(testCase, size(fullhist,2), 2);
verifyEqual(testCase, fullhist{1,1}, 'created');
verifyEqual(testCase, fullhist{2,1}, 'StringTest');
verifyEqual(testCase, fullhist{3,1}, '[ABCDEFG]<03>');
verifyEqual(testCase, fullhist{4,1}{1}, 3);

[~, dates] = history(w);
verifyEqual(testCase, datenum(datestr([fullhist{:,2}])), datenum(dates));

% clearhistory
Z = get(clearhistory(w),'History');
n = now;
onesecond = datenum(0,0,0,0,0,1);
verifyTrue(testCase, abs(Z{2}-n) < onesecond);
verifyEqual(testCase, size(Z), [1 2]);
verifyTrue(testCase, ischar(Z{1}));
verifyTrue(testCase, isa(Z{2},'double'));
verifyEqual(testCase, Z{1}, 'Cleared History');
end

%% ------------------------------------------------------------------------
function testIsEmptyAndDouble(testCase)
w = waveform;
verifyTrue(testCase, isempty(w));

w = set(w,'data',1);
verifyFalse(testCase, isempty(w));

w = set(w,'data',[]);
verifyTrue(testCase, isempty(w));

A = testCase.TestData.wf;
Ad = testCase.TestData.Dt;
verifyEqual(testCase, double(A), Ad);
verifyEqual(testCase, double([A A]), [Ad Ad]);
end

%% ------------------------------------------------------------------------
function testPlotDoesNotError(testCase)
% Just ensure plotting doesn't throw, and clean up.
A = testCase.TestData.wf;
B = waveform('SY.SIN..BHZ',20,fix(now),sin(1:.001:100),'Counts');

f = figure('Visible','off');
plot(A);
plot([A B]);
plot([A B]','g.');
plot([A B B.*2 B.*7 set(B,'start',get(B,'start')+datenum(0,0,0,0,0,1))], ...
     'xunit','date','markersize',3);
legend([A, B]);
delete(f);
end

%% ------------------------------------------------------------------------
function testSacLoadIfLocalFileExists(testCase)
% Optional local SAC test if file is bundled in repo.
gismopath = fileparts(which('startup_GISMO'));
if isempty(gismopath)
    return
end
sacFile = fullfile(gismopath,'tests','test_data','example_sacfile.sac');

if exist(sacFile,'file') ~= 2
    % Not a failure; just skip.
    return
end

f = figure('Visible','off');

dsac = datasource('sac', sacFile);
chanTag = ChannelTag('...');

sacwave = loadsac(waveform, sacFile);
verifyEqual(testCase, get(sacwave,'data_length'), 500);
verifyEqual(testCase, get(sacwave,'NZYEAR'), 2000);
verifyEqual(testCase, get(sacwave,'start'), datenum('2000-07-14 13:40:00.006'));

sacwave2 = waveform(dsac, chanTag, '7/14/2000', '7/15/2000');
verifyEqual(testCase, get(sacwave2,'data_length'), 500);
verifyEqual(testCase, get(sacwave2,'NZYEAR'), 2000);
verifyEqual(testCase, get(sacwave2,'start'), datenum('2000-07-14 13:40:00.006'));

delete(f);
end