function self = usgsrealtime(timeperiod)
%READEVENTS.USGSREALTIME Read last week or month of data from USGS
% catalogObject = READEVENTS.USGSREALTIME('week') Read the last week
% of data from USGS real-time earthquake feed
% catalogObject = READEVENTS.USGSREALTIME('month') Read the last month
% of data from USGS real-time earthquake feed
%
% Uses code by Loren Shure / Mathworks

%%
%   Copyright 2015 The MathWorks, Inc.

options = weboptions('Timeout',10);
quakeDataJSON = webread(sprintf('http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_%s.geojson',timeperiod), options);

%% Extract information per quake
quakeDataInfo = [quakeDataJSON.features.properties];
quakeDataLocation = [quakeDataJSON.features.geometry];

%% Convert struct to table
quakeTable = struct2table(quakeDataInfo);

%% Add location info to the table
eqcoordinates = [quakeDataLocation.coordinates]';
quakeTable.Lon = eqcoordinates(:,1);
quakeTable.Lat = eqcoordinates(:,2);
quakeTable.depth = eqcoordinates(:,3);

%% Create Catalog object from table

% SCAFFOLD: time is probably is some format datenum does not understand
    self = Catalog(datenum(quakeTable.time), quakeTable.lon, quakeTable.lat, quakeTable.depth, quakeTable.mag, {}, {});
end
