classdef testChanneltag < TestCase
   % TESTCHANNELTAG validates the funcionality of channeltag
   %
   % requires xUnit 
   % see also xUnit, channeltag
   
   properties
   end
   methods
      function self = testChanneltag(name)
         self = self@TestCase(name);
      end
      
      function SetUp(self)
         %nothing to set up
      end
      
      %---- test methods follow. each starts with "test" ---
      function testSimpleConstructors(self)
         % make sure these throw no error
         reftag = testChanneltag.createReference('A','B','C','D');
         assert(reftag == channeltag('A', 'B', 'C', 'D'));  % 4 string constructor
         assert(channeltag(reftag) == reftag);              % copy constructor
         assert(channeltag('A.B.C.D') == reftag);           % string constructor
         assert(reftag == channeltag({'A.B.C.D'}));         % cell constructor
      end
      
      function testWhitespaceConstructors(self)
         reftag = testChanneltag.createReference('A','B','C','D');
         ct = channeltag('  A .B . C. D ');
         assert(reftag == ct);
         ct = channeltag(' A ', ' B ', ' C ', ' D ');
         assert(reftag == ct);
      end
      
      function testArrayConstruction(self)
         reftag = testChanneltag.createReference('A','B','C','D');
         ct = channeltag.array({'A .B . C. D ',' A. B . C.D '});
         assert(reftag == ct(1));
         assert(ct(1) == ct(2));
         ct = channeltag.array(['A.B.C.D      '; ' A.B  . C . D']);
         assert(reftag == ct(1));
         assert(ct(1) == ct(2));
         ct = channeltag.array({'N','N','N'},{'S','S','S'},{'L','L','L'}, {'C','C','C'});
         assert (ct(1) == ct(2) && ct(2) == ct(3));
         ct = channeltag.array(['N.S.L.C ';' N.S.L.C'; 'N.S .L.C']);
         assert(ct(1) == ct(2) && ct(2) == ct(3));
         ct = channeltag.array('N',{'S1','S2'},'L','C');
         assert(strcmp(ct(1).station,'S1') && strcmp(ct(2).station, 'S2'));
      end
      
      function testEqNe(self)
         A = testChanneltag.createReference('NW','STA','LOC','CHA');
         B = testChanneltag.createReference('NW','STA','LOC','CHA');
         C = testChanneltag.createReference('NW','STA','LOC','CHAN');
         assert(eq(A,B));
         assert(A == B);
         assert(ne(A,C));
         assert(A ~=C);
      end
      
      function testSort(self)
         ct = channeltag.array('A','S','L',{'CCC','BBB','AAA'});
         s = sort(ct);
         assert(strcmp(s(1).channel,'AAA'));
         assert(strcmp(s(3).channel, 'CCC'));
         ct = channeltag.array({'N2','N1'},'S','L',{'C1','C2'});
         s = sort(ct);
         assert(strcmp(s(1).network,'N1') && strcmp(s(1).channel,'C2'));
         assert(strcmp(s(2).network,'N2') && strcmp(s(2).channel,'C1'));
      end
      
      function testStringConversions(self)
         nslc = 'IU.ANMO.00.LOG';
         ct = channeltag(nslc);
         assert(strcmp(ct.string(),nslc));               % test basic string
         assert(strcmp(ct.string('_'),'IU_ANMO_00_LOG')); % test delimeter
         assert(strcmp(ct.char(),ct.string()));          % test string vs char
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
         obj = channeltag();
         obj.network = N; 
         obj.station = S; 
         obj.location = L;
         obj.channel = C;
      end
   end
end
