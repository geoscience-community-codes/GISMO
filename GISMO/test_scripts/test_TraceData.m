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
      function test_rdivide(testCase)
      end
      function test_power(testCase)
         simpledata = [1 2 3 -inf inf 0];
         powT = test_TraceData.makeTraceData(simpledata .^ 3.5, 10, 'counts');
         T = test_TraceData.makeTraceData(simpledata, 10, 'counts');
         testCase.verifyEqual(T .^ 2, T .* T.data);
         testCase.verifyEqual(T .^ 3.5, powT);
      end
      function test_min(testCase)
      end
      function test_max(testCase)
      end
      function test_median(testCase)
      end
      function test_mean(testCase)
      end
      function test_std(testCase)
      end
      function test_var(testCase)
      end
      function test_abs(testCase)
         simpledata = [1 2 3 -inf inf 0];
         T = test_TraceData.makeTraceData(simpledata, 10, 'counts');
         Tkey = test_TraceData.makeTraceData(abs(simpledata), 10, 'counts');
         testCase.verifyEqual(abs(T), Tkey);
      end
      function test_sign(testCase)
         simpledata = [1 2 3 -inf inf 0];
         T = test_TraceData.makeTraceData(simpledata, 10, 'counts');
         Tsig = test_TraceData.makeTraceData(sign(simpledata), 10, 'sign(counts)');
         testCase.verifyEqual(sign(T),Tsig);
      end
      function test_demean(testCase)
      end
      function test_integerate(testCase)
      end
      function test_diff(testCase)
      end
      function test_detrend(testCase)
         simpledata = [1 1 2 2 3 3 4 4 5 5];
         T= test_TraceData.makeTraceData(simpledata, 10, 'counts');
      end
      function test_double(testCase)
         simpledata = [1 2 3 -inf inf 0]';
         T(1) = test_TraceData.makeTraceData(simpledata, 10, 'counts');
         T(2) = -T(1);
         testCase.verifyEqual(double(T(1)), simpledata);
         testCase.verifyEqual(double(T), [simpledata,-simpledata]);
      end
      function test_resample(testCase)
         simpledata = [-20 20 0 0 -1 1 3 4 10 20 -14 -12];
         T10 = test_TraceData.makeTraceData(simpledata, 10, 'counts');
         T5 = test_TraceData.makeTraceData([], 5, 'counts');
         %           'max' : maximum value
         T5.data = [20 0 1 4 20 -12];
         testCase.verifyEqual(T10.resample('max',2), T5)
         %           'min' : minimum value
         T5.data = [-20 0 -1 3 10 -14];
         testCase.verifyEqual(T10.resample('min',2), T5)
         %           'mean': average value
         T5.data = [0 0 0 3.5 15 -13];
         testCase.verifyEqual(T10.resample('mean',2), T5)
         %           'rms' : rms value (added 2011/06/01)
         %           'absmax': absolute maximum value (greatest deviation from zero)
         T5.data = [20 0 1 4 20 14];
         testCase.verifyEqual(T10.resample('absmax',2), T5)
         %           'absmin': absolute minimum value (smallest deviation from zero)
         T5.data = [20 0 1 3 10 12];
         testCase.verifyEqual(T10.resample('absmin',2), T5)
         %           'absmean' : mean deviation from zero (added 2011/06/01)
         %           'median' : median value
         T10.data = [0 0 0 3.5 -15 100 82 95 90 ]; T10.samplerate = 9;
         T5.data = [0 3.5 90];
         T5 = test_TraceData.makeTraceData(T5.data, 3, 'counts');
         testCase.verifyEqual(T10.resample('median',3), T5)
         %           'absmedian' : median deviation from zero (added 2011/06/01)
         %           'builtin': Use MATLAB's built in resample routine
      end
      function test_smooth(testCase)
         testCase.assumeEqual(exist('smooth'),2);
         error('smooth test not written');
      end
      function test_fillgaps(testCase)
      end
      function test_clip(testCase)
      end
      function stack(testCase)
      end
      function binstack(testCase)
      end
      function test_taper(testCase)
      end
      function test_hilbert(testCase)
      end
      function test_zero2nan(testCase)
      end
      function test_extract(testCase)
      end
      
   end
   
end

