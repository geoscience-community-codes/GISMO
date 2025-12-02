classdef test_drumplot < matlab.unittest.TestCase
    %TEST_DRUMPLOT
    % CI-safe unit tests for the drumplot class.
    %
    % These tests:
    %   • use synthetic waveform data only (except optional real-data test)
    %   • do NOT require TESTDATA for core tests
    %   • do NOT require Antelope / IRIS / Winston / SAC
    %   • only verify that construction + plotting do not error
    %
    % Run with:
    %   runtests('test_drumplot')

    properties
        w          % synthetic waveform
        fs
        start
        data
    end

    %% --------------------------------------------------------------------
    methods (TestMethodSetup)
        function makeSyntheticWaveform(testCase)
            close all

            testCase.fs = 100;
            T = 600;                        % 10 minutes
            t = (0:1/testCase.fs:T-1/testCase.fs)';

            % Synthetic signal
            x = 0.05 * randn(size(t));
            x = x + sin(2*pi*2*t);
            x(500:560)   = x(500:560)   + 5*gausswin(61);
            x(3000:3120) = x(3000:3120) + 3*gausswin(121);

            testCase.start = fix(now);
            testCase.data  = x;

            ctag = ChannelTag('XX.SYN..BHZ');
            testCase.w = waveform(ctag, testCase.fs, ...
                                   testCase.start, ...
                                   testCase.data, ...
                                   'Counts');
        end
    end

    %% --------------------------------------------------------------------
    methods (Test)
        function testConstructorDefault(testCase)
            h = drumplot();
            testCase.verifyClass(h,'drumplot');
        end

        function testConstructorWithWaveform(testCase)
            h = drumplot(testCase.w);
            testCase.verifyClass(h,'drumplot');
            testCase.verifyEqual(h.wave, testCase.w);
        end

        function testConstructorWithParameters(testCase)
            h = drumplot(testCase.w, ...
                'mpl', 5, ...
                'scale', 2, ...
                'trace_color', [0 0 1]);

            testCase.verifyEqual(h.mpl, 5);
            testCase.verifyEqual(h.scale, 2);
            testCase.verifyEqual(h.trace_color, [0 0 1]);
        end

        function testPlotDoesNotError(testCase)
            h = drumplot(testCase.w,'mpl',5);

            f = figure('Visible','off');
            testCase.verifyWarningFree(@() plot(h));
            delete(f);
        end

        function testPlotHelicorderWrapper(testCase)
            f = figure('Visible','off');
            testCase.verifyWarningFree(@() plot_helicorder(testCase.w,'mpl',5));
            delete(f);
        end

        function testWithDetectionsIfAvailable(testCase)
            % Only run if Detection + STA/LTA are available
            try
                [det, ~, ~, ~] = Detection.sta_lta(testCase.w);
            catch
                testCase.assumeFail('Detection.sta_lta not available — skipping.');
            end

            % Require a non-empty Detection object
            if ~isa(det,'Detection') || det.numel == 0
                testCase.assumeFail('Detection.sta_lta did not return any detections — skipping.');
            end

            % Pass detections into drumplot in the supported way
            h = drumplot(testCase.w,'mpl',5,'detections',det);

            f = figure('Visible','off');
            testCase.verifyWarningFree(@() plot(h));
            delete(f);
        end

        function testBadWaveformRejected(testCase)
            badw = [testCase.w testCase.w];   % invalid (array)
            testCase.verifyError(@() drumplot(badw), ...
                'drumplot:InvalidWaveform');
        end

        function testWithRealMiniSEEDIfAvailable(testCase)
            % Optional real-data test using TESTDATA/miniseed_data/REF.EHZ.2009.081
            testdata = getenv('TESTDATA');
            if isempty(testdata)
                testCase.assumeFail('TESTDATA not defined — skipping real-data drumplot test.');
            end

            mseedfile = fullfile(testdata,'miniseed_data','REF.EHZ.2009.081');
            if exist(mseedfile,'file') ~= 2
                testCase.assumeFail('MiniSEED test file not found — skipping real-data drumplot test.');
            end

            try
                ds   = datasource('miniseed', mseedfile);
                % Station code may vary depending on how TESTDATA is set up;
                % XX network keeps things generic.
                ctag = ChannelTag('XX.REF..EHZ');

                wreal = waveform(ds, ctag);

                % Basic preprocessing to ensure reasonable scaling
                wreal = fillgaps(wreal,'interp');
                wreal = detrend(wreal);

                % Extract a short window (e.g., first hour)
                [snum, enum] = gettimerange(wreal);
                wshort = extract(wreal, 'time', snum, min(snum+1/24, enum));

                h = drumplot(wshort,'mpl',5);

                f = figure('Visible','off');
                testCase.verifyWarningFree(@() plot(h));
                delete(f);
            catch ME
                testCase.verifyFail(sprintf( ...
                    'Real-data drumplot test failed: %s', ME.message));
            end
        end
    end
end
