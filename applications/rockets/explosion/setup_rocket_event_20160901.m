% waveform data parameters
%clear all
close all
%startup
make_figures = true;

% Geographical coordinates
% coords = ...
%     [28.574013,	-80.57236;
%      28.574182,	-80.57241;
%      28.573894,	-80.572352;
%      28.574004,	-80.572561];
coords = ...
    [28.5740171611,	-80.5723755;
     28.5742216111,	-80.5724168556;
     28.5738811889,	-80.572295775;
     28.5740064361,	-80.57256045];

 
% SLC40 - SpaceX launch complex
% source.lat = 28.562106; 
% source.lon = -80.57718;
source.lon = -80.57719; %-80.57718;
source.lat = 28.56195; %28.562106;

easting = [461.091 473.067 447.133 465.217 465.217 465.217];
northing = [1343.9 1306.23 1320.01 1321.26 1321.26 1321.26];
% Wind tower data - could read this from Excel instead
% get Excel file from 
relativeHumidity = 89.5; % percent from NASA weather tower data
temperatureF = 80.65; % 80 Fahrenheit according to weather tower data from NASA
wind_direction_from = 144; % degrees - this is the direction FROM according to NASA, see Lisa Huddleston email of Oct 10th
wind_speed_knots = 5.5; % knots

% now call
rocket_airwave_event_analysis