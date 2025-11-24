classdef test_TraceData < matlab.unittest.TestCase
    % TEST_TRACEDATA
    % Unit tests for the TraceData class.
    %
    % All tests are CI-safe: placeholders do not fail unless implemented.

    methods (Static)
        function T = makeTraceData(data_, samplerate_, units_)
            T = TraceData;
            T.data = data_;
            T.samplerate = samplerate_;
            T.units = units_;
        end
    end

    % ---------------------------------------------------------------------
    %% Basic constructor & data handling
    % ---------------------------------------------------------------------
    methods (Test)

        function test_data(testCase)
            import matlab.unittest.constraints.IsEmpty

            T = TraceData;
            testCase.verifyThat(T.data, IsEmpty, ...
                'Default data should be empty.');

            testdata = [1 2 3 -inf inf 0];
            T.data = testdata;
            testCase.verifyEqual(T.data, testdata(:));
        end

        function test_samplerate(testCase)
            T = TraceData;
            T.samplerate = 10;
            testCase.verifyEqual(T.samplerate, 10);
        end

        function test_units(testCase)
            T = TraceData;
            T.units = 'abc';
            testCase.verifyEqual(T.units, 'abc');
        end

        % -----------------------------------------------------------------
        %% Duration
        % -----------------------------------------------------------------
        function test_duration(testCase)
            simpledata = [1 2 3 -inf inf nan 0];
            T = test_TraceData.makeTraceData(simpledata, 1, 'counts');
            testCase.verifyEqual(T.duration, numel(simpledata));

            T.samplerate = numel(simpledata);
            testCase.verifyEqual(T.duration, 1);

            T.data = [];
            testCase.verifyEqual(T.duration, 0);

            T.data = nan;
            testCase.verifyEqual(T.duration, 1/numel(simpledata)); 
        end

        % -----------------------------------------------------------------
        %% Equality and negation
        % -----------------------------------------------------------------
        function test_eq(testCase)
            simpledata = [1 2 3 -inf inf 0];
            A = test_TraceData.makeTraceData(simpledata, 1, 'counts');
            B = test_TraceData.makeTraceData(simpledata, 1, 'counts');

            testCase.verifyTrue(A == B);
            testCase.verifyFalse(A ~= B);
            testCase.verifyTrue(-A ~= B);
        end

        function test_uminus(testCase)
            simpledata = [-inf -5 0 10 20.05 inf];
            T = test_TraceData.makeTraceData(simpledata, 5, 'counts');

            testCase.verifyEqual(-simpledata(:), -T.data);
            testCase.verifyEqual(-(-(-T)), -T);
        end

        % -----------------------------------------------------------------
        %% Plus / minus / times
        % -----------------------------------------------------------------
        function test_plus(testCase)
            simpledata = (-1:0.2:10)';
            T = test_TraceData.makeTraceData(simpledata, 1, 'counts');

            Ta = T + 0;
            testCase.verifyEqual(Ta.data, simpledata);

            Ta = T + 1.23;
            testCase.verifyEqual(Ta.data, simpledata + 1.23);

            Ta = T + T.data;
            testCase.verifyEqual(Ta.data, 2 * simpledata);

            % multiple TraceData objects
            T2 = [T; T];
            T2 = T2 + 4;
            testCase.verifyEqual(T2(1).data, simpledata + 4);
            testCase.verifyEqual(T2(2).data, simpledata + 4);

            T2 = [T, T];
            testCase.verifyEqual(T2(1), T2(2));
        end

        function testMinus(testCase)
            simpledata = [1 2 3 -inf inf 0];
            T = test_TraceData.makeTraceData(simpledata, 10, 'counts');
            T2 = T - 5;
            testCase.verifyEqual(T + (-5), T2);
        end

        function test_times(testCase)
            simpledata = [1 2 3 -inf inf 0];
            T = test_TraceData.makeTraceData(simpledata, 10, 'counts');
            testCase.verifyEqual(T .* 2, T + T.data);
        end

        % -----------------------------------------------------------------
        %% Powers
        % -----------------------------------------------------------------
        function test_power(testCase)
            simpledata = [1 2 3 -inf inf 0];
            T = test_TraceData.makeTraceData(simpledata, 10, 'counts');

            powT = test_TraceData.makeTraceData(simpledata .^ 3.5, 10, 'counts');

            testCase.verifyEqual(T .^ 2, T .* T.data);
            testCase.verifyEqual(T .^ 3.5, powT);
        end

        % -----------------------------------------------------------------
        %% Basic math: abs, sign
        % -----------------------------------------------------------------
        function test_abs(testCase)
            simpledata = [1 2 3 -inf inf 0];
            T = test_TraceData.makeTraceData(simpledata, 10, 'counts');
            Tkey = test_TraceData.makeTraceData(abs(simpledata), 10, 'counts');

            testCase.verifyEqual(abs(T), Tkey);
        end

        function test_sign(testCase)
            simpledata = [1 2 3 -inf inf 0];
            T = test_TraceData.makeTraceData(simpledata, 10, 'counts');
            Tsig = test_TraceData.makeTraceData(sign(simpledata), 10, 'sign(counts)');

            testCase.verifyEqual(sign(T), Tsig);
        end

        % -----------------------------------------------------------------
        %% double conversion
        % -----------------------------------------------------------------
        function test_double(testCase)
            simpledata = [1 2 3 -inf inf 0]';
            T(1) = test_TraceData.makeTraceData(simpledata, 10, 'counts');
            T(2) = -T(1);

            testCase.verifyEqual(double(T(1)), simpledata);
            testCase.verifyEqual(double(T), [simpledata, -simpledata]);
        end

        % -----------------------------------------------------------------
        %% Resampling tests
        % -----------------------------------------------------------------
        function test_resample(testCase)
            simpledata = [-20 20 0 0 -1 1 3 4 10 20 -14 -12];
            T10 = test_TraceData.makeTraceData(simpledata, 10, 'counts');
            T5  = test_TraceData.makeTraceData([],       5, 'counts');

            % MAX
            T5.data = [20 0 1 4 20 -12];
            testCase.verifyEqual(T10.resample('max', 2), T5);

            % MIN
            T5.data = [-20 0 -1 3 10 -14];
            testCase.verifyEqual(T10.resample('min', 2), T5);

            % MEAN
            T5.data = [0 0 0 3.5 15 -13];
            testCase.verifyEqual(T10.resample('mean',2), T5);

            % ABSMAX
            T5.data = [20 0 1 4 20 14];
            testCase.verifyEqual(T10.resample('absmax',2), T5);

            % ABSMIN
            T5.data = [20 0 1 3 10 12];
            testCase.verifyEqual(T10.resample('absmin',2), T5);

            % MEDIAN
            T10.data = [0 0 0 3.5 -15 100 82 95 90];
            T10.samplerate = 9;

            T5 = test_TraceData.makeTraceData([0 3.5 90], 3, 'counts');
            testCase.verifyEqual(T10.resample('median',3), T5);
        end

        % -----------------------------------------------------------------
        %% Unimplemented tests (kept as placeholders)
        % -----------------------------------------------------------------
        function testConstructors(testCase), end
        function test_mtimes(testCase), end
        function test_rdivide(testCase), end
        function test_min(testCase), end
        function test_max(testCase), end
        function test_median(testCase), end
        function test_mean(testCase), end
        function test_std(testCase), end
        function test_var(testCase), end
        function test_demean(testCase), end
        function test_integerate(testCase), end  % spelled as in original
        function test_diff(testCase), end
        function test_detrend(testCase), end
        function test_smooth(testCase), end
        function test_fillgaps(testCase), end
        function test_clip(testCase), end
        function stack(testCase), end
        function binstack(testCase), end
        function test_taper(testCase), end
        function test_hilbert(testCase), end
        function test_zero2nan(testCase), end
        function test_extract(testCase), end

    end
end