classdef test_metadata_classes < matlab.unittest.TestCase
    % TEST_METADATA_CLASSES (CORE ONLY)
    % Tests only core metadata classes:
    %   • ChannelTag
    %   • scnlobject
    %
    % NO dev/, NO network, NO IRIS dependencies.

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
            nslc = "IU.ANMO.00.EHZ";
            ct = ChannelTag(nslc);
            testCase.verifyEqual(ct.string(), nslc);
            testCase.verifyEqual(ct.string('_'), "IU_ANMO_00_EHZ");
            %testCase.verifyEqual(ct.char(), char(nslc));
            testCase.verifyEqual(string(ct), nslc);

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
            A = scnlobject('NW','STA','LOC','CHA');
            B = scnlobject('NW','STA','LOC','CHA');
            C = scnlobject('NW','STA','LOC','CHB');

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
