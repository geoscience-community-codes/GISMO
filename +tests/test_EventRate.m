classdef test_EventRate < matlab.unittest.TestCase
    % TEST_EVENTRATE
    %
    % Unified integration + physics-based validation tests for EventRate.
    %
    % This test suite enforces:
    %   • Cookbook execution safety
    %   • Event conservation
    %   • Energy conservation
    %   • Magnitude–energy physics
    %   • Sliding window structural integrity
    %   • Empty & degenerate catalog behavior
    %   • Deterministic reproducibility
    %   • CI-safe plotting behavior (no visible figures)
    %
    % CI-SAFE:
    %   - No internet
    %   - No Antelope
    %   - No Mapping Toolbox
    %   - No TESTDATA required
    %
    % Glenn Thompson + ChatGPT, 2025

    properties
        C              % synthetic Catalog
        mags           % synthetic magnitudes
        times          % synthetic times
        binsize        % 1 hour in days
        stepsize       % 10 minutes in days
        total_energy   % true total energy from mag2eng()
    end

    %% =====================================================================
    %% COOKBOOK SMOKE TEST (INTEGRATION WRAPPER)
    %% =====================================================================
    methods (Test)
        function test_runEventRateCookbook(testCase)

            mc = meta.class.fromName('EventRate');
            testCase.assertNotEmpty(mc, 'EventRate class not found');

            methodNames = {mc.MethodList.Name};
            testCase.assertTrue(ismember('cookbook', methodNames), ...
                'EventRate.cookbook method not found');

            close all force;

            try
                EventRate.cookbook();
            catch ME
                fprintf(2, '\n--- EventRate Cookbook FAILURE ---\n');
                fprintf(2, '%s\n', ME.getReport('extended'));
                testCase.verifyFail(ME.message);
            end
        end
    end

    %% =====================================================================
    %% CLASS SETUP — LARGE DETERMINISTIC SYNTHETIC CATALOG
    %% =====================================================================
    methods (TestClassSetup)

        function makeLargeSyntheticCatalog(testCase)

            rng(42);  % deterministic reproducibility

            nEvents = 500;
            span    = 5;  % days
            t0      = datenum(2020,1,1,0,0,0);

            times = sort(t0 + span*rand(nEvents,1));
            mags  = 1 + 3*rand(nEvents,1);  % [1,4)

            lon   = zeros(nEvents,1);
            lat   = zeros(nEvents,1);
            depth = zeros(nEvents,1);

            C = Catalog(times, lon, lat, depth, mags, {}, {}, ...
                        'ontime', times, 'offtime', times);

            testCase.C             = C;
            testCase.mags          = mags;
            testCase.times         = times;
            testCase.binsize       = 1/24;      % 1 hour
            testCase.stepsize      = 10/1440;   % 10 minutes
            testCase.total_energy = sum(magnitude.mag2eng(mags));
        end
    end

    %% =====================================================================
    %% BASIC CONSTRUCTION & PERFECT CONSERVATION
    %% =====================================================================
    methods (Test)

        function TestPerfectEventAndEnergyConservation(testCase)

            binsize = testCase.binsize;

            snum = min(testCase.times) - binsize;
            enum = max(testCase.times) + binsize;

            er = testCase.C.eventrate( ...
                'binsize',  binsize, ...
                'stepsize', binsize, ...
                'snum',     snum, ...
                'enum',     enum);

            % ---- Event conservation ----
            testCase.verifyEqual( ...
                sum(er.counts), numel(testCase.times), ...
                'All events must be counted exactly once.');

            % ---- Energy conservation ----
            testCase.verifyEqual( ...
                sum(er.energy), testCase.total_energy, ...
                'RelTol', 1e-12, ...
                'Total binned energy must equal total catalog energy.');

            % ---- total_counts scalar ----
            testCase.verifyEqual( ...
                er.total_counts, numel(testCase.times));

            % ---- total_mag physics ----
            expected_total_mag = magnitude.eng2mag(testCase.total_energy);

            testCase.verifyEqual( ...
                er.total_mag, expected_total_mag, ...
                'RelTol', 1e-12, ...
                'total_mag must equal eng2mag(sum(all energies)).');
        end
    end

    %% =====================================================================
    %% BINNING & SLIDING WINDOWS
    %% =====================================================================
    methods (Test)

        function TestSlidingWindowStructure(testCase)

            er = testCase.C.eventrate( ...
                'binsize',  testCase.binsize, ...
                'stepsize', testCase.stepsize);

            testCase.verifyGreaterThan(numel(er.counts), 50);
            testCase.verifyEqual(numel(er.counts), numel(er.time));
            testCase.verifyEqual(numel(er.energy), numel(er.time));
        end


        function TestNoNegativeCounts(testCase)

            er = testCase.C.eventrate('binsize', testCase.binsize);
            testCase.verifyGreaterThanOrEqual(er.counts(:), 0);
        end


        function TestEdgeBinsHandledGracefully(testCase)

            snum = min(testCase.times) + 0.5;
            enum = max(testCase.times) - 0.5;

            er = testCase.C.eventrate( ...
                'binsize',  testCase.binsize, ...
                'snum',     snum, ...
                'enum',     enum);

            testCase.verifyTrue(all(isfinite(er.time)));
            testCase.verifyTrue(all(er.counts >= 0));
        end
    end

    %% =====================================================================
    %% MAGNITUDE & ENERGY INTERNAL CONSISTENCY
    %% =====================================================================
    methods (Test)

        function TestMeanRatePhysics(testCase)

            er = testCase.C.eventrate('binsize', testCase.binsize);

            expected = er.counts(:) ./ (24 * er.binsize);
            mr       = er.mean_rate(:);

            testCase.verifyEqual(mr, expected, ...
                'RelTol', 1e-12);
        end


        function TestMedianMagFiniteInOccupiedBins(testCase)

            er = testCase.C.eventrate('binsize', testCase.binsize);
            occupied = er.counts > 0;

            testCase.verifyTrue(all(isfinite(er.median_mag(occupied))));
        end


        function TestMinMaxMagOrdering(testCase)

            er = testCase.C.eventrate('binsize', testCase.binsize);
            occupied = er.counts > 0;

            min_mag = er.min_mag(occupied);
            max_mag = er.max_mag(occupied);

            testCase.verifyLessThanOrEqual(min_mag, max_mag);
        end
    end

    %% =====================================================================
    %% EMPTY & SINGLE-EVENT CATALOG HANDLING
    %% =====================================================================
    methods (Test)

        function TestEmptyCatalog(testCase)

            Cempty = Catalog();
            er = Cempty.eventrate('binsize', 1);

            testCase.verifyEqual(er.total_counts, 0);
            testCase.verifyTrue(isempty(er.counts));
        end


        function TestSingleEventBehavesCorrectly(testCase)

            t0  = datenum(2020,1,1);
            mag = 2.5;

            C = Catalog(t0, 0, 0, 0, mag, {}, {}, ...
                        'ontime', t0, 'offtime', t0);

            er = C.eventrate('binsize', 1);

            testCase.verifyEqual(sum(er.counts), 1);

            expected_energy = magnitude.mag2eng(mag);
            testCase.verifyEqual(sum(er.energy), expected_energy);
        end
    end

    %% =====================================================================
    %% PLOT SMOKE TESTS (FIGURE-SAFE)
    %% =====================================================================
    methods (Test)

        function TestPlotNoCrash(testCase)

            er = testCase.C.eventrate('binsize', testCase.binsize);

            f = figure('Visible','off');
            er.plot();
            close(f);
        end


        function TestMultiMetricPlotNoCrash(testCase)

            er = testCase.C.eventrate('binsize', testCase.binsize);

            f = figure('Visible','off');
            er.plot('metric', {'counts','mean_rate','cum_mag'});
            close(f);
        end


        function TestPythonPlotNoCrash(testCase)

            er = testCase.C.eventrate('binsize', testCase.binsize);

            f = figure('Visible','off');
            er.pythonplot();
            close(f);
        end
    end

end
