function sites = get_closest_sites(lon, lat, distkm, sitesdb, maxsta, snum, enum, chanmatch)
%GET_CLOSEST_SITES 
% sites = get_closest_sites(lon, lat, distkm, sitesdb, maxsta, snum, enum, chanmatch)
% load sites within distkm km of a given (LON, LAT) 
% from site database sitesdb
%
% The sites structure returned has the followed fields:
%	channeltag - net.sta.loc.chan a channeltag object
%	longitude	- sites longitude
%	latitude	- sites latitude
%	elev	- sites elevation
%	distance	- distance (in km) from input (LON, LAT)
%
% Example: Get sites within 100km of (-150.0, 60.5) that were
% operational in 1990:
% sites = get_closest_sites(-150.0, 60.5, 100.0, '/avort/oprun/dbmaster/master_stations', 10, datenum(1990,1,1), datenum(1991,1,1));

% AUTHOR: Glenn Thompson, UAF-GI
% $Date: $
% $Revision: -1 $
if ~exist('maxsta', 'var')
	maxsta = 999;
end
% if ~exist(sprintf('%s.site',sitesdb))
%     sitesdb = input('Please enter sites database path', 's')
% end
debug.print_debug(1,sprintf('sites db is %s',sitesdb))
dbptr = dbopen(sitesdb, 'r');

% Filter the site table
dbptr_site = dblookup_table(dbptr, 'site');
nrecs = dbquery(dbptr_site, 'dbRECORD_COUNT');
debug.print_debug(2,sprintf('Site table has %d records', nrecs));
dbptr_site = dbsubset(dbptr_site, sprintf('distance(lon, lat, %.4f, %.4f)<%.4f',lon,lat,km2deg(distkm)));
nrecs = dbquery(dbptr_site, 'dbRECORD_COUNT');
debug.print_debug(2,sprintf('After distance subset to lat %f and lon %f: %d records', lat, lon, nrecs));

if ~exist('snum', 'var')
    % No start time given, so assume we just want sites that exist today.
    % Remove any sites that have been decommissioned
    dbptr_site = dbsubset(dbptr_site, sprintf('offdate == NULL'));
else
    % Remove any sites that were decommissioned before the start time
    debug.print_debug(2,sprintf('offdate == NULL || offdate > %s',datenum2julday(snum)));
    dbptr_site = dbsubset(dbptr_site, sprintf('offdate == NULL || offdate > %s',datenum2julday(snum)));
end
% Remove any sites that were installed after the end time (this may remove
% some sites that exist today)
if exist('enum', 'var')
    debug.print_debug(2, sprintf('ondate  < %s',datenum2julday(enum)));
    dbptr_site = dbsubset(dbptr_site, sprintf('ondate  < %s',datenum2julday(enum)));
end
nrecs = dbquery(dbptr_site, 'dbRECORD_COUNT');
debug.print_debug(2,sprintf('After time subset: %d records', nrecs));
%dbgetv(db, 'sta')

% Filter the sitechan table
dbptr_sitechan = dblookup_table(dbptr, 'sitechan');
nrecs = dbquery(dbptr_sitechan, 'dbRECORD_COUNT');
debug.print_debug(2,sprintf('sitechan has %d records', nrecs));

if exist('chanmatch','var')
    dbptr_sitechan = dbsubset(dbptr_sitechan, chanmatch);
    nrecs = dbquery(dbptr_sitechan, 'dbRECORD_COUNT');
    debug.print_debug(2,sprintf('After chan subset: %d records', nrecs));
end

if ~exist('snum', 'var')
    % No start time given, so assume we just want sites that exist today.
    % Remove any sites that have been decommissioned
    dbptr_sitechan = dbsubset(dbptr_sitechan, sprintf('offdate == NULL'));
else
    % Remove any sites that were decommissioned before the start time
    debug.print_debug(2,sprintf('offdate == NULL || offdate > %s',datenum2julday(snum)));
    dbptr_sitechan = dbsubset(dbptr_sitechan, sprintf('offdate == NULL || offdate > %s',datenum2julday(snum)));
end
% Remove any sites that were installed after the end time (this may remove
% some sites that exist today)
if exist('enum', 'var')
    debug.print_debug(2,sprintf('ondate  < %s',datenum2julday(enum)));
    dbptr_sitechan = dbsubset(dbptr_sitechan, sprintf('ondate  < %s',datenum2julday(enum)));
end
nrecs = dbquery(dbptr_sitechan, 'dbRECORD_COUNT');
debug.print_debug(2,sprintf('After time subset: %d records', nrecs));
%dbgetv(dbptr_sitechan, 'sta')

% Join site and sitechan
dbptr_sitechan = dbjoin(dbptr_site, dbptr_sitechan);
nrecs = dbquery(dbptr_sitechan, 'dbRECORD_COUNT');
debug.print_debug(2,sprintf('After join site-sitechan %d records', nrecs));
%dbgetv(dbptr_sitechan, 'sta')

% Read snetsta to get network code
dbptr_snetsta = dblookup_table(dbptr, 'snetsta');
nrecs = dbquery(dbptr_snetsta, 'dbRECORD_COUNT');
debug.print_debug(2,sprintf('snetsta has %d records', nrecs));
dbptr_snetsta = dbjoin(dbptr_sitechan, dbptr_snetsta);
nrecs = dbquery(dbptr_snetsta, 'dbRECORD_COUNT');
debug.print_debug(2,sprintf('After join site-sitechan-snetsta: %d records', nrecs));
snet = dbgetv(dbptr_snetsta, 'snet');
sta = dbgetv(dbptr_snetsta, 'sta');
stanetmap = containers.Map();
for c=1:numel(sta)
    stanetmap(sta{c}) = snet{c};
end
    
% If there is a calibration table, get the calib value and units
dbptr_calibration = dblookup_table(dbptr, 'calibration');
nrecs = dbquery(dbptr_calibration, 'dbRECORD_COUNT');
debug.print_debug(2,sprintf('calibration has %d records', nrecs));
%dbptr_calibration = dbjoin(dbptr_sitechan, dbptr_calibration,
%{'sta';'chan'}, {'sta';'chan'}); % danger with this is no subset on ondate/offdate
dbptr_calibration = dbjoin(dbptr_sitechan, dbptr_calibration);
dbptr_calibration = dbsubset(dbptr_calibration, 'sitechan.sta == calibration.sta && sitechan.chan == calibration.chan');
nrecs = dbquery(dbptr_calibration, 'dbRECORD_COUNT');
debug.print_debug(2,sprintf('After join site-sitechan-calibration: %d records', nrecs));


% Read data from final view
if nrecs == 0
    sites = [];
    return
end
% net = dbgetv(db4, 'snet');
% if ~iscell(net)
%     net = {net};
% end

latitude = dbgetv(dbptr_calibration, 'lat');
longitude = dbgetv(dbptr_calibration, 'lon');
elev = dbgetv(dbptr_calibration, 'elev');
staname = dbgetv(dbptr_calibration, 'sta');
if ~iscell(staname)
	staname = {staname};
end
channame = dbgetv(dbptr_calibration, 'chan');
if ~iscell(channame)
	channame = {channame};
end
ondate = dbgetv(dbptr_calibration, 'sitechan.ondate');
offdate = dbgetv(dbptr_calibration, 'sitechan.offdate');
calib = dbgetv(dbptr_calibration, 'calibration.calib');
units = dbgetv(dbptr_calibration, 'calibration.units');
dbclose(dbptr);


% Reformat data into sites return structure
numsites = numel(latitude);
for c=1:numsites
    yyyy = floor(ondate(c)/1000);
    if yyyy>1900
        jjj = ondate(c)-yyyy*1000;
        ondnum(c) = datenum(yyyy,1,jjj);
    else
        ondnum(c)=-Inf;
    end
end

for c=1:numsites
    yyyy = floor(offdate(c)/1000);
    if yyyy>1900
        jjj = offdate(c)-yyyy*1000;
        offdnum(c) = datenum(yyyy,1,jjj);
    else
       offdnum(c) = Inf; 
    end
end

for c=1:numsites
    stadist(c) = deg2km(distance(lat, lon, latitude(c), longitude(c)));
end

% order the sites by distance
[y,i]=sort(stadist);
c=1;
while ((c<=numsites) && (stadist(i(c)) < distkm))
	%sites(c).name = staname{i(c)};
	%sites(c).channel = channame{i(c)};
	%sites(c).scnl = scnlobject(sites(c).name, sites(c).channel, net{i(c)});
    sta = staname{i(c)};
    chan = channame{i(c)};
    net = stanetmap(sta);
    sites(c).channeltag = channeltag(net, sta, '', chan);
	sites(c).longitude = longitude(i(c));
	sites(c).latitude = latitude(i(c));
	sites(c).elev = elev(i(c));
	sites(c).distance = stadist(i(c));
    sites(c).ondnum = ondnum(i(c));
    sites(c).offdnum = offdnum(i(c));
    sites(c).calib = calib(i(c));
    sites(c).units = units(i(c));
	c = c + 1;
end

% remove any duplicate sites
%[~,j]=unique({sites.name});
%sites = sites(sort(j));

% limit the number of sites
numsites = min([maxsta numel(sites)]);
sites = sites(1:numsites);




