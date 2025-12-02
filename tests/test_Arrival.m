classdef test_Arrival < matlab.unittest.TestCase
    %TEST_ARRIVAL
    % CI-safe unit tests for the Arrival class.
    %
    % These tests:
    %   • use synthetic waveform data only
    %   • do NOT require TESTDATA
    %   • do NOT require Antelope / IRIS / Winston
    %   • verify constructor, subsetting, addwaveforms, and association
    %
    % Run with:
    %   runtests('test_Arrival')

    properties
        sta
        chan
        time
        iphase
        fs
        w
    end

    %% --------------------------------------------------------------------
    methods (TestMethodSetup)
        function makeSyntheticInputs(testCase)

            % ---- Arrival metadata ----
            testCase.sta    = {'AAA','BBB','CCC'};
            testCase.chan   = {'HHZ','HHZ','HHZ'};
            testCase.time   = fix(now) + [10 20 30]/86400;
            testCase.iphase = {'P','P','P'};

            % ---- Synthetic waveform ----
            testCase.fs = 100;
            T = 120;                        % 2 minutes
            t = (0:1/testCase.fs:T-1/testCase.fs)';

            x = 0.05 * randn(size(t));
            x = x + sin(2*pi*2*t);
            x(500:560) = x(500:560) + 5*gausswin(61);

            ctag = ChannelTag('XX.AAA..HHZ');
            testCase.w = waveform(ctag, testCase.fs, ...
                                   fix(now), x, 'Counts');
        end
    end

    %% --------------------------------------------------------------------
    methods (Test)

        function testDefaultConstructor(testCase)
            A = Arrival();
            testCase.verifyTrue(isempty(A.time));
            testCase.verifyEqual(A.waveforms, {});
        end

        function testConstructorValid(testCase)
            A = Arrival(testCase.sta, ...
                        testCase.chan, ...
                        testCase.time, ...
                        testCase.iphase);

            testCase.verifyEqual(numel(A.time), 3);
            testCase.verifyEqual(A.iphase(:), testCase.iphase(:));
            testCase.verifyEqual(A.channelinfo(1), "AAA..HHZ");
        end

        function testConstructorScalarExpansion(testCase)
            A = Arrival(testCase.sta, ...
                        testCase.chan, ...
                        testCase.time, ...
                        testCase.iphase, ...
                        'amp', 5, ...
                        'per', 2, ...
                        'signal2noise', 10);

            testCase.verifyEqual(A.amp,          5 * ones(3,1));
            testCase.verifyEqual(A.per,          2 * ones(3,1));
            testCase.verifyEqual(A.signal2noise, 10 * ones(3,1));
        end

        function testConstructorLengthMismatch(testCase)
            badsta = {'AAA','BBB'};
            testCase.verifyError( ...
                @() Arrival(badsta, ...
                            testCase.chan, ...
                            testCase.time, ...
                            testCase.iphase), ...
                'Arrival:Constructor:LengthMismatch');
        end

        function testSubsetByValue(testCase)
            iphase = {'P','S','P'};

            A = Arrival(testCase.sta, ...
                        testCase.chan, ...
                        testCase.time, ...
                        iphase);

            Ap = A.subset('iphase','P');

            testCase.verifyEqual(numel(Ap.time), 2);
            testCase.verifyTrue(all(strcmp(Ap.iphase,'P')));
        end

        function testSubsetByIndex(testCase)
            A = Arrival(testCase.sta, ...
                        testCase.chan, ...
                        testCase.time, ...
                        testCase.iphase);

            A2 = A.subset([1 3]);

            testCase.verifyEqual(numel(A2.time), 2);
            testCase.verifyEqual(A2.time, A.time([1 3]));
        end

        function testAddWaveformsWithWaveformInput(testCase)
            A = Arrival({'AAA'}, ...
                        {'HHZ'}, ...
                        fix(now)+20/86400, ...
                        {'P'});

            pre  = 1;
            post = 1;

            A = A.addwaveforms(testCase.w, pre, post);

            testCase.verifyTrue(iscell(A.waveforms));
            testCase.verifyEqual(numel(A.waveforms), 1);
            testCase.verifyClass(A.waveforms{1}, 'waveform');
        end

        function testAssociateIntoCatalog(testCase)
            % Two stations with nearly coincident arrivals
            sta    = {'AAA','BBB'};
            chan   = {'HHZ','HHZ'};
            time   = fix(now) + [10 10.05]/86400;
            iphase = {'P','P'};

            A = Arrival(sta, chan, time, iphase);

            maxTimeDiff = 0.1; % seconds

            [C, Aout] = A.associate(maxTimeDiff);

            testCase.verifyClass(C,'Catalog');
            testCase.verifyTrue(numel(C.otime) >= 1);
            testCase.verifyClass(Aout,'Arrival');
        end

        function testEmptySubsetReturnsEmptyArrival(testCase)
            A = Arrival(testCase.sta, ...
                        testCase.chan, ...
                        testCase.time, ...
                        testCase.iphase);

            A2 = A.subset('iphase','X');   % no match

            testCase.verifyTrue(isempty(A2.time));
        end

    end
end
