classdef test_threecomp < matlab.unittest.TestCase
    % TEST_THREECOMP
    %
    % CI-safe smoke test for the THREECOMP cookbook.

    methods (Test)

        function test_runThreecompCookbook(testCase)

            mc = meta.class.fromName('threecomp');
            testCase.assertNotEmpty(mc, 'threecomp class not found');

            close all force

            try
                threecomp.cookbook();
            catch ME
                fprintf(2,'\n--- THREECOMP Cookbook Failure ---\n%s\n', ...
                    ME.getReport('extended'));
                testCase.verifyFail(ME.message);
            end

            figs = get(0,'Children');
            testCase.verifyGreaterThanOrEqual(numel(figs), 1, ...
                'threecomp cookbook produced no figures');

        end
    end
end
