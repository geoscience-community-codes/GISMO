classdef testChanneltag < matlab.unittest.TestCase
   % TESTCHANNELTAG validates the funcionality of channeltag
   %
   % requires xUnit 
   % see also xUnit, channeltag
   
   properties
   end
   methods(Test)
      %---- test methods follow. each starts with "test" ---
      function testSimpleConstructors(self)
         % make sure these throw no error
         reftag = testChanneltag.createReference('A','B','C','D');
         self.verifyEqual(reftag, channeltag('A', 'B', 'C', 'D'));  % 4 string constructor
         self.verifyEqual(channeltag(reftag), reftag);              % copy constructor
         self.verifyEqual(channeltag('A.B.C.D'), reftag);           % string constructor
         self.verifyEqual(reftag, channeltag({'A.B.C.D'}));         % cell constructor
      end
      
      function testWhitespaceConstructors(self)
         reftag = testChanneltag.createReference('A','B','C','D');
         ct = channeltag('  A .B . C. D ');
         self.verifyEqual(reftag, ct);
         ct = channeltag(' A ', ' B ', ' C ', ' D ');
         self.verifyEqual(reftag, ct);
      end
      
      function testArrayConstruction(self)
         reftag = testChanneltag.createReference('A','B','C','D');
         ct = channeltag.array({'A .B . C. D ',' A. B . C.D '});
         self.verifyEqual(reftag, ct(1));
         self.verifyEqual(ct(1), ct(2));
         ct = channeltag.array(['A.B.C.D      '; ' A.B  . C . D']);
         self.verifyEqual(reftag, ct(1));
         self.verifyEqual(ct(1), ct(2));
         ct = channeltag.array({'N','N','N'},{'S','S','S'},{'L','L','L'}, {'C','C','C'});
         self.verifyEqual(ct(1), ct(2))
         self.verifyEqual(ct(2), ct(3));
         ct = channeltag.array(['N.S.L.C ';' N.S.L.C'; 'N.S .L.C']);
         self.verifyEqual(ct(1), ct(2))
         self.verifyEqual(ct(2), ct(3));
         ct = channeltag.array('N',{'S1','S2'},'L','C');
         self.verifyEqual(ct(1).station,'S1');
         self.verifyEqual(ct(2).station, 'S2');
      end
      
      function testEqNe(self)
         A = testChanneltag.createReference('NW','STA','LOC','CHA');
         B = testChanneltag.createReference('NW','STA','LOC','CHA');
         C = testChanneltag.createReference('NW','STA','LOC','CHAN');
         self.verifyTrue(eq(A,B));
         self.verifyTrue(eq(B,A));
         self.verifyTrue(A == B);
         self.verifyFalse(ne(A,B));
         
         self.verifyTrue(ne(A,C));
         self.verifyFalse(eq(A,C));
         self.verifyTrue(A ~=C);
      end
      
      function testSort(self)
         ct = channeltag.array('A','S','L',{'CCC','BBB','AAA'});
         s = sort(ct);
         self.verifyEqual(s(1).channel,'AAA');
         self.verifyEqual(s(3).channel, 'CCC');
         ct = channeltag.array({'N2','N1'},'S','L',{'C1','C2'});
         s = sort(ct);
         self.verifyEqual(s(1).network,'N1');
         self.verifyEqual(s(1).channel,'C2');
         self.verifyEqual(s(2).network,'N2');
         self.verifyEqual(s(2).channel,'C1');
      end
      
      function testStringConversions(self)
         nslc = 'IU.ANMO.00.LOG';
         ct = channeltag(nslc);
         self.verifyEqual(ct.string(),nslc);               % test basic string
         self.verifyEqual(ct.string('_'),'IU_ANMO_00_LOG'); % test delimeter
         self.verifyEqual(ct.char(),ct.string());          % test string vs char
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
