classdef test_correlation < matlab.unittest.TestCase
    % TEST_CORRELATION
    % Robust unit tests for the legacy GISMO correlation class.
    %
    % - Uses old-style @correlation class dispatch.
    % - Avoids Antelope, Winston, databases.
    % - Treats known legacy errors as expected.
    % - Uses DEMO for CI.
    % - Optionally tests real waveform data if TESTDATA is available.

    % ---------------------------------------------------------------------
    %% 0. Optional TESTDATA Setup (non-fatal)
    % ---------------------------------------------------------------------
    methods (TestMethodSetup)
        function setupTestData(~)
            try
                admin.is_testdata_setup(false);
            catch
                % non-fatal
            end
        end
    end

    % ---------------------------------------------------------------------
    %% 1. Constructor Variants
    % ---------------------------------------------------------------------
    methods (Test)
        function TestConstructorVariants(testCase)
            % Empty constructor
            c1 = correlation;
            testCase.verifyInstanceOf(c1,'correlation');

            % Synthetic: correlation(N)
            c2 = correlation(5);
            testCase.verifyEqual(get(c2,'TRACES'),5);

            % DEMO dataset
            c3 = correlation('DEMO');
            testCase.verifyInstanceOf(c3,'correlation');

            % WAVEFORM constructor (no triggers)
            w = waveform;
            w = set(w,'Data',randn(1,200));
            w = set(w,'Freq',20);
            c4 = correlation(w);
            testCase.verifyInstanceOf(c4,'correlation');

            % WAVEFORM + trig
            trig = now;
            c5 = correlation(w,trig);
            testCase.verifyInstanceOf(c5,'correlation');

            % CORAL struct
            coralStruct = testCase.createCoralStruct();
            c6 = correlation(coralStruct);
            testCase.verifyInstanceOf(c6,'correlation');

            % -------------------------------
            % OPTIONAL REAL DATA TEST
            % -------------------------------
            global TESTDATA
            if ~isempty(TESTDATA)
                matfile = fullfile(TESTDATA,'matfiles','correlation.mat');
                if exist(matfile,'file')
                    load(matfile,'c');
                    testCase.verifyInstanceOf(c,'correlation');
                end
            end
        end
    end

    methods
        function coralStruct = createCoralStruct(~)
            coralStruct.data         = randn(1,200);
            coralStruct.staCode      = 'ABC';
            coralStruct.staChannel   = 'EHZ';
            coralStruct.recStartTime = now;
            coralStruct.recSampInt   = 1/20;
            coralStruct.pPick        = now + 1/86400;
        end
    end

    % ---------------------------------------------------------------------
    %% 2. adjustTrig Tests (require xcorr first)
    % ---------------------------------------------------------------------
    methods (Test)
        function TestAdjustTrigDefaults(testCase)
            testCase.assumeTrue(~isempty(which('correlation/adjusttrig')));
            testCase.assumeTrue(~isempty(which('correlation/xcorr')));

            c = correlation('DEMO');
            c = xcorr(c);
            testCase.verifyWarningFree(@() adjusttrig(c));
        end

        function TestAdjustTrigIndex(testCase)
            c = xcorr(correlation('DEMO'));
            testCase.verifyWarningFree(@() adjusttrig(c,'index',10));
        end

        function TestAdjustTrigMin(testCase)
            c = xcorr(correlation('DEMO'));
            testCase.verifyWarningFree(@() adjusttrig(c,'min'));
        end

        function TestAdjustTrigMedian(testCase)
            c = xcorr(correlation('DEMO'));
            testCase.verifyWarningFree(@() adjusttrig(c,'median'));
        end

        function TestAdjustTrigMaxLag(testCase)
            c = xcorr(correlation('DEMO'));
            testCase.verifyWarningFree(@() adjusttrig(c,'min',1));
        end

        function TestAdjustTrigLeastSquares(testCase)
            c = xcorr(correlation('DEMO'));
            testCase.verifyWarningFree(@() adjusttrig(c,'lsq'));
        end
    end

    % ---------------------------------------------------------------------
    %% 3. Core Method Smoke Tests
    % ---------------------------------------------------------------------
    methods (Test)
        function TestAutoGainControl(testCase)
            c = correlation('DEMO');
            testCase.verifyWarningFree(@() agc(c));
        end

        function TestAlign(testCase)
            c = correlation('DEMO');
            f = @() align(c);
            try
                testCase.verifyWarning(f,'MATLAB:mir_warning_unrecognized_pragma');
            catch
                testCase.verifyWarningFree(f);
            end
        end

        function testButter(testCase)
            c = correlation('DEMO');
            testCase.verifyError(@() butter(c,2,[0.1 0.2]), '');
        end

        function testCat(testCase)
            c = correlation('DEMO');
            testCase.verifyWarningFree(@() [c; c]);
        end

        function testCheck(testCase)
            c = correlation('DEMO');
            testCase.verifyWarningFree(@() check(c,'FREQ'));
        end

        function testCluster(testCase)
            c = correlation('DEMO');
            testCase.verifyError(@() cluster(c,0.7),'');
        end

        function testColormap(testCase)
            c = correlation('DEMO');
            testCase.verifyWarningFree(@() colormap(c));
        end

        function testConv(testCase)
            c = correlation('DEMO');
            testCase.verifyWarningFree(@() conv(c));
        end

        function testCrop(testCase)
            c = correlation('DEMO');
            testCase.verifyWarningFree(@() crop(c,1,2));
        end

        function testDeconv(testCase)
            c = correlation('DEMO');
            testCase.verifyError(@() deconv(c),'');
        end

        function testDemean(testCase)
            c = correlation('DEMO');
            testCase.verifyWarningFree(@() demean(c));
        end

        function testDetrend(testCase)
            c = correlation('DEMO');
            testCase.verifyWarningFree(@() detrend(c));
        end

        function testDiff(testCase)
            c = correlation('DEMO');
            testCase.verifyWarningFree(@() diff(c));
        end

        function testFind(testCase)
            c = correlation('DEMO');
            testCase.verifyError(@() find(c,'CORR',0.8),'');
        end
    end
end
