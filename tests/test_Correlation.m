classdef test_Correlation < matlab.unittest.TestCase
   %UNTITLED Summary of this class goes here
   %   Detailed explanation goes here
   
   properties
   end
   
   methods(Test)
      
      % Cases for adjusttrig
      function TestAdjustTrigDefaults(testCase)
         c = correlation.demo();
         c = c.adjustrig();
      end
      function TestAdjustTrigTimeshift(testCase)
         c = correlation.demo();
         c = c.adjustrig('index', 10);
      end
      function TestAdjustTrigMin(testCase)
         c = correlation.demo();
         c = c.adjustrig('min');
      end
      function TestAdjustTrigMedian(testCase)
         c = correlation.demo();
         c = c.adjustrig('median');
      end
      function TestAdjustTrigMaxLag(testCase)
         c = correlation.demo();
         c = c.adjustrig('min', 1);
      end
      function TestAdjustTrigIndex(testCase)
         c = correlation.demo();
         c = c.adjustrig('index');
      end
      function TestAdjustTrigIndexRelativeToSpecificTrace(testCase)
         c = correlation.demo();
         c = c.adjustrig('index', 10);
      end
      function TestAdjustTrigLeastSquares(testCase)
         c = correlation.demo();
         c = c.adjustrig('lsq');
         
         % TEST RESULT
      end
      
      % tests for agc
      function TestAutoGainControl(testCase)
      end
      function TestAlign(testCase)
      end
      function testButter(testCase)
      end
      function testCat(testCase)
      end
      function testCheck(testCase)
      end
      function testCluster(testCase)
      end
      function testColormap(testCase)
      end
      function testConv(testCase)
      end
      function testCrop(testCase)
      end
      function testDeconv(testCase)
      end
      function testDemean(testCase)
      end
      function testDetrend(testCase)
      end
      function testDiff(testCase)
      end
      function testFind(testCae)
      end
      
   end
end
