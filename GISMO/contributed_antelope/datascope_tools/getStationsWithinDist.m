function station = getStationsWithinDist(lon, lat, distkm, dbstations, maxsta, snum, enum)
%GETSTATIONSWITHINDIST 
% station = getStationsWithinDist(lon, lat, distkm, dbstations, maxsta, snum, enum)
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
%	longitude	- station longitude
%	latitude	- station latitude
%	elev	- station elevation
%	distance	- distance (in km) from input (LON, LAT)
%
% Example: Get stations within 100km of (-150.0, 60.5) that were
% operational in 1990:
% s = getStationsWithinDist(-150.0, 60.5, 100.0, '/avort/oprun/dbmaster/master_stations', 10, datenum(1990,1,1), datenum(1991,1,1));

% AUTHOR: Glenn Thompson, UAF-GI
% $Date: $
% $Revision: -1 $
if ~exist('maxsta', 'var')
	maxsta = 999;
end
if ~exist(sprintf('%s.site',dbstations))
    dbstations = input('Please enter master stations path', 's')
end
disp(sprintf('master stations db is %s',dbstations))
db = dbopen(dbstations, 'r');

% Filter the site table
db = dblookup_table(db, 'site');
nrecs = dbquery(db, 'dbRECORD_COUNT');
disp(sprintf('Site table has %d records', nrecs));
db = dbsubset(db, sprintf('distance(lon, lat, %.4f, %.4f)<%.4f',lon,lat,km2deg(distkm)));
nrecs = dbquery(db, 'dbRECORD_COUNT');
disp(sprintf('After distance subset to lat %f and lon %f: %d records', lat, lon, nrecs));

if ~exist('snum', 'var')
    % No start time given, so assume we just want sites that exist today.
    % Remove any sites that have been decommissioned
    db = dbsubset(db, sprintf('offdate == NULL'));
else
    % Remove any sites that were decommissioned before the start time
    disp(sprintf('offdate == NULL || offdate > %s',datenum2julday(snum)));
    db = dbsubset(db, sprintf('offdate == NULL || offdate > %s',datenum2julday(snum)));
end
% Remove any sites that were installed after the end time (this may remove
% some sites that exist today)
if exist('enum', 'var')
    disp(sprintf('ondate  < %s',datenum2julday(enum)));
    db = dbsubset(db, sprintf('ondate  < %s',datenum2julday(enum)));
end
nrecs = dbquery(db, 'dbRECORD_COUNT');
disp(sprintf('After time subset: %d records', nrecs));

% Filter the sitechan table
db2 = dblookup_table(db, 'sitechan');
nrecs = dbquery(db2, 'dbRECORD_COUNT');
disp(sprintf('sitechan has %d records', nrecs));

db2 = dbsubset(db2, 'chan=~/[BES]H[ENZ]/  || chan=~/BD[FL]/');
nrecs = dbquery(db2, 'dbRECORD_COUNT');
disp(sprintf('After chan subset: %d records', nrecs));

if ~exist('snum', 'var')
    % No start time given, so assume we just want sites that exist today.
    % Remove any sites that have been decommissioned
    db2 = dbsubset(db2, sprintf('offdate == NULL'));
else
    % Remove any sites that were decommissioned before the start time
    disp(sprintf('offdate == NULL || offdate > %s',datenum2julday(snum)));
    db2 = dbsubset(db2, sprintf('offdate == NULL || offdate > %s',datenum2julday(snum)));
end
% Remove any sites that were installed after the end time (this may remove
% some sites that exist today)
if exist('enum', 'var')
    disp(sprintf('ondate  < %s',datenum2julday(enum)));
    db2 = dbsubset(db2, sprintf('ondate  < %s',datenum2julday(enum)));
end
nrecs = dbquery(db2, 'dbRECORD_COUNT');
disp(sprintf('After time subset: %d records', nrecs));

% Join site and sitechan
db2 = dbjoin(db, db2);
nrecs = dbquery(db2, 'dbRECORD_COUNT');
disp(sprintf('After join site-sitechan %d records', nrecs));

% Join to snetsta
db3 = dblookup_table(db, 'snetsta');
nrecs = dbquery(db3, 'dbRECORD_COUNT');
disp(sprintf('snetsta has %d records', nrecs));
db3 = dbjoin(db2, db3);
nrecs = dbquery(db3, 'dbRECORD_COUNT');
disp(sprintf('After join site-sitechan-snetsta: %d records', nrecs));

% Read net vector 
if nrecs == 0
    station = [];
    return
end
net = dbgetv(db3, 'snet');
if ~iscell(net)
    net = {net};
end

latitude = dbgetv(db3, 'lat');
longitude = dbgetv(db3, 'lon');
elev = dbgetv(db3, 'elev');
staname = dbgetv(db3, 'sta');
if ~iscell(staname)
	staname = {staname};
end
channame = dbgetv(db3, 'chan');
if ~iscell(channame)
	channame = {channame};
end
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
	station(c).longitude = longitude(i(c));
	station(c).latitude = latitude(i(c));
	station(c).elev = elev(i(c));
	station(c).distance = stadist(i(c));
	c = c + 1;
end

% remove any duplicate stations
%[~,j]=unique({station.name});
%station = station(sort(j));

% limit the number of stations
numstations = min([maxsta numel(station)]);
station = station(1:numstations);


