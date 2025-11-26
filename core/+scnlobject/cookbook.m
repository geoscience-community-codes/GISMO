%% SCNLOBJECT Cookbook
% This cookbook introduces the SCNLOBJECT class, which represents
% station–channel identifiers used throughout GISMO for waveform and
% datasource queries.
%
% A SCNLOBJECT contains four fields:
%   • Network
%   • Station
%   • Location
%   • Channel
%
% Station and Channel are required.
% Network and Location are optional.

%% Basic Construction

% Full NSLC specification
red = scnlobject('RED','EHZ','AV','--');

% Without location
rso = scnlobject('RSO','EHZ','AV');

% From dot-delimited string
ref = scnlobject('AV.REF.--.EHZ');

%% Multi-Component Stations

% 3-component broadband station
rdbw = scnlobject('RDBW',{'BHZ','BHE','BHN'},'AV');

%% Modifying Existing Objects with SET

% Duplicate template and change station name
rdjh = set(rdbw,'station','RDJH');

%% Grouping SCNL Objects

redstas = [red rso rdbw rdjh];

%% Wildcards

% Wildcards allow flexible querying
anyEHZ = scnlobject('*','EHZ','*','*');
anyBroadband = scnlobject('*',{'BHZ','BHE','BHN'},'*','*');
anyNorth = scnlobject('*',{'EHN','SHN','BHN'},'*','*');

%% Finding Matches with ISMEMBER

% Does RSO exist in the group?
[tf, idx] = ismember(rso, redstas);

% Reverse lookup
[tf2, idx2] = ismember(redstas, rso);

%% Wildcard Matching

stationsOfInterest = redstas(ismember(redstas, anyEHZ));

for k = 1:numel(stationsOfInterest)
    disp(stationsOfInterest(k))
end

%% Broadband Selection

myBroadbands = redstas(ismember(redstas, anyBroadband));
size(myBroadbands)

%% Retrieving Fields with GET

get(myBroadbands,'station')
strcat(get(myBroadbands,'station'),'|',get(myBroadbands,'channel'))

%% Vertical Formatting

strcat( ...
    get(myBroadbands','station'), ...
    "|", ...
    get(myBroadbands','channel') )

%% Removing Duplicates with UNIQUE

manyscnls = [redstas red rso red redstas];
unique(manyscnls)

%% Relationship to ChannelTag
% SCNLOBJECT and ChannelTag are interoperable in many GISMO functions.
%
% ChannelTag:
%   Network.Station.Location.Channel
%
% SCNLOBJECT:
%   Network, Station, Location, Channel (same fields, legacy ordering)

ct = ChannelTag('AV.REF.--.EHZ');
sc = scnlobject(ct.string());

%% Method Summary

methods(scnlobject)
