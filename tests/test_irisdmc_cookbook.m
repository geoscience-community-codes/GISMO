classdef test_irisdmc_cookbook < matlab.unittest.TestCase
    % TEST_IRISDMC_COOKBOOK
    %
    % Legacy contributed cookbook smoke test.
    % Skipped automatically for unsupported MATLAB versions or
    % when IRIS / Java libraries are unavailable.

    methods (Test)
        function test_runIrisdmCCookbook(testCase)

            % --- MATLAB version guard -----------------------------
            v = ver('MATLAB');
            rel = regexp(v.Release,'\d{4}[ab]','match','once');
            if str2double(rel(1:4)) >= 2023
                testCase.assumeFail( ...
                    'Skipping irisdmc cookbook: not supported on MATLAB >= R2023a');
            end

            % --- Package existence (PACKAGE-SAFE, RELIABLE) --------------------------
            cbfun = which('irisdmc.station_meta');
            if isempty(cbfun)
                testCase.assumeFail('Skipping: irisdmc package not on path.');
            end

            % --- irisFetch presence --------------------------------
            if exist('irisFetch','file') ~= 2
                testCase.assumeFail('Skipping: irisFetch not on path.');
            end

            % --- Cookbook existence --------------------------------
            cbfun = which('irisdmc.cookbook');
            testCase.assertNotEmpty(cbfun, 'irisdmc.cookbook not found');

            try
                close all;
                irisdmc.cookbook();   % ✅ correct invocation

            catch ME
                warning('irisdmc cookbook failed:\n%s', ME.message);
                testCase.verifyFail(ME.message);
            end
        end
    end
end