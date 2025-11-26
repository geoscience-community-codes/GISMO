classdef test_threecomp < matlab.unittest.TestCase
    % TEST_THREECOMP
    %
    % Smoke tests for the THREECOMP class.
    %
    % These tests verify that:
    %   • the demo dataset loads (if available)
    %   • a threecomp object can be constructed
    %   • rotation, particle motion, and extraction run without error
    %
    % No numerical verification is performed.
    % All figure creation is suppressed for CI safety.

    properties
        hasDemo = false
        w
        backAzimuth
        trigger
        TC
    end

    %% --------------------------------------------------------------------
    methods (TestClassSetup)
        function loadDemo(testCase)
            % Attempt to load demo data (CI-safe)
            try
                [w, backAzimuth, trigger] = demo(threecomp);
                testCase.w = w;
                testCase.backAzimuth = backAzimuth;
                testCase.trigger = trigger;
                testCase.hasDemo = true;
            catch
                warning('threecomp:DemoUnavailable', ...
                    'threecomp demo data not available. Tests will be skipped.');
                testCase.hasDemo = false;
            end
        end
    end

    %% --------------------------------------------------------------------
    methods (Test)
        function TestConstructor(testCase)
            if ~testCase.hasDemo
                testCase.assumeTrue(false, 'Skipping test: threecomp demo unavailable.');
            end

            TC = threecomp(testCase.w, ...
                           testCase.backAzimuth, ...
                           testCase.trigger);

            testCase.verifyClass(TC, 'threecomp');
            testCase.verifyNotEmpty(TC);

            testCase.TC = TC;
        end

        function TestPlot(testCase)
            if ~testCase.hasDemo
                testCase.assumeTrue(false, 'Skipping test: threecomp demo unavailable.');
            end

            TC = threecomp(testCase.w, ...
                           testCase.backAzimuth, ...
                           testCase.trigger);

            f = figure('Visible','off');
            plot(TC(1));
            close(f);
        end

        function TestRotate(testCase)
            if ~testCase.hasDemo
                testCase.assumeTrue(false, 'Skipping test: threecomp demo unavailable.');
            end

            TC = threecomp(testCase.w, ...
                           testCase.backAzimuth, ...
                           testCase.trigger);

            TCr = rotate(TC);
            testCase.verifyClass(TCr, 'threecomp');
        end

        function TestParticleMotion(testCase)
            if ~testCase.hasDemo
                testCase.assumeTrue(false, 'Skipping test: threecomp demo unavailable.');
            end

            TC = threecomp(testCase.w, ...
                           testCase.backAzimuth, ...
                           testCase.trigger);

            TCr  = rotate(TC);
            TCpm = particlemotion(TCr, 2, 20);

            testCase.verifyClass(TCpm, 'threecomp');
        end

        function TestExtract(testCase)
            if ~testCase.hasDemo
                testCase.assumeTrue(false, 'Skipping test: threecomp demo unavailable.');
            end

            TC = threecomp(testCase.w, ...
                           testCase.backAzimuth, ...
                           testCase.trigger);

            TCr  = rotate(TC);
            TCpm = particlemotion(TCr, 2, 20);

            pm = extract(TCpm, [0 30], [0.7 0]);
            testCase.verifyNotEmpty(pm);
        end

        function TestPlotParticleMotion(testCase)
            if ~testCase.hasDemo
                testCase.assumeTrue(false, 'Skipping test: threecomp demo unavailable.');
            end

            TC = threecomp(testCase.w, ...
                           testCase.backAzimuth, ...
                           testCase.trigger);

            TCr  = rotate(TC);
            TCpm = particlemotion(TCr, 2, 20);

            f = figure('Visible','off');
            plotpm(TCpm(1));
            close(f);
        end
    end
end