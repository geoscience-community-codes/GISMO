classdef test_TraceData < matlab.unittest.TestCase
   %testTraceData tests the TraceData class
   %   Detailed explanation goes here
   
   properties
   end
   methods(Static)
      function T = makeTraceData(data_, samplerate_, units_)
         T = TraceData;
         T.data = data_;
         T.samplerate = samplerate_;
         T.units = units_;
      end
      
   end
   methods(Test)
      function testConstructors(testCase)
      end
      function test_data(testCase)
         import matlab.unittest.constraints.IsEmpty;
         T = TraceData;
         testCase.verifyThat(T.data, IsEmpty, ...
            'default data should be empty');
         testdata = [1 2 3 -inf inf 0];
         T.data = testdata;
         testCase.verifyEqual(T.data, testdata(:));
      end
      function test_samplerate(testCase)
         T = TraceData;
         T.samplerate = 10;
         testCase.verifyEqual(T.samplerate, 10);
      end
      function test_duration(testCase)
         simpledata = [1 2 3 -inf inf nan 0];
         T = test_TraceData.makeTraceData(simpledata, 1, 'counts');
         testCase.verifyEqual(T.duration, numel(simpledata));
         T.samplerate = numel(simpledata);
         testCase.verifyEqual(T.duration, 1);
         T.data = [];
         testCase.verifyEqual(T.duration, 0);
         T.data = nan;
         testCase.verifyEqual(T.duration, 1/numel(simpledata));
      end
      function test_eq(testCase)
         simpledata = [1 2 3 -inf inf 0];
         A = test_TraceData.makeTraceData(simpledata, 1, 'counts');
         B = test_TraceData.makeTraceData(simpledata, 1, 'counts');
         testCase.assumeEqual(A.data, B.data);
         testCase.assumeEqual(A.samplerate, B.samplerate);
         testCase.assumeEqual(A.units, B.units);
         testCase.verifyTrue(A == B);
         testCase.verifyFalse(A ~= B);
         testCase.verifyTrue(-A ~= B);
      end
      function test_units(testCase)
         T = TraceData;
         T.units = 'abc';
         testCase.verifyEqual(T.units, 'abc');
      end
      function test_uminus(testCase)
         simpledata=[-inf -5 0 10 20.05 inf];
         T = test_TraceData.makeTraceData(simpledata, 5, 'counts');
         testCase.verifyEqual(-simpledata(:), -T.data);
         testCase.verifyEqual(-(-(-T)), -T);
      end
      function test_plus(testCase)
         simpledata = (-1:.2:10)';
         T = test_TraceData.makeTraceData(simpledata, 1, 'counts');
         % tests for a single TraceData
         Ta = T + 0;
         testCase.assertEqual(Ta.data, simpledata);
         Ta = T + 1.23;
         testCase.assertEqual(Ta.data, simpledata + 1.23);
         Ta = T + T.data;
         testCase.verifyEqual(Ta.data, 2*simpledata);
         testCase.verifyEqual(T+T.data+T.data, test_TraceData.makeTraceData(3 * simpledata, 1, 'counts'));
         % TODO: tests for multiple TraceDatas
         T2 = [T; T];
         T2 = T2 + 4;
         testCase.verifySize(T2,[2,1]);
         testCase.assumeEqual([T2.samplerate],[1;1]);
         testCase.verifyEqual(T2(1).data, T2(2).data);
         testCase.verifyEqual(T2(1).data, simpledata(:) + 4);
         T2 = [T, T];
         testCase.verifySize(T2,[1,2]);
         testCase.assumeEqual([T2.samplerate],[1;1]);
         testCase.verifyEqual(T2(1), T2(2));
         testCase.verifyEqual(T2(1).data, simpledata(:) + 4);
         Ta = T + T.data;
         TestCase.verifyEqual(Ta, T + T.data);
         
      end
      function testMinus(testCase)
         simpledata = [1 2 3 -inf inf 0];
         T = test_TraceData.makeTraceData(simpledata, 10, 'counts');
         T2 = T - 5;
         testCase.verifyEqual(T + (-5), T2);
      end
      function test_times(testCase)
         simpledata = [1 2 3 -inf inf 0];
         T = test_TraceData.makeTraceData(simpledata, 10, 'counts');
         testCase.verifyEqual(T + T.data, T .* 2);
      end
      function test_mtimes(testCase)
         
      end
      function test_pow(testCase)
         simpledata = [1 2 3 -inf inf 0];
         powT = test_TraceData.makeTraceData(simpledata .^ 3.5, 10, 'counts');
         T = test_TraceData.makeTraceData(simpledata, 10, 'counts');
         testCase.verifyEqual(T .^ 2, T .* T.data);
         testCase.verifyEqual(T .^ 3.5, powT);
      end
   end
   
end

