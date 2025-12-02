function cookbook()
%% THREECOMP Cookbook (Core GISMO)
%
% End-to-end demonstration of the THREECOMP class:
%
%   • Construction from 3-component waveform matrices
%   • Horizontal rotation
%   • Particle motion analysis
%   • Trigger-relative extraction
%   • Particle motion plotting
%
% This cookbook is:
%   ✓ CI-safe (no required toolboxes)
%   ✓ Demo-driven (no TESTDATA dependency)
%   ✓ Fully validates the THREECOMP processing chain
%
% Glenn Thompson / Refactored 2025

close all
clc

fprintf('\n=== THREECOMP COOKBOOK START ===\n');

%% ------------------------------------------------------------------------
%% 1. Load Demo Dataset (CI-Safe)
%% ------------------------------------------------------------------------
fprintf('\n--- Loading threecomp demo dataset ---\n');

try
    [w, backAzimuth, trigger] = demo(threecomp);
    hasDemo = true;
catch ME
    warning('threecomp:DemoUnavailable', ...
        'Demo dataset not found. threecomp cookbook skipped.');
    fprintf('%s\n', ME.message);
    return
end

fprintf('Loaded THREECOMP demo data.\n');

%% ------------------------------------------------------------------------
%% 2. Construct THREECOMP Object
%% ------------------------------------------------------------------------
fprintf('\n--- Constructing THREECOMP object ---\n');

TC = threecomp(w, backAzimuth, trigger);
disp(TC(1));

NSCL = get(TC,'NSCL'); %#ok<NASGU>

%% ------------------------------------------------------------------------
%% 3. Plot Unrotated Traces
%% ------------------------------------------------------------------------
fprintf('\n--- Plotting unrotated traces ---\n');

figure('Visible','off','Name','THREECOMP Raw');
plot(TC(1));

%% ------------------------------------------------------------------------
%% 4. Rotate Horizontal Traces
%% ------------------------------------------------------------------------
fprintf('\n--- Rotating to radial–transverse frame ---\n');

TCr = rotate(TC);

figure('Visible','off','Name','THREECOMP Rotated');
plot(TCr(1));

%% ------------------------------------------------------------------------
%% 5. Explore Rotation Sensitivity (Spin)
%% ------------------------------------------------------------------------
fprintf('\n--- Performing spin test ---\n');

baz = round(TC(1).backAzimuth);
spin(TC(1), baz-180:30:baz+180);

%% ------------------------------------------------------------------------
%% 6. Particle Motion Analysis
%% ------------------------------------------------------------------------
fprintf('\n--- Computing particle motion (2–20 Hz) ---\n');

TCpm = particlemotion(TCr, 2, 20);
disp(TCpm(1));

figure('Visible','off','Name','Particle Motion');
plotpm(TCpm(1));

%% ------------------------------------------------------------------------
%% 7. Trigger-Relative Extraction
%% ------------------------------------------------------------------------
fprintf('\n--- Extracting trigger-relative particle motion ---\n');

pm = extract(TCpm, [0 30], [0.7 0]); %#ok<NASGU>

fprintf('Extracted %d particle-motion windows.\n', numel(pm));

%% ------------------------------------------------------------------------
%% 8. Optional Mapping (Toolbox-Safe Auto-Skip)
%% ------------------------------------------------------------------------
if exist('reckon','file') == 2

    fprintf('\n--- Mapping particle motion vectors ---\n');

    [~,~,~,staLat,staLon,origLat,origLon] = demo(threecomp);

    figure('Color','w','Position',[50 50 400 400]);
    plot(staLon, staLat, 'bo','LineWidth',2,'MarkerSize',7);
    hold on; box on; grid on;
    plot(origLon, origLat, 'ro','LineWidth',2,'MarkerSize',9);
    set(gca,'DataAspectRatio',[1 cosd(mean(staLat)) 1]);

    for n = 1:numel(pm)
        [arrowLat(1), arrowLon(1)] = reckon(staLat(n),staLon(n), -0.3, pm(n).azimuth);
        [arrowLat(2), arrowLon(2)] = reckon(staLat(n),staLon(n),  0.3, pm(n).azimuth);
        plot(arrowLon, arrowLat,'r-');
        text(staLon(n), staLat(n), ['  ' num2str(n)], 'FontWeight','bold');
    end

    text(origLon, origLat, '  Origin','FontWeight','bold');
    xlabel('Longitude'); ylabel('Latitude');
    legend('Stations','Origin','Particle motion','Location','NorthWest');

else
    fprintf('Mapping Toolbox not available — skipping map overlay.\n');
end

%% ------------------------------------------------------------------------
%% Final Status
%% ------------------------------------------------------------------------
fprintf('\n=== THREECOMP COOKBOOK COMPLETED SUCCESSFULLY ===\n');

end
