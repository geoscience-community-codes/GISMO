classdef test_metadata_classes < matlab.unittest.TestCase
    % TEST_METADATA_CLASSES
    % Combined test suite for:
    %   • ChannelDetails
    %   • ChannelTag
    %   • scnlobject
    %
    % All tests requiring IRIS/FDSN metadata will be skipped automatically
    % if the service is not reachable.

    properties (Constant)
        ANMO = 'IU.ANMO.00.BHZ';
        ANTO = 'IU.ANTO.00.BHZ';
        TestDate = '2015-10-21';
    end

    properties
        irisAvailable = false
    end

    %% --------------------------------------------------------------------
    methods (TestClassSetup)
        function checkIrisAvailability(testCase)
            % Detect whether IRIS DMC web services work
            try
                ds = datasource("irisdmcws");
                % Try a minimal metadata fetch
                Ch = ChannelDetails.retrieve(ds, testCase.ANMO);
                if ~isempty(Ch)
                    testCase.irisAvailable = true;
                end
            catch
                testCase.irisAvailable = false;
            end
        end
    end

    %% --------------------------------------------------------------------
    %  CHANNELDETAILS TEST
    %% --------------------------------------------------------------------
    methods (Test)
        function Test_ChannelDetails_Retrieve(testCase)
            testCase.assumeTrue(testCase.irisAvailable, ...
                "IRIS unavailable — skipping ChannelDetails tests.");

            ANMO = testCase.ANMO;
            ANTO = testCase.ANTO;

            % --- Retrieve using explicit NSLC fields
            cdKey = ChannelDetails.retrieve( ...
                [], ...
                'station','ANMO', ...
                'channel','BHZ', ...
                'location','00', ...
                'network','IU', ...
                'starttime', testCase.TestDate );

            testCase.assertLength(cdKey, 1);
            testCase.assertEqual(cdKey.channelinfo, ChannelTag(ANMO));

            % Basic known metadata
            testCase.assertEqual(cdKey.samplerate, 20);
            testCase.assertEqual(cdKey.elevation, 1671);
            testCase.assertEqual(cdKey.depth, 145);

            testCase.assertEqual(cdKey.azimuth, 0);
            testCase.assertEqual(cdKey.dip, -90);

            % Sensor description and scale
            testCase.assertEqual(cdKey.sensordescription, ...
                "Geotech KS-54000 Borehole Seismometer");
            testCase.assertEqual(cdKey.scalefreq, 0.0200);
            testCase.assertEqual(cdKey.scaleunits, "M/S");

            % Time sanity checks
            testCase.assertEqual(datestr(cdKey.starttime), ...
                "17-Dec-2014 18:40:00");
            testCase.assertGreaterThan(cdKey.endtime, cdKey.starttime);

            % --- Retrieve using NSLC string
            ch = ChannelDetails.retrieve([], ANMO);
            testCase.verifyEqual(ch(end), cdKey);

            % --- Retrieve using ChannelTag
            tg = ChannelTag(ANMO);
            ch2 = ChannelDetails.retrieve([], tg);
            testCase.verifyEqual(ch2(end), cdKey);

            % --- Retrieve 2×2 tag matrix
            tg2 = ChannelTag({ANMO, ANTO});
            mat = [tg2; tg2];
            C = ChannelDetails.retrieve([], mat);
            testCase.verifySize(C,[2 2]);

            % --- Retrieve from SeismicTrace
            T = SeismicTrace;
            T.name = ANMO;
            T.start = datenum(testCase.TestDate);

            ch3 = ChannelDetails.retrieve([], T);
            testCase.verifyEqual(ch3, cdKey);

            % --- Matrix of traces
            C2 = ChannelDetails.retrieve([], [T T; T T]);
            testCase.verifySize(C2, [2 2]);
        end
    end


    %% --------------------------------------------------------------------
    %  CHANNELTAG TESTS
    %% --------------------------------------------------------------------
    methods (Test)
        function Test_ChannelTag_Constructors(testCase)
            ref = test_metadata_classes.refCT('A','B','C','D');
            testCase.verifyEqual(ref, ChannelTag("A","B","C","D"));
            testCase.verifyEqual(ChannelTag(ref), ref);
            testCase.verifyEqual(ChannelTag('A.B.C.D'), ref);
            testCase.verifyEqual(ref, ChannelTag({'A.B.C.D'}));
        end

        function Test_ChannelTag_Whitespace(testCase)
            ref = test_metadata_classes.refCT('A','B','C','D');
            ct = ChannelTag('  A .B . C. D ');
            testCase.verifyEqual(ref, ct);

            ct = ChannelTag(' A ', ' B ', ' C ', ' D ');
            testCase.verifyEqual(ref, ct);
        end

        function Test_ChannelTag_Array(testCase)
            ref = test_metadata_classes.refCT('A','B','C','D');
            ct = ChannelTag.array({'A.B.C.D ',' A.B.C.D'});
            testCase.verifyEqual(ct(1), ref);
        end

        function Test_ChannelTag_EqNe(testCase)
            A = test_metadata_classes.refCT('NW','STA','LOC','CHA');
            B = test_metadata_classes.refCT('NW','STA','LOC','CHA');
            C = test_metadata_classes.refCT('NW','STA','LOC','CHB');

            testCase.verifyTrue(A == B);
            testCase.verifyTrue(eq(A,B));
            testCase.verifyFalse(A == C);
            testCase.verifyTrue(A ~= C);
        end

        function Test_ChannelTag_StringConversions(testCase)
            nslc = "IU.ANMO.00.LOG";
            ct = ChannelTag(nslc);
            testCase.verifyEqual(ct.string(), nslc);
            testCase.verifyEqual(ct.string('_'), "IU_ANMO_00_LOG");
            testCase.verifyEqual(ct.char(), char(nslc));
        end
    end


    %% --------------------------------------------------------------------
    %  SCNLOBJECT TESTS
    %% --------------------------------------------------------------------
    methods (Test)
        function Test_Scnl_Constructors(testCase)
            ref = test_metadata_classes.refSCNL('N','S','L','C');
            testCase.verifyEqual(ref, scnlobject('S','C','N','L'));
            testCase.verifyEqual(scnlobject('N.S.L.C'), ref);
            testCase.verifyEqual(ref, scnlobject({'N.S.L.C'}));
        end

        function Test_Scnl_Whitespace(testCase)
            ref = test_metadata_classes.refSCNL('N','S','L','C');
            ct = scnlobject(' N .S . L. C ');
            testCase.verifyEqual(ref, ct);
        end

        function Test_Scnl_Array(testCase)
            ref = test_metadata_classes.refSCNL('N','S','L','C');
            ct = scnlobject({'N.S.L.C','N.S.L.C'});
            testCase.verifyEqual(ct(1), ref);
        end

        function Test_Scnl_EqNe(testCase)
            A = test_metadata_classes.refSCNL('NW','STA','LOC','CHA');
            B = test_metadata_classes.refSCNL('NW','STA','LOC','CHA');
            C = test_metadata_classes.refSCNL('NW','STA','LOC','CHB');

            testCase.verifyTrue(A == B);
            testCase.verifyFalse(A == C);
        end

        function Test_Scnl_StringConversions(testCase)
            ct = scnlobject('IU.ANMO.00.LOG');
            str = get(ct,'nscl_string');
            testCase.verifyEqual(str,'IU_ANMO_LOG_00');
        end

        function Test_Scnl_ismember(testCase)
            A = scnlobject('N.S.L.C');
            B = scnlobject('N1.S1.L1.C1');

            testCase.verifyTrue(ismember(A,[A A B]));
        end
    end

    %% --------------------------------------------------------------------
    %  Static helpers
    %% --------------------------------------------------------------------
    methods (Static)
        function obj = refCT(N,S,L,C)
            obj = ChannelTag();
            obj.network = N;
            obj.station = S;
            obj.location = L;
            obj.channel = C;
        end

        function obj = refSCNL(N,S,L,C)
            obj = scnlobject();
            obj = set(obj,'network',N,'station',S,'channel',C,'location',L);
        end
    end

end