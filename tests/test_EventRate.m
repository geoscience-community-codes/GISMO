classdef test_EventRate < matlab.unittest.TestCase
    % Robust unit tests for EventRate using a large synthetic Catalog.
    %
    % This test file assumes:
    %   - Catalog has properties: otime, lon, lat, depth, mag, ...
    %   - Catalog.eventrate(...) internally calls Catalog.binning.bin_irregular
    %   - bin_irregular respects the (snum, enum, binsize, stepsize) it is given
    %
    % The tests focus on:
    %   • Construction and basic sizes
    %   • Non-negative counts
    %   • Internal consistency of rates and magnitudes
    %   • Sliding-window structure
    %   • Plot smoke tests (no exceptions)
    %
    % They DO NOT assume:
    %   • That every single event is counted (edge events can fall out)
    %   • That er.total_mag equals the magnitude of all original events
    %     (because edge effects can legitimately exclude a few events)

    properties
        C          % synthetic Catalog
        mags       % synthetic magnitudes
        times      % synthetic times
        binsize    % 1 hour in days
        stepsize   % sliding step (10 min) in days
    end

    %% ------------------------------------------------------------
    methods (TestClassSetup)
        function makeLargeSyntheticCatalog(testCase)
            % Large synthetic catalog: 500 events over 5 days
            rng(42);  % deterministic
            nEvents = 500;

            t0    = datenum(2020,1,1,0,0,0);
            span  = 5;                    % days
            times = sort(t0 + span*rand(nEvents,1));   % (t0, t0+5)
            mags  = 1 + 3*rand(nEvents,1);             % [1,4)

            % Use the real Catalog constructor interface
            lon   = zeros(nEvents,1);
            lat   = zeros(nEvents,1);
            depth = zeros(nEvents,1);

            C = Catalog(times, lon, lat, depth, mags, {}, {}, ...
                        'ontime', times, 'offtime', times);

            testCase.C        = C;
            testCase.mags     = mags;
            testCase.times    = times;
            testCase.binsize  = 1/24;      % 1 hour
            testCase.stepsize = 10/1440;   % 10 minutes
        end
    end

    %% ------------------------------------------------------------
    % BASIC CONSTRUCTION
    %% ------------------------------------------------------------
    methods (Test)

        function TestPerfectEventConservation(testCase)
            C = testCase.C;
            binsize = testCase.binsize;

            snum = min(testCase.times) - binsize;
            enum = max(testCase.times) + binsize;

            er = C.eventrate( ...
                'binsize',  binsize, ...
                'stepsize', binsize, ...
                'snum',     snum, ...
                'enum',     enum);

            % 1. Count conservation must be exact
            nEvents = numel(testCase.times);
            testCase.verifyEqual( ...
                sum(er.counts), nEvents, ...
                'All events must be counted into exactly one bin.' );

            % 2. Energy conservation must be exact
            total_energy_catalog = sum(magnitude.mag2eng(testCase.mags));
            testCase.verifyEqual( ...
                sum(er.energy), total_energy_catalog, ...
                'RelTol', 1e-12, ...
                'Total binned energy must equal catalog energy.' );

            % 3. total_counts must be exact
            testCase.verifyEqual( ...
                er.total_counts, nEvents, ...
                'total_counts must equal the number of catalog events.' );

            % 4. total_mag must match physics exactly
            expected_total_mag = magnitude.eng2mag(total_energy_catalog);
            testCase.verifyEqual( ...
                er.total_mag, expected_total_mag, ...
                'RelTol', 1e-12, ...
                'total_mag must equal eng2mag(sum(all energies)).' );
        end

    end
    %% ------------------------------------------------------------
    % BINNING & SLIDING WINDOWS
    %% ------------------------------------------------------------
    methods (Test)

        function TestSlidingWindowStructure(testCase)
            er = testCase.C.eventrate( ...
                'binsize',  testCase.binsize, ...
                'stepsize', testCase.stepsize);

            % We expect many bins, and 1:1 mapping of time/counts
            testCase.verifyGreaterThan(numel(er.counts), 10);
            testCase.verifyEqual(numel(er.counts), numel(er.time));
        end

        function TestNoNegativeCounts(testCase)
            er = testCase.C.eventrate('binsize', testCase.binsize);
            testCase.verifyGreaterThanOrEqual(er.counts(:), 0, ...
                'Event counts must be non-negative.');
        end
    end

    %% ------------------------------------------------------------
    % MAGNITUDE, ENERGY, & RATE CONSISTENCY
    %% ------------------------------------------------------------
    methods (Test)

        function TestTotalMagnitudeInternalConsistency(testCase)
            % This checks EventRate's internal definition of total_mag,
            % not that all original events are included.
            er = testCase.C.eventrate('binsize', testCase.binsize);

            total_energy_from_bins = sum(er.energy(:));
            expected_mag_from_bins = magnitude.eng2mag(total_energy_from_bins);

            testCase.verifyEqual(er.total_mag, expected_mag_from_bins, ...
                'RelTol', 1e-10, ...
                'total_mag must be consistent with sum(er.energy).');
        end

        function TestMeanRatePhysics(testCase)
            er = testCase.C.eventrate('binsize', testCase.binsize);

            % mean_rate is defined as counts / (24 * binsize) [events/hour]
            expected = er.counts(:) ./ (24 * er.binsize);
            mr       = er.mean_rate(:);

            testCase.verifyEqual(mr, expected, ...
                'RelTol', 1e-12, ...
                'mean_rate must equal counts / (24 * binsize).');
        end

        function TestMedianMagFinite(testCase)
            er = testCase.C.eventrate('binsize', testCase.binsize);

            counts      = er.counts(:);
            median_mag  = er.median_mag(:);

            % Only check bins that actually contain events
            finiteMask = counts > 0;

            testCase.verifyTrue(all(isfinite(median_mag(finiteMask))), ...
                'median_mag must be finite in bins that contain events.');
        end

        function TestMinMaxMagOrdering(testCase)
            er = testCase.C.eventrate('binsize', testCase.binsize);

            min_mag = er.min_mag(:);
            max_mag = er.max_mag(:);
            counts  = er.counts(:);

            finiteMask = counts > 0 ...
                         & isfinite(min_mag) ...
                         & isfinite(max_mag);

            testCase.verifyLessThanOrEqual(min_mag(finiteMask), max_mag(finiteMask), ...
                'For bins with events, min_mag must be <= max_mag.');
        end
    end

    %% ------------------------------------------------------------
    % PLOT SMOKE TESTS
    %% ------------------------------------------------------------
    methods (Test)
        function TestPlot(testCase)
            er = testCase.C.eventrate('binsize', testCase.binsize);
            f = figure('Visible','off');
            er.plot();
            close(f);
        end

        function TestPlotMultipleMetrics(testCase)
            er = testCase.C.eventrate('binsize', testCase.binsize);
            f = figure('Visible','off');
            er.plot('metric', {'counts','mean_rate','cum_mag'});
            close(f);
        end

        function TestPythonPlot(testCase)
            er = testCase.C.eventrate('binsize', testCase.binsize);
            f = figure('Visible','off');
            er.pythonplot();
            close(f);
        end
    end
end
