classdef test_rsam < matlab.unittest.TestCase
    %TEST_RSAM
    % CI-safe unit tests for GISMO RSAM class
    %
    % These tests:
    %   - Use only synthetic waveform data by default
    %   - Do not require Antelope, IceWeb, or IRIS
    %   - Optionally test legacy BOB reading if TESTDATA is available
    %
    % Glenn Thompson / Refactored 2025

    properties
        wf        % synthetic waveform
        fs
        startTime
        data
        tmpdir
    end

    %% --------------------------------------------------------------------
    methods (TestClassSetup)
        function setupGISMOPath(testCase)
            gismopath = fileparts(which('startup_GISMO'));
            if ~isempty(gismopath)
                addpath(genpath(gismopath));
            else
                error('GISMO not found on MATLAB path.');
            end

            testCase.tmpdir = fullfile(tempdir, 'gismo_rsam_tests');
            if ~exist(testCase.tmpdir,'dir')
                mkdir(testCase.tmpdir);
            end
        end
    end

    methods (TestClassTeardown)
        function cleanupGISMO(testCase)
            if exist(testCase.tmpdir,'dir')
                try
                    rmdir(testCase.tmpdir,'s');
                catch
                end
            end
        end
    end

    %% --------------------------------------------------------------------
    methods (TestMethodSetup)
        function createSyntheticWaveform(testCase)

            testCase.fs = 20;     % 20 Hz
            testCase.startTime = fix(now);

            t = (0:1/testCase.fs:3600)';
            sig = 500 * sin(2*pi*2*t);
            noise = 100 * randn(size(t));

            testCase.data = sig + noise;

            testCase.wf = waveform( ...
                'XX.TEST..BHZ', ...
                testCase.fs, ...
                testCase.startTime, ...
                testCase.data, ...
                'Counts');

        end
    end

    %% ====================================================================
    %% 1. RSAM Construction
    %% ====================================================================
    methods (Test)
        function testWaveform2RSAM_Default(testCase)
            r = waveform2rsam(testCase.wf);

            testCase.verifyClass(r,'rsam');
            testCase.verifyGreaterThan(numel(r.data),10);
            testCase.verifyEqual(r.measure,'mean');
            testCase.verifyEqual(r.sampling_interval,60, 'AbsTol', 1e-3);
        end

        function testWaveform2RSAM_Max(testCase)
            r = waveform2rsam(testCase.wf,'max',10);

            testCase.verifyEqual(r.measure,'max');
            testCase.verifyEqual(r.sampling_interval,10, 'AbsTol', 1e-3);
        end

        function testWaveform2RSAM_Median(testCase)
            r = waveform2rsam(testCase.wf,'median',300);

            testCase.verifyEqual(r.measure,'median');
            testCase.verifyEqual(r.sampling_interval,300, 'AbsTol', 1e-3);
        end
    end

    %% ====================================================================
    %% 2. RSAM Data Integrity
    %% ====================================================================
    methods (Test)
        function testRSAMTimeVector(testCase)
            r = waveform2rsam(testCase.wf, 'mean', 60);

            testCase.verifyEqual(numel(r.dnum), numel(r.data));
            testCase.verifyGreaterThan(min(r.dnum), testCase.startTime-1);
            testCase.verifyLessThan(max(r.dnum), testCase.startTime+1);
        end

        function testRSAMUnits(testCase)
            r = waveform2rsam(testCase.wf);

            testCase.verifyEqual(r.units, 'Counts');
        end
    end

    %% ====================================================================
    %% 3. Plotting (Smoke Tests)
    %% ====================================================================
    methods (Test)
        function testPlotDoesNotError(testCase)
            r = waveform2rsam(testCase.wf);

            f = figure('Visible','off');
            testCase.verifyWarningFree(@() plot(r));
            delete(f);
        end

        function testPanelPlotDoesNotError(testCase)
            r1 = waveform2rsam(testCase.wf);
            r2 = waveform2rsam(testCase.wf,'max',10);

            f = figure('Visible','off');
            testCase.verifyWarningFree(@() plot_panels([r1 r2]));
            delete(f);
        end
    end

    %% ====================================================================
    %% 4. Save + Reload (Text + BOB)
    %% ====================================================================
    methods (Test)
        function testSaveToText(testCase)
            r = waveform2rsam(testCase.wf,'max',10);

            fn = fullfile(testCase.tmpdir,'test_rsam.txt');
            testCase.verifyWarningFree(@() r.save_to_text_file(fn));

            testCase.verifyTrue(exist(fn,'file')==2);
        end

        function testSaveToBOB(testCase)
            r = waveform2rsam(testCase.wf,'max',10);

            fn = fullfile(testCase.tmpdir,'test_rsam.bob');
            testCase.verifyWarningFree(@() r.save_to_bob_file(fn));

            testCase.verifyTrue(exist(fn,'file')==2);
        end
    end

    %% ====================================================================
    %% 5. Legacy BOB Loading (Optional)
    %% ====================================================================
    methods (Test)
        function testReadLegacyBOBIfAvailable(testCase)

            if ~admin.is_testdata_setup()
                testCase.assumeFail('TESTDATA not available — skipping BOB read test.');
            end

            dp = fullfile(TESTDATA,'rsam','MCPZ1996.DAT');

            if exist(dp,'file')~=2
                testCase.assumeFail('Legacy BOB file missing — skipping BOB read test.');
            end

            r = rsam.read_bob_file(dp, ...
                'snum', datenum(1996,12,1), ...
                'enum', datenum(1996,12,31), ...
                'sta', 'MCPZ', ...
                'units', 'Counts');

            testCase.verifyClass(r,'rsam');
            testCase.verifyGreaterThan(numel(r.data),100);
        end
    end

end