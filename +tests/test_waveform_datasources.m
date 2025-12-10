classdef test_waveform_datasources < matlab.unittest.TestCase
    %CI-safe tests for portable waveform datasources
    %
    % Antelope:
    %   - Uses downloadable TESTDATA only
    %
    % IRIS:
    %   - Uses live web services
    %
    % Winston:
    %   - Smoke test only (no data expectation)

    properties
        originalDir
    end

    methods (TestClassSetup)
        function setupPaths(testCase)
            testCase.originalDir = pwd;

            gismopath = fileparts(which('startup_GISMO'));
            if ~isempty(gismopath)
                addpath(genpath(gismopath));
            end
        end
    end

    methods (TestClassTeardown)
        function restoreDir(testCase)
            cd(testCase.originalDir);
        end
    end

    %% =============================================================
    %% ANT ELOPE — SINGLE PORTABLE TEST
    %% =============================================================
    methods (Test)
        function testAntelope_TESTDATA(testCase)

            assumeTrue(testCase, admin.is_testdata_setup(), ...
                'TESTDATA not installed.');
            assumeTrue(testCase, admin.antelope_exists(), ...
                'Antelope not installed.');

            dbpath = fullfile(TESTDATA,'antelope','testdb');
            assumeTrue(testCase, exist(dbpath,'dir')==7, ...
                'Antelope test database not found in TESTDATA.');

            ds = datasource('antelope', dbpath);

            scnl = scnlobject('TEST','BHZ');
            startTime = datenum(2020,1,1,0,0,0);
            endTime   = datenum(2020,1,1,0,10,0);

            w = waveform(ds, scnl, startTime, endTime);

            testCase.verifyClass(w,'waveform');
            testCase.verifyNotEmpty(w);
        end

        %% =========================================================
        %% IRIS DMC WEB SERVICES
        %% =========================================================
        function testIRIS(testCase)

            assumeTrue(testCase, exist('irisFetch','file')==2, ...
                'irisFetch not available.');

            ds = datasource('irisdmcws');
            chan = ChannelTag('IU.ANMO.10.BHZ');

            w = waveform(ds, chan, ...
                '2010-02-27 06:30:00', ...
                '2010-02-27 10:30:00');

            testCase.verifyClass(w,'waveform');
            testCase.verifyNotEmpty(w);
        end

        %% =========================================================
        %% WINSTON (SMOKE TEST ONLY)
        %% =========================================================
        function testWinston(testCase)

            ds = datasource('winston','pubavo1.wr.usgs.gov',16022);
            chanInfo = ChannelTag.array('AV.REF.--.EHZ');

            w = waveform(ds, chanInfo, now-1/1440, now);

            % Winston may return empty — only verify call integrity
            testCase.verifyClass(w,'waveform');
        end
    end
end
