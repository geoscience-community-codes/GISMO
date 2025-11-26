classdef test_Response_cookbook < matlab.unittest.TestCase
    % TEST_RESPONSE_COOKBOOK
    %
    % Smoke test for the Response cookbook.
    % Ensures that the tutorial executes without fatal errors.
    % External services (Antelope) are OPTIONAL and skipped automatically.

    methods (Test)
        function test_runResponseCookbook(testCase)

            % --- Locate cookbook -----------------------------------------
            cb = which('Response.cookbook');
            testCase.assertNotEmpty(cb, ...
                '@Response/cookbook.m not found on path');

            % --- Run cookbook safely -------------------------------------
            try
                close all;
                Response.cookbook();
            catch ME
                warning('Response cookbook crashed:\n%s', ME.message);
                testCase.verifyFail(ME.message);
            end
        end
    end
end