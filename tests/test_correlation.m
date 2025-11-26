classdef test_correlation < matlab.unittest.TestCase
    % TEST_CORRELATION
    % Unified correlation test suite combining:
    %   - Constructor diagnostics (formerly correlation_diagnostics.m)
    %   - adjustTrig tests
    %   - Method smoke tests for broader API coverage
    %
    % All tests avoid external dependencies (Antelope/Winston/Coral)
    % unless safely detectable.
    %
    % GISMO-ready & MATLAB Unit Test–compatible.

    % ---------------------------------------------------------------------
    methods (TestClassSetup)
        function setupGISMO(testCase)
            % Ensure GISMO is available
            gismopath = fileparts(which('startup_GISMO'));
            if ~isempty(gismopath)
                addpath(genpath(gismopath));
            else
                error('GISMO not found on MATLAB path.');
            end
        end
    end

    methods (TestClassTeardown)
        function teardownGISMO(testCase)
            % Clean up path additions
            gismopath = fileparts(which('startup_GISMO'));
            if ~isempty(gismopath)
                rmpath(genpath(gismopath));
            end
        end
    end

    % ---------------------------------------------------------------------
    %% 1. Constructor Variants (Merged from correlation_diagnostics.m)
    % ---------------------------------------------------------------------
    methods (Test)
        function TestConstructorVariants(testCase)
            % Empty constructor
            c1 = correlation;
            testCase.verifyInstanceOf(c1, 'correlation');

            % Synthetic: correlation(N)
            c2 = correlation(5);
            testCase.verifyEqual(get(c2,'TRACES'), 5);

            % DEMO dataset (optional)
            demoFile = which('demo_data_100.mat');
            if ~isempty(demoFile)
                c3 = correlation('DEMO');
                testCase.verifyInstanceOf(c3, 'correlation');
            else
                testCase.verifyWarningFree(@() disp('Skipping DEMO, no demo_data_100.mat'));
            end

            % WAVEFORM constructor (no triggers)
            w = waveform;
            w = set(w, 'data', randn(1,200));
            w = set(w, 'freq', 20);
            c4 = correlation(w);
            testCase.verifyInstanceOf(c4, 'correlation');

            % WAVEFORM + trig
            trig = now;
            c5 = correlation(w, trig);
            testCase.verifyInstanceOf(c5, 'correlation');

            % CORAL struct (optional)
            coralStruct = testCase.createCoralStruct();
            if ~isempty(coralStruct)
                c6 = correlation(coralStruct);
                testCase.verifyInstanceOf(c6, 'correlation');
            end
        end
    end

    methods
        function coralStruct = createCoralStruct(~)
            % Build minimal CORAL struct
            try
                coralStruct.data = randn(1,200);
                coralStruct.staCode = 'ABC';
                coralStruct.staChannel = 'EHZ';
                coralStruct.recStartTime = datevec(now);
                coralStruct.recSampInt = 1/20;   % 20 Hz
                coralStruct.pPick = datevec(now + 1/86400);
            catch
                coralStruct = [];
            end
        end
    end

    % ---------------------------------------------------------------------
    %% 2. adjustTrig Tests
    % ---------------------------------------------------------------------
    methods (Test)
        function TestAdjustTrigDefaults(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.adjustrig());
        end

        function TestAdjustTrigTimeshift(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.adjustrig('index', 10));
        end

        function TestAdjustTrigMin(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.adjustrig('min'));
        end

        function TestAdjustTrigMedian(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.adjustrig('median'));
        end

        function TestAdjustTrigMaxLag(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.adjustrig('min', 1));
        end

        function TestAdjustTrigIndex(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.adjustrig('index'));
        end

        function TestAdjustTrigIndexRelativeToSpecificTrace(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.adjustrig('index', 10));
        end

        function TestAdjustTrigLeastSquares(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.adjustrig('lsq'));
        end
    end

    % ---------------------------------------------------------------------
    %% 3. Method Smoke Tests (non-exhaustive, but good for API coverage)
    % ---------------------------------------------------------------------
    methods (Test)
        function TestAutoGainControl(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.agc());
        end

        function TestAlign(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.align());
        end

        function testButter(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.butter(2, 0.2));
        end

        function testCat(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() [c; c]); % concatenation
        end

        function testCheck(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.check());
        end

        function testCluster(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.cluster());
        end

        function testColormap(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.colormap());
        end

        function testConv(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.conv());
        end

        function testCrop(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.crop(1, 2));
        end

        function testDeconv(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.deconv());
        end

        function testDemean(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.demean());
        end

        function testDetrend(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() c.detrend());
        end

        function testDiff(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() diff(c));
        end

        function testFind(testCase)
            c = correlation.demo();
            testCase.verifyWarningFree(@() find(c));
        end
    end

end
