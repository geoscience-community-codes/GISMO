function station = getStationsWithinDist(lon, lat, distkm, dbstations, maxsta)
%GETSTATIONSWITHINDIST 
% station = getStationsWithinDist(lon, lat, distkm, dbstations)
% load station/channels within DISTKM km of a given (LON, LAT) 
% from site database DBSTATIONS
% 
% station = getStationsWithinDist(lon, lat, distkm, dbstations, maxsta)
% return the closest maxsta stations, even if more are within DISTKM
%
% The station structure returned has the followed fields:
%	name - the station name
%	channel - the channel
%	scnl - station name, channel, network as a scnlobject
%	site.lon	- station longitude
%	site.lat	- station latitude
%	site.elev	- station elevation
%	distance	- distance (in km) from input (LON, LAT)

% AUTHOR: Glenn Thompson, UAF-GI
% $Date: $
% $Revision: -1 $

if ~exist('maxsta', 'var')
	maxsta = 999;
end

db = dbopen(dbstations, 'r');
db = dblookup_table(db, 'site');
db = dbsubset(db, sprintf('distance(lon, lat, %.4f, %.4f)<%.4f',lon,lat,km2deg(distkm)));
db = dbsubset(db, sprintf('offdate == NULL'));
db2 = dblookup_table(db, 'sitechan');
db2 = dbsubset(db2, '(chan=~/[BES]H[ENZ]/  || chan=~/BDF/) && offdate == NULL');
db2 = dbjoin(db, db2);
db3 = dblookup_table(db, 'snetsta');
db3 = dbjoin(db2, db3);
%db3 = dbsubset(db3, 'snet=~/A[KTV]/');
latitude = dbgetv(db3, 'lat');
longitude = dbgetv(db3, 'lon');
elev = dbgetv(db3, 'elev');
staname = dbgetv(db3, 'sta');
channame = dbgetv(db3, 'chan');
net = dbgetv(db3, 'snet');
dbclose(db);

numstations = length(latitude);
for c=1:length(latitude)
    stadist(c) = deg2km(distance(lat, lon, latitude(c), longitude(c)));
end

% order the stations by distance
[y,i]=sort(stadist);
c=1;
while ((c<=numstations) && (stadist(i(c)) < distkm))
	station(c).name = staname{i(c)};
	station(c).channel = channame{i(c)};
	station(c).scnl = scnlobject(station(c).name, station(c).channel, net{i(c)});
	station(c).site.lon = longitude(i(c));
	station(c).site.lat = latitude(i(c));
	station(c).site.elev = elev(i(c));
	station(c).distance = stadist(i(c));
	c = c + 1;
end

% remove any duplicate stations
%[~,j]=unique({station.name});
%station = station(sort(j));

% limit the number of stations
numstations = min([maxsta numel(station)]);
station = station(1:numstations);

