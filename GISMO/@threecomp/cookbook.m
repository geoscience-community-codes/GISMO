function cookbook(TC)

% This cookbook contains sample code to illustrate the basic functions of
% the threecomp toolbox.

%% TEMPORARY
clear
clear classes
rmgismo
addpath('/home/field/GISMO_BRANCH/GISMO/');
startup_GISMO


%% Load demo data
% Demo dataset consists of 14 stations of data from a single earthquake
% recorded regionally in California. Each station has three components of
% waveform data. There is an accompanying 14 element vector "backAzimuth"
% which contains the backazimuth from each station to the origin. The
% vector "trigger" contains a set a crude surface wave pick times - one per
% station. The trigger field is not required by the threecomp object.
% However it provides functionality demonstrated later. Though not required
% for threecomp functions, each trace also contains the station lat/lon and
% the origin lat/lon used to illustrate three component processing. DEMO
% also creates a simple map, useful for interpreting the 3-component data.

[w,backAzimuth,trigger] = demo(threecomp);

%% Create a threecomp object
% In this example, the backAzimuth property is set as well. 

TC = threecomp(w,backAzimuth,trigger);


%% List object properties
% Example lists all network-station-channels-location and the full set of
% properties for threecomp element 5.

NSCL = get(TC,'NSCL')
disp(TC(4));


%% Plot object
% PLOT operates on a single object at a time. 

plot(TC(4));


%% Rotate horizontal traces
% Default useage rotates traces inline with the backazimuths. Plot rotated
% traces. Note the horizontal and vertical orientations noted on the
% plot. See DESCRIBE(THREECOMP) for reference frame specifics.

TC = rotate(TC);
plot(TC(4))


%% Examinte traces over a range of rotations
% This function rotates a single threecomp object through a range of
% bearings and plots the suite of rotated traces.

baz = round(TC(13).backAzimuth)
spin(TC(13),[baz-180:10:baz+180])


%% Calculate particle motion coefficients 
% The PARTCLEMOTION function fills the following threecomp properties:
% rectilinearity, planarity, energy, azimuth and inclination. See
% DESCRIBE(THREECOMP) for description of each. Display properties and plot
% traces.

TC = particlemotion(TC,2,20);
disp(TC(4));
plotpm(TC(4))



%% Extract mean particle motion
% This function extracts a single value of each particle motion coefficient
% averaged over a 30 sec window beginning at the trigger time. Include only
% those time steps that meet the minimum rectilinearity threshold of 0.7.

pm = extract(TC,[0 30],[0.7 0]);


%% Add azimuth of particle motions to station map
% Plot the extracted particle motion azimuths on the station map. First,
% replot the demo map. Second, create vector lines from the azimuth
% particle motion coefficients. Third, plot the lines.

[~,~,~,staLat,staLon,origLat,origLon] = demo(threecomp);
for n=1:size(w,1)
    [arrowLat(1,n) arrowLon(1,n)] = reckon(staLat(n),staLon(n), -0.3, pm(n).azimuth);
    [arrowLat(2,n) arrowLon(2,n)] = reckon(staLat(n),staLon(n), 0.3, pm(n).azimuth);
end
plot(arrowLon,arrowLat,'r-');

    
