classdef test_rsam < matlab.unittest.TestCase

    methods (Test)
        function test_runRSAMCookbook(testCase)

            mc = meta.class.fromName('rsam');
            testCase.assertNotEmpty(mc,'rsam class not found');

            close all force

            try
                rsam.cookbook();
            catch ME
                fprintf(2,'\n--- RSAM Cookbook Failure ---\n%s\n', ...
                    ME.getReport('extended'));
                testCase.verifyFail(ME.message);
            end

            figs = get(0,'Children');
            testCase.verifyGreaterThanOrEqual(numel(figs), 1, ...
                'RSAM cookbook produced no figures');

        end
    end
end
