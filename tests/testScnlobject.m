classdef testScnlobject < matlab.unittest.TestCase
   % testScnlobject validates the funcionality of scnlobject using matlab's
   % built in unit tests
 
   methods (Test)
      %---- test methods follow. each starts with "test" ---
      function testSimpleConstructors(testCase)
         % make sure these throw no error
         reftag = testScnlobject.createReference('N','S','L','C');
         testCase.verifyEqual(reftag,scnlobject('S', 'C', 'N', 'L'));  % 4 string constructor
         ct2 = reftag;
         testCase.verifyEqual(ct2, reftag);              % copy constructor
         testCase.verifyEqual(scnlobject('N.S.L.C'), reftag);           % string constructor
         testCase.verifyEqual(reftag,scnlobject({'N.S.L.C'}));         % cell constructor
      end
      
      function testWhitespaceConstructors(testCase)
         reftag = testScnlobject.createReference('N','S','L','C');
         ct = scnlobject('  N .S . L. C ');
         testCase.verifyEqual(reftag, ct);
         ct = scnlobject(' S ', ' C ', ' N ', ' L ');
         testCase.verifyEqual(reftag, ct);
      end
      
      function testArrayConstruction(testCase)
         reftag = testScnlobject.createReference('N','S','L','C');
         ct = scnlobject({'N .S . L. C ',' N. S . L.C '});
         testCase.verifyEqual(reftag, ct(1));
         testCase.verifyEqual(ct(1), ct(2));
         ct = scnlobject(['N.S.L.C      '; ' N.S  . L . C']);
         testCase.verifyEqual(reftag, ct(1));
         testCase.verifyEqual(ct(1), ct(2));
         ct = scnlobject({'S','S','S'},{'C','C','C'}, {'N','N','N'}, {'L','L','L'} );
         testCase.verifyEqual(ct(1), ct(2));
         testCase.verifyEqual(ct(2), ct(3));
         ct = scnlobject(['N.S.L.C ';' N.S.L.C'; 'N.S .L.C']);
         testCase.verifyEqual(ct(1), ct(2));
         testCase.verifyEqual(ct(2), ct(3));
         ct = scnlobject({'S1','S2'},'C','N','L');
         testCase.verifyEqual(get(ct(1),'station'),'S1')
         testCase.verifyEqual(get(ct(2),'station'), 'S2');
      end
      
      function testEqNe(testCase)
         A = testScnlobject.createReference('NW','STA','LOC','CHA');
         B = testScnlobject.createReference('NW','STA','LOC','CHA');
         C = testScnlobject.createReference('NW','STA','LOC','CHAN');
         testCase.verifyTrue(eq(A, B));
         testCase.verifyTrue(A == B);
         testCase.verifyFalse(A == C);
      end
      
      function testStringConversions(testCase)
         nslc = 'IU.ANMO.00.LOG';
         ct = scnlobject(nslc);
         testCase.verifyEqual(get(ct,'nscl_string'),'IU_ANMO_LOG_00');
      end
      
      function testIsmember(testCase)
         A = scnlobject('N.S.L.C');
         B = scnlobject('N1.S1.L1.C1');
         C = scnlobject('N2.S2.L2.C2');
         testCase.verifyEqual(ismember(A,[A, A, B]), true)
         testCase.verifyEqual(ismember([A, A, B],A), [true true false]);
         [LTA, LTB]   = ismember([A A B C],  [A scnlobject() B; B scnlobject() scnlobject()]);
         [NumA, NumB] = ismember([ 1 1 2 3], [1 0 2;2 0 0]);
         testCase.verifyEqual(LTA, NumA)
         testCase.verifyEqual(LTB, NumB)
      end
      
      function  testMatching(testCase)
         wildcardString = '*.*.*.*';
         A = scnlobject('N.S.L.C');
         B = scnlobject('N1.S1.L1.C1');
         % C = scnlobject('N2.S2.L2.C2');
         W = scnlobject(wildcardString);
         testCase.verifyTrue(ismember(scnlobject,wildcardString), 'Wildcards are not recognized');
         testCase.verifyError(@() ismember(A,B),'somexception')
         testCase.verifyTrue(ismember(A,W))
         testCase.verifyEqual(ismember([A, A, B],W), [true true true]);
         testCase.verifyTrue(ismember(A, [A A W]));
      end
   end
   
   methods(Static)
      function obj = createReference(N, S, L, C)
         obj = scnlobject();
         obj = set(obj,'network',N,'station',S,'channel',C,'location',L);
      end
   end
end
