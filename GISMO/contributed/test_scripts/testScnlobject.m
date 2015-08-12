classdef testScnlobject < TestCase
   % testScnlobject validates the funcionality of scnlobject
   %
   % requires xUnit 
   % see also xUnit, scnlobject
   
   properties
   end
   methods
      function self = testScnlobject(name)
         self = self@TestCase(name);
      end
      
      function SetUp(self)
         %nothing to set up
      end
      
      %---- test methods follow. each starts with "test" ---
      function testSimpleConstructors(self)
         % make sure these throw no error
         reftag = testScnlobject.createReference('N','S','L','C');
         assert(reftag == scnlobject('S', 'C', 'N', 'L'));  % 4 string constructor
         ct2 = reftag;
         assertEqual(ct2, reftag);              % copy constructor
         assertEqual(scnlobject('N.S.L.C'), reftag);           % string constructor
         assertEqual(reftag,scnlobject({'N.S.L.C'}));         % cell constructor
      end
      
      function testWhitespaceConstructors(self)
         reftag = testScnlobject.createReference('N','S','L','C');
         ct = scnlobject('  N .S . L. C ');
         assertEqual(reftag, ct);
         ct = scnlobject(' S ', ' C ', ' N ', ' L ');
         assertEqual(reftag, ct);
      end
      
      function testArrayConstruction(self)
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
      
      function testEqNe(self)
         A = testScnlobject.createReference('NW','STA','LOC','CHA');
         B = testScnlobject.createReference('NW','STA','LOC','CHA');
         C = testScnlobject.createReference('NW','STA','LOC','CHAN');
         assertTrue(eq(A, B));
         assertTrue(A == B);
         assertFalse(A == C);
      end
      
      %{
      function testSort(self)
         % unimiplemented by scnlobject
         ct = scnlobject('S',{'CCC','BBB','AAA'},'A','L');
         s = sort(ct);
         assert(strcmp(s(1).channel,'AAA'));
         assert(strcmp(s(3).channel, 'CCC'));
         ct = scnlobject('S',{'C1','C2'},{'N2','N1'},'L');
         s = sort(ct);
         assert(strcmp(s(1).network,'N1') && strcmp(s(1).channel,'C2'));
         assert(strcmp(s(2).network,'N2') && strcmp(s(2).channel,'C1'));
      end
      %}
      
      function testStringConversions(self)
         nslc = 'IU.ANMO.00.LOG';
         ct = scnlobject(nslc);
         assert(strcmp(get(ct,'string'),nslc));               % test basic string
         %assert(strcmp(ct.string('_'),'IU_ANMO_00_LOG')); % test delimeter
         %assert(strcmp(ct.char(),ct.string()));          % test string vs char
      end
      
      function testIsmember(self)
         % not implemented
      end
      function  testMatching(self)
         % not implemented
      end
   end
   
   methods(Static)
      function obj = createReference(N, S, L, C)
         obj = scnlobject();
         obj = set(obj,'network',N,'station',S,'channel',C,'location',L);
      end
   end
end
