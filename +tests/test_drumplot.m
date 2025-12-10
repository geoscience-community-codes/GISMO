classdef test_drumplot < matlab.unittest.TestCase
    %TEST_DRUMPLOT
    % CI-safe unit tests for the drumplot class.
    %
    % Design principles:
    %   • Core tests use synthetic waveform data only
    %   • Optional features are guarded and SKIPPED if unavailable
    %   • No hard dependency on TESTDATA / Antelope / IRIS
    %   • Plotting tests only verify "does not error"
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
            % Basic environment sanity check
            tests.guard(testCase,'basic');

            close all
            set(0,'DefaultFigureVisible','off');

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
            testCase.w = waveform(ctag, ...
                                   testCase.fs, ...
                                   testCase.start, ...
                                   testCase.data, ...
                                   'Counts');
        end
    end

    %% --------------------------------------------------------------------
    methods (Test)

        function testConstructorDefault(testCase)
            tests.guard(testCase,'basic');

            h = drumplot();
            testCase.verifyClass(h,'drumplot');
        end

        function testConstructorWithWaveform(testCase)
            tests.guard(testCase,'basic');

            h = drumplot(testCase.w);
            testCase.verifyClass(h,'drumplot');
            testCase.verifyEqual(h.wave, testCase.w);
        end

        function testConstructorWithParameters(testCase)
            tests.guard(testCase,'basic');

            h = drumplot(testCase.w, ...
                'mpl', 5, ...
                'scale', 2, ...
                'trace_color', [0 0 1]);

            testCase.verifyEqual(h.mpl, 5);
            testCase.verifyEqual(h.scale, 2);
            testCase.verifyEqual(h.trace_color, [0 0 1]);
        end

        function testPlotDoesNotError(testCase)
            tests.guard(testCase,'basic');

            h = drumplot(testCase.w,'mpl',5);
            f = figure('Visible','off');

            testCase.verifyWarningFree(@() plot(h));

            delete(f);
        end

        function testPlotHelicorderWrapper(testCase)
            tests.guard(testCase,'basic');

            f = figure('Visible','off');
            testCase.verifyWarningFree(@() ...
                plot_helicorder(testCase.w,'mpl',5));
            delete(f);
        end

        function testWithDetectionsIfAvailable(testCase)
            % Requires Signal Processing Toolbox + Detection
            tests.guard(testCase,'signal');

            [det,~,~,~] = Detection.sta_lta(testCase.w);

            if det.numel == 0
                testCase.assumeFail( ...
                    'No detections produced — skipping detection overlay test.');
            end

            h = drumplot(testCase.w,'mpl',5,'detections',det);

            f = figure('Visible','off');
            testCase.verifyWarningFree(@() plot(h));
            delete(f);
        end

        function testBadWaveformRejected(testCase)
            tests.guard(testCase,'basic');

            badw = [testCase.w testCase.w];   % invalid waveform array

            testCase.verifyError(@() drumplot(badw), ...
                'drumplot:InvalidWaveform');
        end

        function testWithRealMiniSEEDIfAvailable(testCase)
            % Optional real-data integration test
            tests.guard(testCase,'basic');

            G = admin.gismo_guard();

            if ~G.TESTDATA.configured
                testCase.assumeFail( ...
                    'TESTDATA not configured — skipping real MiniSEED test.');
            end

            testdata = getenv('TESTDATA');
            mseedfile = fullfile(testdata,'miniseed_data','REF.EHZ.2009.081');

            if exist(mseedfile,'file') ~= 2
                testCase.assumeFail( ...
                    'MiniSEED file not found — skipping real MiniSEED test.');
            end

            ds   = datasource('miniseed', mseedfile);
            ctag = ChannelTag('XX.REF..EHZ');

            wreal = waveform(ds, ctag);

            % Defensive preprocessing
            wreal = fillgaps(wreal,'interp');
            wreal = detrend(wreal);

            [snum, enum] = gettimerange(wreal);
            wshort = extract(wreal, 'time', ...
                snum, min(snum + 1/24, enum));   % first hour

            h = drumplot(wshort,'mpl',5);

            f = figure('Visible','off');
            testCase.verifyWarningFree(@() plot(h));
            delete(f);
        end

    end
end
