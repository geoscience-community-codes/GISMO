classdef test_waveform_datasources < matlab.unittest.TestCase
    %TEST_WAVEFORM_DATASOURCES
    % Safe, modular rewrite of the old trloadcss_test.m
    %
    % All tests depending on external datasources (UAF continuous, Antelope,
    % Winston, IRIS DMC web services, etc.) are now wrapped in skip guards so
    % that CI runs cleanly and developers can still exercise the tests manually.
    %
    % Each test performs:
    %   - datasource availability check
    %   - waveform() call
    %   - structural verification

    properties
        originalDir
    end

    %% --------------------------------------------------------------------
    methods (TestClassSetup)
        function setupPaths(testCase)
            testCase.originalDir = pwd;

            % Ensure GISMO path is available
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

    %% --------------------------------------------------------------------
    methods (TestMethodSetup)
        function closeFigs(~)
            close all
        end
    end


    %% ============================================================
    %  Helper: datasource availability
    % ============================================================

    methods (Static)
        function ok = isDatasourceAvailable(typeName)
            switch lower(typeName)
                case 'uaf_continuous'
                    ok = ~isempty(which('datasource')) && ~isempty(getenv('UAFDATAPATH'));

                case 'antelope'
                    ok = admin.antelope_exists;

                case 'winston'
                    ok = true;  % Winston server may still reject later

                case 'irisdmcws'
                    ok = ~isempty(which('irisFetch'));

                otherwise
                    ok = false;
            end
        end
    end


    %% ============================================================
    %  TESTS START HERE
    % ============================================================

    % ------------------------------------------------------------
    % Test 1 — simple UAF example (COLA)
    % ------------------------------------------------------------
    methods (Test)
        function testUAF_COLA(testCase)
            assumeTrue(testCase, test_waveform_datasources.isDatasourceAvailable('uaf_continuous'), ...
                'Skipping UAF tests (no UAFDATAPATH / unavailable).');

            ds = datasource('uaf_continuous');
            startTime = datenum(2009,2,15,19,33,20);
            endTime   = datenum(2009,2,15,19,40,0);
            scnl = scnlobject('COLA','BHZ*');

            w = waveform(ds, scnl, startTime, endTime);

            testCase.verifyNotEmpty(w);
            testCase.verifyClass(w, 'waveform');
        end


        % --------------------------------------------------------
        % Test 2 — UAF example, COR problematic but should not crash
        % --------------------------------------------------------
        function testUAF_COR_problematic(testCase)
            assumeTrue(testCase, test_waveform_datasources.isDatasourceAvailable('uaf_continuous'));

            ds = datasource('uaf_continuous');
            scnl = scnlobject({'COLA','COR'}, 'BHZ*');
            startTime = datenum(2009,2,15,19,33,20);
            endTime   = datenum(2009,2,15,19,40,0);

            w = waveform(ds, scnl, startTime, endTime);

            testCase.verifyNotEmpty(w);
        end


        % --------------------------------------------------------
        % Test 3–4 — BEAAR array via Antelope
        % --------------------------------------------------------
        function testAntelope_BEAAR_DH1(testCase)
            assumeTrue(testCase, test_waveform_datasources.isDatasourceAvailable('antelope'), ...
                'Skipping Antelope tests.');

            dbpath = '/home/admin/databases/BEAAR/wf/beaar';
            ds = datasource('antelope', dbpath);

            scnl = scnlobject({'BYR','CAR','DH1'}, 'BHZ_01');
            startTime = '2000/07/31 22:44:38';
            endTime   = '2000/07/31 23:59:38';

            w = waveform(ds, scnl, startTime, endTime);
            testCase.verifyNotEmpty(w);
        end

        function testAntelope_BEAAR_wildcardSta(testCase)
            assumeTrue(testCase, test_waveform_datasources.isDatasourceAvailable('antelope'));

            dbpath = '/home/admin/databases/BEAAR/wf/beaar';
            ds = datasource('antelope', dbpath);

            scnl = scnlobject('*','BHZ_01');
            startTime = '2000/07/31 22:44:38';
            endTime   = '2000/07/31 23:59:38';

            w = waveform(ds, scnl, startTime, endTime);
            testCase.verifyNotEmpty(w);
        end


        % --------------------------------------------------------
        % Test 6 — UAF AKT problem example
        % --------------------------------------------------------
        function testUAF_AKT_problem(testCase)
            assumeTrue(testCase, test_waveform_datasources.isDatasourceAvailable('uaf_continuous'));

            ds = datasource('uaf_continuous');
            scnl = scnlobject('*','HHZ*');

            startTime = datenum(2011,11,16,16,29,0);
            endTime   = startTime + 1/100;

            w = waveform(ds, scnl, startTime, endTime);
            testCase.verifyNotEmpty(w);
        end


        % --------------------------------------------------------
        % Test 7 — UAF day boundary
        % --------------------------------------------------------
        function testUAF_dayBoundary(testCase)
            assumeTrue(testCase, test_waveform_datasources.isDatasourceAvailable('uaf_continuous'));

            ds = datasource('uaf_continuous');
            scnl = scnlobject({'REF','RSO'}, 'EHZ');

            startTime = '2009/03/21 23:00:00';
            endTime   = '2009/03/22 01:00:00';

            w = waveform(ds, scnl, startTime, endTime);
            testCase.verifyNotEmpty(w);
        end


        % --------------------------------------------------------
        % Test 8 & 10 — Carl Tape wildcard test (UAF)
        % --------------------------------------------------------
        function testUAF_CarlWildcard(testCase)
            assumeTrue(testCase, test_waveform_datasources.isDatasourceAvailable('uaf_continuous'));

            ds = datasource('uaf_continuous');
            scnl = scnlobject('C*','BHZ*');

            startTime = 7.338198148159491e+05;
            endTime   = 7.338198194455787e+05;

            w = waveform(ds, scnl, startTime, endTime);
            testCase.verifyNotEmpty(w);
        end


        % --------------------------------------------------------
        % Test 9 — YAHTSE network via Antelope
        % --------------------------------------------------------
        function testAntelope_YAHTSE(testCase)
            assumeTrue(testCase, test_waveform_datasources.isDatasourceAvailable('antelope'));

            ds = datasource('antelope','/home/admin/databases/YAHTSE/wf/yahtse');
            scnl = scnlobject('X*','*');

            startTime = '2010-09-18 14:14:42';
            endTime   = '2010-09-18 14:16:12';

            w = waveform(ds, scnl, startTime, endTime);
            testCase.verifyNotEmpty(w);
        end


        % --------------------------------------------------------
        % IRIS DMC Web Services
        % --------------------------------------------------------
        function testIRIS(testCase)
            assumeTrue(testCase, test_waveform_datasources.isDatasourceAvailable('irisdmcws'), ...
                'irisFetch not available on this system.');

            ds = datasource('irisdmcws');
            chan = ChannelTag('IU.ANMO.10.BHZ');

            w = waveform(ds, chan, '2010-02-27 06:30:00','2010-02-27 10:30:00');
            testCase.verifyNotEmpty(w);
        end


        % --------------------------------------------------------
        % Winston Server
        % --------------------------------------------------------
        function testWinston(testCase)
            assumeTrue(testCase, test_waveform_datasources.isDatasourceAvailable('winston'));

            ds = datasource('winston','pubavo1.wr.usgs.gov',16022);
            chanInfo = ChannelTag.array('AV.REF.--.EHZ');

            w = waveform(ds, chanInfo, now-1, now-0.995);

            % Winston often returns empty for unavailable channels,
            % so we do not assert nonempty – only that the call works.
            testCase.verifyClass(w,'waveform');
        end
    end

end