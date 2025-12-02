classdef test_Detection < matlab.unittest.TestCase
    % TEST_DETECTION
    %
    % Comprehensive test suite for the GISMO Detection class.
    %
    % This test file includes:
    %   1. CI-safe cookbook smoke test
    %   2. Real-data STA/LTA detection test using Redoubt MiniSEED
    %
    % The real-data test is automatically skipped if:
    %   • TESTDATA is not configured
    %   • The required MiniSEED file is missing
    %
    % Glenn Thompson / Refactored 2025

    %% --------------------------------------------------------------------
    %% 1. CI-SAFE COOKBOOK SMOKE TEST
    %% --------------------------------------------------------------------
    methods (Test)
        function test_runDetectionCookbook(testCase)
            % Verifies that Detection.cookbook runs without fatal error.
            % This test is fully CI-safe and does NOT require TESTDATA.

            mc = meta.class.fromName('Detection');
            testCase.assertNotEmpty(mc, 'Detection class not found');

            methodNames = {mc.MethodList.Name};
            testCase.assertTrue(ismember('cookbook', methodNames), ...
                'Detection.cookbook method not found');

            close all force;

            try
                Detection.cookbook();
            catch ME
                fprintf(2, '\n--- Detection Cookbook FAILURE ---\n');
                fprintf(2, '%s\n', ME.getReport('extended'));
                testCase.verifyFail(ME.message);
            end
        end
    end

    %% --------------------------------------------------------------------
    %% 2. REAL REDOUBT MINISEED INTEGRATION TEST
    %% --------------------------------------------------------------------
    methods (Test)
        function testStaLtaOnRedoubtMiniSEED(testCase)
            % Integration test using real Redoubt MiniSEED
            % Requires: TESTDATA/miniseed_data/REF.EHZ.2009.081
            %
            % This test validates:
            %   • waveform loading
            %   • STA/LTA detection
            %   • ON/OFF pairing
            %   • Detection.associate()
            %   • Conversion to Catalog

            % ---- Ensure TESTDATA is available ----------------------------
            try
                admin.is_testdata_setup(false);
            catch
                testCase.assumeFail( ...
                    'TESTDATA not configured — skipping Redoubt Detection test.');
            end

            global TESTDATA

            mseedFile = fullfile(TESTDATA, ...
                'miniseed_data','REF.EHZ.2009.081');

            testCase.assumeTrue(exist(mseedFile,'file') == 2, ...
                sprintf('Redoubt MiniSEED not found: %s', mseedFile));

            % ---- Read waveform ------------------------------------------
            w = waveform('miniseed', mseedFile);

            % ---- Basic waveform sanity ----------------------------------
            testCase.verifyClass(w, 'waveform');
            testCase.verifyGreaterThan(numel(get(w,'data')), 1000);

            % ---- Run STA/LTA detector ----------------------------------
            [det, sta, lta, ratio] = Detection.sta_lta(w);

            testCase.verifyClass(det, 'Detection');

            % ---- Detection integrity ------------------------------------
            testCase.verifyGreaterThan(det.numel, 0, ...
                'Expected at least one detection on eruptive day.');

            % Must be ON/OFF paired
            testCase.verifyEqual(mod(det.numel,2), 0, ...
                'Detections must be ON/OFF paired.');

            % All times finite
            testCase.verifyTrue(all(isfinite(det.time)), ...
                'Detection times contain invalid values.');

            % Channel integrity
            testCase.verifyTrue(any(contains(det.channelinfo,'REF')));
            testCase.verifyTrue(any(contains(det.channelinfo,'EHZ')));

            % STA/LTA vectors must match waveform length
            n = numel(get(w,'data'));
            testCase.verifyEqual(numel(sta),   n);
            testCase.verifyEqual(numel(lta),   n);
            testCase.verifyEqual(numel(ratio), n);

            % ---- Association into Catalog -------------------------------
            cat = det.associate(30);   % 30-s association window

            testCase.verifyClass(cat, 'Catalog');

            % Even a single-station run should still produce a catalog
            testCase.verifyGreaterThanOrEqual(numel(cat.otime), 1);

        end
    end

end
