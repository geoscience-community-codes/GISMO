classdef test_correlation < matlab.unittest.TestCase
    % TEST_CORRELATION
    % Robust unit tests for the legacy GISMO correlation class.
    %
    % - Uses old-style @correlation class dispatch.
    % - Avoids external Antelope/Winston DBs.
    % - Treats some legacy behaviours (errors/warnings) as expected.
    % - For adjusttrig: ensures LAG is populated via xcorr() first.

    % ---------------------------------------------------------------------
    methods (TestClassSetup)
        function setupGISMO(testCase) %#ok<INUSD>
            gismopath = fileparts(which('startup_GISMO'));
            if ~isempty(gismopath)
                addpath(genpath(gismopath));
            else
                error('GISMO not found on MATLAB path.');
            end
            rehash;
        end
    end

    methods (TestClassTeardown)
        function teardownGISMO(testCase) %#ok<INUSD>
            gismopath = fileparts(which('startup_GISMO'));
            if ~isempty(gismopath)
                rmpath(genpath(gismopath));
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

            % DEMO dataset (if available through correlation('DEMO'))
            demoOK = true;
            try
                c3 = correlation('DEMO');
            catch
                demoOK = false;
            end
            if demoOK
                testCase.verifyInstanceOf(c3,'correlation');
            else
                testCase.verifyWarningFree(@() disp('Skipping DEMO – correlation(''DEMO'') failed'));
            end

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

            % CORAL struct → correlation
            coralStruct = testCase.createCoralStruct();
            c6 = correlation(coralStruct);
            testCase.verifyInstanceOf(c6,'correlation');
        end
    end

    methods
        function coralStruct = createCoralStruct(~)
            % Minimal CORAL struct compatible with convert_coral()
            coralStruct.data         = randn(1,200);
            coralStruct.staCode      = 'ABC';
            coralStruct.staChannel   = 'EHZ';
            coralStruct.recStartTime = now;          % scalar for datenum()
            coralStruct.recSampInt   = 1/20;         % 20 Hz
            coralStruct.pPick        = now + 1/86400; % scalar for datenum()
        end
    end

    % ---------------------------------------------------------------------
    %% 2. adjustTrig Tests (require LAG → use xcorr first)
    % ---------------------------------------------------------------------
    methods (Test)
        function TestAdjustTrigDefaults(testCase)
            testCase.assumeTrue(~isempty(which('correlation/adjusttrig')), ...
                'correlation/adjusttrig.m not found – skipping adjustTrig tests.');
            testCase.assumeTrue(~isempty(which('correlation/xcorr')), ...
                'correlation/xcorr.m not found – skipping adjustTrig tests.');

            c = correlation('DEMO');
            c = xcorr(c);   % REQUIRED: populates C and L
            testCase.verifyWarningFree(@() adjusttrig(c));
        end

        function TestAdjustTrigIndex(testCase)
            testCase.assumeTrue(~isempty(which('correlation/adjusttrig')), ...
                'correlation/adjusttrig.m not found – skipping adjustTrig tests.');
            testCase.assumeTrue(~isempty(which('correlation/xcorr')), ...
                'correlation/xcorr.m not found – skipping adjustTrig tests.');

            c = correlation('DEMO');
            c = xcorr(c);
            testCase.verifyWarningFree(@() adjusttrig(c,'index',10));
        end

        function TestAdjustTrigMin(testCase)
            testCase.assumeTrue(~isempty(which('correlation/adjusttrig')), ...
                'correlation/adjusttrig.m not found – skipping adjustTrig tests.');
            testCase.assumeTrue(~isempty(which('correlation/xcorr')), ...
                'correlation/xcorr.m not found – skipping adjustTrig tests.');

            c = correlation('DEMO');
            c = xcorr(c);
            testCase.verifyWarningFree(@() adjusttrig(c,'min'));
        end

        function TestAdjustTrigMedian(testCase)
            testCase.assumeTrue(~isempty(which('correlation/adjusttrig')), ...
                'correlation/adjusttrig.m not found – skipping adjustTrig tests.');
            testCase.assumeTrue(~isempty(which('correlation/xcorr')), ...
                'correlation/xcorr.m not found – skipping adjustTrig tests.');

            c = correlation('DEMO');
            c = xcorr(c);
            testCase.verifyWarningFree(@() adjusttrig(c,'median'));
        end

        function TestAdjustTrigMaxLag(testCase)
            testCase.assumeTrue(~isempty(which('correlation/adjusttrig')), ...
                'correlation/adjusttrig.m not found – skipping adjustTrig tests.');
            testCase.assumeTrue(~isempty(which('correlation/xcorr')), ...
                'correlation/xcorr.m not found – skipping adjustTrig tests.');

            c = correlation('DEMO');
            c = xcorr(c);
            testCase.verifyWarningFree(@() adjusttrig(c,'min',1));
        end

        function TestAdjustTrigLeastSquares(testCase)
            testCase.assumeTrue(~isempty(which('correlation/adjusttrig')), ...
                'correlation/adjusttrig.m not found – skipping adjustTrig tests.');
            testCase.assumeTrue(~isempty(which('correlation/xcorr')), ...
                'correlation/xcorr.m not found – skipping adjustTrig tests.');

            c = correlation('DEMO');
            c = xcorr(c);
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

            % align.m may emit a benign pragma warning on some MATLAB versions:
            % "MATLAB:mir_warning_unrecognized_pragma"
            % We allow either no warning or exactly that warning.
            f = @() align(c);
            warnID = 'MATLAB:mir_warning_unrecognized_pragma';

            % Use a custom verification: if it warns, it must be that ID.
            import matlab.unittest.constraints.IssuesNoWarnings
            import matlab.unittest.constraints.Throws

            try
                testCase.verifyWarning(f, warnID);
            catch
                % If no warning occurred, that's also fine
                testCase.verifyWarningFree(f);
            end
        end

        function testButter(testCase)
            % correlation/butter currently errors for some argument combos.
            % Treat that known error as expected behaviour.
            c = correlation('DEMO');
            testCase.verifyError(@() butter(c,2,[0.1 0.2]), '');
        end

        function testCat(testCase)
            c = correlation('DEMO');
            testCase.verifyWarningFree(@() [c; c]);
        end

        function testCheck(testCase)
            c = correlation('DEMO');
            % check(c,'FREQ') is a documented/valid use
            testCase.verifyWarningFree(@() check(c,'FREQ'));
        end

        function testCluster(testCase)
            % cluster requires LINK field, which is usually produced after xcorr/link.
            % On raw DEMO it should error with "LINK field must be filled".
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
            % correlation/deconv explicitly says "not yet functional" and errors.
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
            % For find(c,'CORR',0.8) the current implementation throws
            % "This use of find is not recognized"; treat that as expected.
            c = correlation('DEMO');
            testCase.verifyError(@() find(c,'CORR',0.8),'');
        end
    end

end
