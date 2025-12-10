classdef test_bvalue < matlab.unittest.TestCase
    % Unit tests for Catalog.bvalue
    %
    % These tests use a synthetic Gutenberg–Richter catalog
    % with known b ≈ 1.0 to validate numerical correctness.
    %
    % CI-safe: no plotting, no internet, no toolboxes required.

    methods (Test)

        function testSyntheticGRCatalog(testCase)

            % ----------------------------
            % Create synthetic GR catalog
            % ----------------------------
            rng(42);               % reproducibility
            N = 3000;              % number of events
            btrue = 1.0;           % true b-value
            Mc_true = 1.0;         % completeness magnitude
            Mmax = 5.0;

            % Inverse CDF sampling for GR distribution:
            %   P(M >= m) = 10^{-b (m - Mc)}
            u = rand(N,1);
            mag = Mc_true - (1/btrue) * log10(u);
            mag = mag(mag <= Mmax);

            % Ensure we still have enough data
            testCase.assertGreaterThan(numel(mag), 500);

            % ----------------------------
            % Build synthetic Catalog
            % ----------------------------
            ot = datenum(2020,1,1) + (0:numel(mag)-1)'/86400;
            cat = Catalog();
            cat.mag = mag(:);
            cat.otime = ot(:);

            % ----------------------------
            % Run b-value (batch-safe mode)
            % ----------------------------
            gr = cat.bvalue(0);   % runmode = 0 (no plot)

            % ----------------------------
            % Assertions
            % ----------------------------
            testCase.verifyTrue(isstruct(gr), ...
                'bvalue output must be a structure');

            testCase.verifyTrue(isfinite(gr.bvalue), ...
                'bvalue must be finite');

            testCase.verifyTrue(isfinite(gr.avalue), ...
                'avalue must be finite');

            testCase.verifyTrue(isfinite(gr.Mc), ...
                'Mc must be finite');

            testCase.verifyTrue(isfinite(gr.bvalue_error), ...
                'bvalue_error must be finite');

            % b-value accuracy (allow generous tolerance)
            testCase.verifyLessThan(abs(gr.bvalue - btrue), 0.15, ...
                sprintf('Recovered b-value %.3f deviates too far from true %.2f', ...
                gr.bvalue, btrue));

            % Mc should fall near true Mc
            testCase.verifyGreaterThanOrEqual(gr.Mc, Mc_true - 0.5);
            testCase.verifyLessThanOrEqual(gr.Mc, Mc_true + 0.5);

            % Error bar sanity
            testCase.verifyGreaterThan(gr.bvalue_error, 0);
            testCase.verifyLessThan(gr.bvalue_error, 0.5);

        end


        function testInsufficientData(testCase)

            % ----------------------------
            % Build tiny catalog (<30 events)
            % ----------------------------
            cat = Catalog();
            cat.mag   = rand(10,1);
            cat.otime = datenum(2020,1,1) + (0:9)'/86400;

            % ----------------------------
            % Verify that error is thrown
            % ----------------------------
            testCase.verifyError(@() cat.bvalue(0), ...
                'Catalog:bvalue:InsufficientData');

        end


        function testNoPlotDoesNotCreateFigures(testCase)

            % ----------------------------
            % Small but valid synthetic catalog
            % ----------------------------
            rng(1);
            mag = 1 + rand(200,1);
            ot  = datenum(2020,1,1) + (0:199)'/86400;

            cat = Catalog();
            cat.mag   = mag;
            cat.otime = ot;

            % ----------------------------
            % Count current figures
            % ----------------------------
            figsBefore = numel(findall(0,'Type','figure'));

            % ----------------------------
            % Run in batch mode
            % ----------------------------
            cat.bvalue(0);

            % ----------------------------
            % Verify no new figures
            % ----------------------------
            figsAfter = numel(findall(0,'Type','figure'));

            testCase.verifyEqual(figsAfter, figsBefore, ...
                'bvalue(runmode=0) must not create figures');

        end
    end
end
