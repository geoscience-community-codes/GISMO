classdef test_Detection < matlab.unittest.TestCase
    %TEST_DETECTION  Unit tests for the Detection class
    %
    % This test suite exercises:
    %   • Construction from ChannelTag and {sta,chan}
    %   • subset()
    %   • append()
    %   • Detection.sta_lta()
    %   • Detection.associate()
    %
    % All tests are CI-safe (no plotting, no Antelope / IRIS required).
    %
    % Glenn’s refactor test scaffold, 2025
    
    properties
        Fs = 50;              % sampling frequency (Hz) for synthetic waveforms
        startTime             % base datenum for synthetic objects
    end
    
    methods (TestMethodSetup)
        function setUp(testCase)
            testCase.startTime = datenum(2020,1,1,0,0,0);
        end
    end
    
    %% --------------------------------------------------------------------
    methods (Test)
        
        function testConstructorFromStaChan(testCase)
            % Test constructor using {sta,chan} cell arrays
            
            t0 = testCase.startTime;
            times = t0 + ([0 10 20]/86400);
            sta  = {'STA1','STA2','STA1'}';
            chan = {'BHZ','BHZ','EHZ'}';
            state = {'D','D','D'}';
            filt  = {'','', ''}';
            snr   = [3 4 5];
            
            det = Detection(sta, chan, times, state, filt, snr);
            
            testCase.verifyClass(det,'Detection');
            testCase.verifyEqual(det.numel, numel(times));
            testCase.verifyEqual(numel(det.channelinfo), numel(times));
            testCase.verifyEqual(det.time(:), times(:));
            testCase.verifyEqual(det.state(:), state(:));
            testCase.verifyEqual(det.signal2noise(:)', snr(:)');
        end
        
        function testConstructorFromChannelTag(testCase)
            % Test constructor using ChannelTag array
            
            t0 = testCase.startTime;
            times = t0 + ([5 15]/86400);
            
            c1 = ChannelTag('XX.STA1..BHZ');
            c2 = ChannelTag('XX.STA2..BHZ');
            ctags = [c1; c2];
            
            state = {'D','D'}';
            filt  = {'',''}';
            snr   = [2.5 3.1];
            
            % In ChannelTag mode, Detection is called as:
            % Detection(ctags, times, state, filt, snr)
            det = Detection(ctags, times, state, filt, snr);
            
            testCase.verifyClass(det,'Detection');
            testCase.verifyEqual(det.numel, 2);
            testCase.verifyEqual(det.time(:), times(:));
            testCase.verifyEqual(det.state(:), state(:));
            testCase.verifyEqual(det.signal2noise(:)', snr(:)');
        end
        
        function testSubsetByIndexAndField(testCase)
            % Test subset() using index vector and field/value
            
            t0 = testCase.startTime;
            times = t0 + ([0 10 20 30]/86400);
            sta   = {'STA1','STA2','STA1','STA2'}';
            chan  = {'BHZ','BHZ','EHZ','EHZ'}';
            state = {'D','ON','OFF','D'}';
            filt  = {'','','',''}';
            snr   = [1 2 3 4];
            
            det = Detection(sta, chan, times, state, filt, snr);
            
            % By index
            idx = [1 3];
            det2 = det.subset(idx);
            testCase.verifyEqual(det2.time, times(idx));
            testCase.verifyEqual(det2.state(:), state(idx));
            
            % By field/value (state == 'D')
            detD = det.subset('state','D');
            expectedIdx = find(strcmp(state,'D'));
            testCase.verifyEqual(detD.time, times(expectedIdx));
        end
        
        function testAppendSortsByTime(testCase)
            % Test append() concatenates and sorts by time
            
            t0 = testCase.startTime;
            timesA = t0 + ([0 10]/86400);
            timesB = t0 + ([5 20]/86400);
            
            staA = {'STA1','STA1'}';
            chanA = {'BHZ','BHZ'}';
            staB = {'STA2','STA2'}';
            chanB = {'BHZ','BHZ'}';
            
            stateA = {'D','D'}';
            stateB = {'D','D'}';
            filtA  = {'',''}';
            filtB  = {'',''}';
            snrA   = [1 2];
            snrB   = [3 4];
            
            detA = Detection(staA, chanA, timesA, stateA, filtA, snrA);
            detB = Detection(staB, chanB, timesB, stateB, filtB, snrB);
            
            det = detA.append(detB);
            
            [timesAll, sortIdx] = sort([timesA timesB]);
            
            testCase.verifyEqual(det.numel, 4);
            testCase.verifyEqual(det.time, timesAll);
            
            % Ensure corresponding SNR values are sorted with time
            expectedSnr = [snrA snrB];
            expectedSnr = expectedSnr(sortIdx);
            testCase.verifyEqual(det.signal2noise(:)', expectedSnr(:)');
        end
        
        function testStaLtaDetectsSyntheticBurst(testCase)
            % Test Detection.sta_lta on a simple synthetic waveform
            
            w = buildSyntheticWaveform(testCase, true); % with event
            
            [det, sta, lta, ratio] = Detection.sta_lta(w);
            
            testCase.verifyClass(det,'Detection');
            testCase.verifyGreaterThanOrEqual(det.numel, 2); % ON/OFF at least
            
            % Should be even number of detections (ON/OFF pairs)
            testCase.verifyEqual(mod(det.numel,2), 0);
            
            % States should alternate ON/OFF
            states = det.state(:);
            testCase.verifyTrue(all(ismember(states, {'ON','OFF'})));
            testCase.verifyEqual(states(1:2:end), repmat({'ON'},det.numel/2,1));
            testCase.verifyEqual(states(2:2:end), repmat({'OFF'},det.numel/2,1));
            
            % STA/LTA arrays should be same length as waveform data
            testCase.verifyEqual(numel(sta), numel(get(w,'data')));
            testCase.verifyEqual(numel(lta), numel(get(w,'data')));
            testCase.verifyEqual(numel(ratio), numel(get(w,'data')));
        end
        
        function testStaLtaWaveformArray(testCase)
            % Test Detection.sta_lta with waveform arrays (concatenation)
            
            w1 = buildSyntheticWaveform(testCase, true);   % with burst
            w2 = buildSyntheticWaveform(testCase, false);  % pure noise
            
            det = Detection.sta_lta([w1 w2]);
            
            testCase.verifyClass(det,'Detection');
            % At least the burst from w1 should trigger some detections
            testCase.verifyGreaterThan(det.numel, 0);
        end
        
        function testAssociateSimpleTwoStationCase(testCase)
            % Test Detection.associate on simple 2-station synthetic detections
            
            t0 = testCase.startTime;
            
            % Two events, each seen on two stations
            tEvt1 = t0 + [10 11]/86400;
            tEvt2 = t0 + [100 101]/86400;
            times = [tEvt1 tEvt2];
            
            c1 = ChannelTag('XX.STA1..BHZ');
            c2 = ChannelTag('XX.STA2..BHZ');
            ctags = [c1; c2; c1; c2];
            
            states = repmat({'D'},4,1);
            filt   = repmat({''},4,1);
            snr    = [3 4 5 6];
            
            % ChannelTag-mode constructor: Detection(ctags, times, state, filt, snr)
            det = Detection(ctags, times, states, filt, snr);
            
            % 20 seconds maxTimeDiff -> each pair forms an event
            cat = det.associate(20);
            
            testCase.verifyClass(cat,'Catalog');
            testCase.verifyEqual(numel(cat.otime), 2);
            
            % First event should be around tEvt1(1), second near tEvt2(1)
            testCase.verifyLessThan(abs(cat.otime(1) - tEvt1(1)), 5/86400);
            testCase.verifyLessThan(abs(cat.otime(2) - tEvt2(1)), 5/86400);
            
            % Arrivals should be present and have 2 arrivals per event
            testCase.verifyTrue(isfield(cat,'arrivals'));
            testCase.verifyEqual(numel(cat.arrivals), 2);
            testCase.verifyEqual(cat.arrivals{1}.numel, 2);
            testCase.verifyEqual(cat.arrivals{2}.numel, 2);
        end
        
        function testAssociateHonoursMinStations(testCase)
            % Test that MinStations option suppresses events with too few detections
            
            t0 = testCase.startTime;
            
            tEvt1 = t0 + [10 11]/86400;
            times = tEvt1;  % only 2 detections total
            
            c1 = ChannelTag('XX.STA1..BHZ');
            c2 = ChannelTag('XX.STA2..BHZ');
            ctags = [c1; c2];
            
            states = repmat({'D'},2,1);
            filt   = repmat({''},2,1);
            snr    = [3 4];
            
            det = Detection(ctags, times, states, filt, snr);
            
            % Require at least 3 stations -> should return empty Catalog
            cat = det.associate(20,'MinStations',3);
            
            testCase.verifyClass(cat,'Catalog');
            testCase.verifyEqual(numel(cat.otime), 0);
        end
        
    end
end

%% =======================================================================
% Local helper to build synthetic waveforms
% ========================================================================
function w = buildSyntheticWaveform(testCase, includeBurst)
    % Build a simple waveform with optional transient burst
    
    Fs = testCase.Fs;
    N  = Fs * 60; % 60 seconds
    t  = (0:N-1)/Fs;
    
    % Base noise
    data = 0.1*randn(size(t));
    
    if includeBurst
        % Add a short high-amplitude burst around 20–25 seconds
        burstIdx = t >= 20 & t <= 25;
        data(burstIdx) = data(burstIdx) + 5*sin(2*pi*5*t(burstIdx));
    end
    
    w = waveform();
    w = set(w,'data',data);
    w = set(w,'freq',Fs);
    w = set(w,'start',testCase.startTime);
    w = set(w,'station','TEST');
    w = set(w,'channel','BHZ');
end
