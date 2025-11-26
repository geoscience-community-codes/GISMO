%% THREECOMP Cookbook
% This cookbook demonstrates the core functionality of the THREECOMP class,
% which is used for three-component seismic waveform analysis including:
%
%   • Horizontal rotation
%   • Particle motion analysis
%   • Rectilinearity and planarity
%   • Azimuth and inclination estimation
%
% THREECOMP operates on matrices of waveform objects where each row
% represents a station and the three columns represent Z, N/E, N/S
% components.

%% Load Demo Dataset (CI-Safe)
% The built-in demo provides:
%   • w            : Nx3 matrix of waveform objects
%   • backAzimuth : N×1 backazimuth vector (deg)
%   • trigger     : N×1 trigger times (datenum)
%
% NOTE: If the demo dataset is missing, we gracefully skip all examples.

try
    [w, backAzimuth, trigger] = demo(threecomp);
    hasDemo = true;
catch
    warning('threecomp:DemoUnavailable', ...
        'Demo dataset not found. threecomp cookbook examples skipped.');
    hasDemo = false;
end

if ~hasDemo
    return
end

%% Create a THREECOMP Object
TC = threecomp(w, backAzimuth, trigger);

%% Inspect Object Properties
% List available network–station–channel identifiers
NSCL = get(TC,'NSCL');

% Display one element's metadata
disp(TC(4));

%% Plot Unrotated Traces
figure('Visible','off');
plot(TC(4));

%% Rotate Horizontal Traces into Radial–Transverse Frame
% Default: rotation into backazimuth frame
TCr = rotate(TC);

figure('Visible','off');
plot(TCr(4));

%% Explore Rotation Sensitivity for a Single Station
% Spin through +/- 180 degrees around the backazimuth

baz = round(TC(13).backAzimuth);
spin(TC(13), baz-180:10:baz+180);

%% Particle Motion Analysis
% Compute rectilinearity, planarity, azimuth, inclination, and energy
% using a 2–20 Hz band for particle motion estimation

TCpm = particlemotion(TCr, 2, 20);

% Inspect one station
disp(TCpm(4));

% Plot particle motion for one station
figure('Visible','off');
plotpm(TCpm(4));

%% Extract Mean Particle Motion Around Trigger
% Extract 30-second window starting at trigger time
% Apply minimum rectilinearity threshold = 0.7

pm = extract(TCpm, [0 30], [0.7 0]);

%% Optional Mapping of Particle Motion (If Mapping Toolbox Available)
% This section overlays particle motion azimuths on the demo station map.
% It is skipped automatically if Mapping Toolbox is unavailable.

if exist('reckon','file') == 2
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
    disp('Mapping Toolbox not available — skipping particle motion map overlay.');
end

%% Summary of THREECOMP Capabilities
% THREECOMP supports:
%   • Multi-station 3C waveform handling
%   • Backazimuth-aware rotation
%   • Particle motion parameter estimation
%   • Trigger-relative extraction
%   • Visual rotation exploration