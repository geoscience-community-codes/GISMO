classdef test_EventRate < matlab.unittest.TestCase
    % TEST_EVENTRATE
    %
    % Unit tests for the EventRate class.
    %
    % All tests use a synthetic Catalog object with fully controlled
    % timestamps and magnitudes so that counts, mean_rate, median_rate,
    % cum_mag, mean_mag, and median_mag can be verified exactly.
    %
    % No Antelope, no TESTDATA, no external files required.

    properties
        C   % synthetic Catalog
    end

    %% --------------------------------------------------------------------
    methods (TestClassSetup)
        function makeSyntheticCatalog(testCase)

            % Synthetic event times (in datenum)
            % Three events per hour, uniformly spaced, two-hour window
            t0 = datenum(2020,1,1,0,0,0);
            times = [
                t0 + 0/1440          % 00:00
                t0 + 20/1440         % 00:20
                t0 + 40/1440         % 00:40
                t0 + 60/1440         % 01:00
                t0 + 80/1440         % 01:20
                t0 + 100/1440        % 01:40
                ];

            mags = [1; 2; 3; 4; 5; 6];   % arbitrary but known

            % Create a minimal Catalog:
            C = Catalog();
            C.trig = times;
            C.lat  = zeros(size(times));
            C.lon  = zeros(size(times));
            C.depth = zeros(size(times));
            C.mag = mags;

            testCase.C = C;
        end
    end

    %% --------------------------------------------------------------------
    % Basic constructor tests
    %% --------------------------------------------------------------------
    methods (Test)
        function TestConstructorDefaults(testCase)
            er = testCase.C.eventrate();
            testCase.verifyClass(er, "EventRate");
            testCase.verifyNotEmpty(er.time);
        end

        function TestBinSizeOneHour(testCase)
            er = testCase.C.eventrate('binsize', 1/24);  % 1 hour
            % Expect 3 events per hour (we made them that way)
            testCase.verifyEqual(er.counts, [3; 3], ...
                'AbsTol', 1e-6, ...
                'Counts per hour should be exactly [3 3].');
        end

        function TestStepsizeSmallerThanBinsize(testCase)
            er = testCase.C.eventrate('binsize', 1/24, 'stepsize', 1/1440); % 1 min
            % We expect sliding-window counts to vary from 0→3→3→2→... etc
            testCase.verifyGreaterThan(max(er.counts), 0);
            testCase.verifySize(er.counts, size(er.time), ...
                'Sliding window eventrate counts must match number of windows.');
        end
    end

    %% --------------------------------------------------------------------
    % Magnitude and cumulative metrics
    %% --------------------------------------------------------------------
    methods (Test)
        function TestCumMag(testCase)
            er = testCase.C.eventrate('binsize', 1/24);
            % Magnitudes per hour:
            % Hour 1: 1+2+3 = 6
            % Hour 2: 4+5+6 = 15
            testCase.verifyEqual(er.cum_mag, [6; 15], 'AbsTol', 1e-6);
        end

        function TestMeanMag(testCase)
            er = testCase.C.eventrate('binsize', 1/24);
            testCase.verifyEqual(er.mean_mag, [2; 5], 'AbsTol', 1e-6);
        end

        function TestMedianMag(testCase)
            er = testCase.C.eventrate('binsize', 1/24);
            testCase.verifyEqual(er.median_mag, [2; 5], 'AbsTol', 1e-6);
        end

        function TestMeanRate(testCase)
            er = testCase.C.eventrate('binsize', 1/24);
            expected = er.counts ./ (1/24); % counts per hour
            testCase.verifyEqual(er.mean_rate, expected, 'AbsTol', 1e-6);
        end
    end

    %% --------------------------------------------------------------------
    % Plotting
    % These tests are smoke tests that ensure no exception is thrown.
    %% --------------------------------------------------------------------
    methods (Test)
        function TestPlotDefault(testCase)
            er = testCase.C.eventrate('binsize', 1/24);
            f = figure('Visible','off');
            er.plot();
            close(f);
        end

        function TestPlotSpecificMetric(testCase)
            er = testCase.C.eventrate('binsize', 1/24);
            f = figure('Visible','off');
            er.plot('metric','mean_rate');
            close(f);
        end

        function TestPlotMultipleMetrics(testCase)
            er = testCase.C.eventrate('binsize', 1/24);
            f = figure('Visible','off');
            er.plot('metric', {'counts','mean_mag','cum_mag'});
            close(f);
        end

        function TestHelenaPlot(testCase)
            er = testCase.C.eventrate('binsize', 1/24);
            f = figure('Visible','off');
            er.helenaplot();
            close(f);
        end

        function TestPythonPlot(testCase)
            er = testCase.C.eventrate('binsize', 1/24);
            f = figure('Visible','off');
            er.pythonplot();
            close(f);
        end
    end
end