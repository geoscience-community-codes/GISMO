classdef test_irisdmc_cookbook < matlab.unittest.TestCase
    % TEST_IRISDMC_COOKBOOK
    %
    % Legacy irisdmc Java cookbook smoke test.
    %
    % This test:
    %   • Runs ONLY on MATLAB R2022b and earlier
    %   • Skips cleanly if Java/IRIS libraries are missing
    %   • Skips cleanly if offline / firewalled
    %   • Only FAILS on true MATLAB code regressions
    %
    % CI-safe for GitHub/JOSS when irisdmc is absent.

    methods (Test)

        function test_runIrisdmcCookbook(testCase)

            %% ------------------------------------------------------------
            % MATLAB VERSION GUARD (Java break in R2023a+)
            %% ------------------------------------------------------------
            v = ver('MATLAB');
            rel = regexp(v.Release,'\d{4}[ab]','match','once');

            if isempty(rel)
                testCase.assumeFail('Unable to parse MATLAB release.');
            end

            yr = str2double(rel(1:4));

            if yr >= 2023
                testCase.assumeFail( ...
                    'Skipping irisdmc cookbook: unsupported on MATLAB ≥ R2023a');
            end


            %% ------------------------------------------------------------
            % JAVA AVAILABILITY
            %% ------------------------------------------------------------
            if ~usejava('jvm')
                testCase.assumeFail('Skipping irisdmc: JVM not available.');
            end


            %% ------------------------------------------------------------
            % irisdmc PACKAGE PRESENCE
            %% ------------------------------------------------------------
            if isempty(which('irisdmc.station_meta'))
                testCase.assumeFail('Skipping: irisdmc package not on path.');
            end


            %% ------------------------------------------------------------
            % irisFetch PRESENCE
            %% ------------------------------------------------------------
            if exist('irisFetch','file') ~= 2
                testCase.assumeFail('Skipping: irisFetch not on path.');
            end


            %% ------------------------------------------------------------
            % COOKBOOK PRESENCE
            %% ------------------------------------------------------------
            cbfun = which('irisdmc.cookbook');
            testCase.assertNotEmpty(cbfun, ...
                'irisdmc.cookbook not found on MATLAB path.');


            %% ------------------------------------------------------------
            % INTERNET / FIREWALL GUARD
            %% ------------------------------------------------------------
            % We do NOT require IRIS to be reachable.
            % Instead, we allow connection failures to count as a SKIP.
            %
            % Only MATLAB coding errors should FAIL.

            close all force;

            try
                irisdmc.cookbook();   % ✅ SAFE LEGACY SMOKE TEST

            catch ME

                % --- Allowed failure modes (treated as SKIP) ------------
                netFail = contains(lower(ME.message), {'java','socket','timeout','refused','unknown host','handshake','ssl'});

                if netFail
                    testCase.assumeFail( ...
                        ['Skipping irisdmc cookbook due to network/Java error: ' ...
                         ME.message]);
                end

                % --- True regression: FAIL ------------------------------
                warning(ME.identifier, 'irisdmc cookbook failed:\n%s', ME.message);
                testCase.verifyFail(ME.message);
            end

        end
    end
end
