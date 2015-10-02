classdef testScnlobject < matlab.unittest.TestCase
   % testScnlobject validates the funcionality of scnlobject using matlab's
   % built in unit tests
 
   methods (Test)
      %---- test methods follow. each starts with "test" ---
      function testSimpleConstructors(testCase)
         % make sure these throw no error
         reftag = testScnlobject.createReference('N','S','L','C');
         assert(reftag == scnlobject('S', 'C', 'N', 'L'));  % 4 string constructor
         ct2 = reftag;
         assertEqual(ct2, reftag);              % copy constructor
         assertEqual(scnlobject('N.S.L.C'), reftag);           % string constructor
         assertEqual(reftag,scnlobject({'N.S.L.C'}));         % cell constructor
      end
      
      function testWhitespaceConstructors(testCase)
         reftag = testScnlobject.createReference('N','S','L','C');
         ct = scnlobject('  N .S . L. C ');
         assertEqual(reftag, ct);
         ct = scnlobject(' S ', ' C ', ' N ', ' L ');
         assertEqual(reftag, ct);
      end
      
      function testArrayConstruction(testCase)
         reftag = testScnlobject.createReference('N','S','L','C');
         ct = scnlobject({'N .S . L. C ',' N. S . L.C '});
         assertEqual(reftag, ct(1));
         assertEqual(ct(1), ct(2));
         ct = scnlobject(['N.S.L.C      '; ' N.S  . L . C']);
         assertEqual(reftag, ct(1));
         assertEqual(ct(1), ct(2));
         ct = scnlobject({'S','S','S'},{'C','C','C'}, {'N','N','N'}, {'L','L','L'} );
         assertEqual(ct(1), ct(2));
         assertEqual(ct(2), ct(3));
         ct = scnlobject(['N.S.L.C ';' N.S.L.C'; 'N.S .L.C']);
         assertEqual(ct(1), ct(2));
         assertEqual(ct(2), ct(3));
         ct = scnlobject({'S1','S2'},'C','N','L');
         assertEqual(get(ct(1),'station'),'S1')
         assertEqual(get(ct(2),'station'), 'S2');
      end
      
      function testEqNe(testCase)
         A = testScnlobject.createReference('NW','STA','LOC','CHA');
         B = testScnlobject.createReference('NW','STA','LOC','CHA');
         C = testScnlobject.createReference('NW','STA','LOC','CHAN');
         assertTrue(eq(A, B));
         assertTrue(A == B);
         assertFalse(A == C);
      end
      
      function testStringConversions(testCase)
         nslc = 'IU.ANMO.00.LOG';
         ct = scnlobject(nslc);
         assertEqual(get(ct,'nscl_string'),'IU_ANMO_LOG_00');
      end
      
      function testIsmember(testCase)
         A = scnlobject('N.S.L.C');
         B = scnlobject('N1.S1.L1.C1');
         C = scnlobject('N2.S2.L2.C2');
         assertEqual(ismember(A,[A, A, B]), true)
         assertEqual(ismember([A, A, B],A), [true true false]);
         [LTA, LTB]   = ismember([A A B C],  [A scnlobject() B; B scnlobject() scnlobject()]);
         [NumA, NumB] = ismember([ 1 1 2 3], [1 0 2;2 0 0]);
         assertEqual(LTA, NumA)
         assertEqual(LTB, NumB)
      end
      
      function  testMatching(testCase)
         wildcardString = '*.*.*.*';
         A = scnlobject('N.S.L.C');
         B = scnlobject('N1.S1.L1.C1');
         % C = scnlobject('N2.S2.L2.C2');
         W = scnlobject(wildcardString);
         assertTrue(ismember(scnlobject,wildcardString), 'Wildcards are not recognized');
         assertExceptionThrown(@() ismember(A,B),'somexception')
         assertTrue(ismember(A,W))
         assertEqual(ismember([A, A, B],W), [true true true]);
         assertTrue(ismember(A, [A A W]));
      end
   end
   
   methods(Static)
      function obj = createReference(N, S, L, C)
         obj = scnlobject();
         obj = set(obj,'network',N,'station',S,'channel',C,'location',L);
      end
   end
end
