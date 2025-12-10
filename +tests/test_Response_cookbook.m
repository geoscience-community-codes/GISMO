classdef test_Response_cookbook < matlab.unittest.TestCase
    % TEST_RESPONSE_COOKBOOK
    %
    % Smoke + regression test for the modern Response & sacpz system.
    %
    % This test ensures that:
    %   • @Response/cookbook.m executes fully without error
    %   • sacpz loading via TESTDATA is exercised
    %   • Response.apply(), evaluate(), and plot() are called
    %   • Antelope paths are OPTIONAL and auto-skipped
    %
    % This test replaces ALL legacy response toolbox tests.

    methods (Test)

        function test_runResponseCookbook(testCase)

            % ---- Ensure TESTDATA is available ---------------------------
            try
                admin.is_testdata_setup(false);
            catch
                testCase.assumeFail( ...
                    'TESTDATA not configured — skipping Response cookbook test.');
            end
            global TESTDATA

            % ---- Locate Response class --------------------------------
            mc = meta.class.fromName('Response');
            testCase.assertNotEmpty(mc, ...
                'Response class not found on path');

            methodNames = {mc.MethodList.Name};
            testCase.assertTrue(ismember('cookbook', methodNames), ...
                'Response.cookbook method not found');

            % ---- Clean graphics state ---------------------------------
            close all force;

            % ---- Execute cookbook safely ------------------------------
            try
                Response.cookbook();
            catch ME
                fprintf(2, '\n--- Response Cookbook FAILURE ---\n');
                fprintf(2, '%s\n', ME.getReport('extended'));
                testCase.verifyFail(ME.message);
            end

            % ---- Basic post-conditions --------------------------------
            figs = get(0,'Children');
            testCase.verifyGreaterThanOrEqual( ...
                numel(figs), 1, ...
                'Cookbook ran but produced no figures');
        end


        function test_sacpz_basic_evaluation(testCase)
            % Direct numerical sanity test of sacpz → Response path

            % ---- Ensure TESTDATA is available -------------------------
            try
                admin.is_testdata_setup(false);
            catch
                testCase.assumeFail('TESTDATA not configured — skipping test.');
            end

            % ---- Synthetic poles & zeros ------------------------------
            pz = sacpz();
            pz.z = [0; 0];
            pz.p = [-2+2i; -2-2i];
            pz.k = 1;
            pz.samplerate = 100;
            pz.outputunit = 'M/S';
            pz.station = 'TEST';
            pz.channel = 'BHZ';

            R = Response.from_sacpz(pz);

            f = logspace(-2,2,200);
            H = R.evaluate(f);

            testCase.verifyEqual(numel(H), numel(f));
            testCase.verifyTrue(all(isfinite(H)), ...
                'Response contains NaNs or Infs');
        end


        function test_response_apply_synthetic(testCase)
            % End-to-end numerical apply test without Antelope

            fs = 100;
            t  = (0:fs*10-1)'/fs;
            x  = sin(2*pi*2*t);

            % ---- Build synthetic PZ -----------------------------------
            pz = sacpz();
            pz.z = [0;0];
            pz.p = [-5+5i; -5-5i];
            pz.k = 1;
            pz.samplerate = fs;
            pz.outputunit = 'M/S';
            pz.station = 'TEST';
            pz.channel = 'BHZ';

            R = Response.from_sacpz(pz);

            filt = filterobject('b',[0.5 10],3);

            w = waveform( ...
                ChannelTag('TEST','BHZ','',''), ...
                fs, datenum(2020,1,1), x);

            w2 = R.apply(w, filt);

            y = double(w2);

            testCase.verifyEqual(numel(y), numel(x));
            testCase.verifyTrue(all(isfinite(y)), ...
                'Response.apply output contains NaNs or Infs');
        end

    end
end
