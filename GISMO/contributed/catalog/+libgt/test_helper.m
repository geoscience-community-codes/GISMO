% TEST_HELPER
function test_helper(str)
            persistent testNum;
            if isempty(testNum)
                testNum = 1;
            else
                testNum = testNum + 1;
            end
            disp(sprintf('\nTest: %d\n%s',testNum, str));
            eval(str);
            i = input('<ENTER> to continue');
end