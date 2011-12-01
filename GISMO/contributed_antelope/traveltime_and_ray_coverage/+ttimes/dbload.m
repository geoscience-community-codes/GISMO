function [origin,site,arrival,ray] = dbload(dbName)

%DBLOAD extracts travel times from a database
% [ORIGIN,SITE,ARRIVAL,RAY] = DBLOAD(DBNAME) reads an Antelope database
% DBNAME and creates structures with information needed to explore the
% traveltime and ray coverage of an earthquake catalog. DBNAME must contain
% the following tables: origin, event, assoc, arrival and site Antelope
% database tables.
% 
%
% -- OUTPUT ARGUMENTS --
%
% ORIGIN
% This is a minimally populated catalog object (see help catalog) that
% describes the earthquake hypocenters. It includes the fields lat, lon,
% depth (km, positive down), origin time (Matlab datenum format) and origin
% id (orid). One element for each earthquake.
%
% ARRIVAL
% This structure describes the phase arrivals. Fields include station name
% (sta), phase name (iphase), travel time (seconds), timeRes (modeled
% travel time residual. specifically it is the observed travel time minus
% the model predicted travel time) and orid. One element for each pahse
% arrival.
%
% RAY
% This structure crudely describes the ray path coverage. It's elements are
% the same length as the elements of arrival. They include originLat,
% otiginLon, originDepth (km, positive down), siteLat, siteLon, siteElev
% (km, positive down) and flatDist (the horizontal distance in km between
% the origin and and site. RAY contains information that is redundant to
% other structures. it exists to allow faster plotting of ray paths.
%
% STATION
% This structure descibes the stations. Fields include sta (station name),
% lat, lon, elevation. STATION has one element for each station. Only
% stations that have at least one phase arrival are included.
%
%
% CAVEATS
% Only P and S phase arrivals are loaded from the database since the goal
% of the ttimes package is to prepare local/regional scale tomography data.
% Because there are so many ways users might wish to cull the dataset, this
% is best done directly on the database before final application of this
% function. No subsetting functions are included here.
% 
% See also ttimes.map ttimes.depth_section ttimes.tt_curve
% ttimes.arrival_histogram ttimes.write_lotos ttimes.do_all


% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date: 2010-07-02 ls14:24:55 -0800 (Fri, 02 Jul 2010) $
% $Revision: 242 $ 



% CHECK FOR VALID DATABASE
if ~admin.antelope_exists
   error('This function requires the Antelope toolbox for Matlab'); 
end


try
    db = dbopen(dbName,'r');
    dbclose(db);
catch
    error(['Could not open database: ' dbName]);
end


% FOR DEBUGGING
%  dbName = '/Users/west/FIELDDATA/doc/database/origin/2009april-2010april/reviewed';
%  [origin,site,arrival,ray] = ttimes.dbload(dbName);

%% ACCESS DATABASE
% CREATE DATABASE VIEW 
try
    % Entire database
    db = dbopen(dbName,'r');
    
    % Event view
    db = dblookup_table(db,'origin');
    db1 = dblookup_table(db,'event');
    db = dbjoin(db,db1);
    db = dbsubset(db,'orid==prefor');
    nEvents = dbquery(db,'dbRECORD_COUNT');
    oridList = dbgetv(db,'orid');
    %disp(['Number of origins: ' num2str(nEvents) ]);
    [tmp.lat,tmp.lon,tmp.depth,tmp.time,tmp.orid] = dbgetv(db,'origin.lat','origin.lon','origin.depth','origin.time','origin.orid');
    tmp.time = epoch2datenum(tmp.time);
    origin = catalog;
    origin = set(origin,'LAT',tmp.lat,'LON',tmp.lon,'DEPTH',tmp.depth,'DNUM',tmp.time,'ORID',tmp.orid);
    
    % Arrival view
    db1 = dblookup_table(db,'assoc');
    db = dbjoin(db,db1);
    db1 = dblookup_table(db,'arrival');
    db = dbjoin(db,db1);
    db = dbsubset(db,'iphase=="S" || iphase=="P"');
    db1 = dblookup_table(db,'site');
    db = dbjoin(db,db1);
    nArrivals = dbquery(db,'dbRECORD_COUNT');
    %disp(['Number of arrivals: ' num2str(nArrivals) ]);
    [arrival.sta,arrival.iphase,arrival.time,arrival.timeres,arrival.orid] = dbgetv(db,'arrival.sta','arrival.iphase','arrival.time','timeres','orid');
    arrival.time = epoch2datenum(arrival.time);

    % Ray view
    [ray.originLat,ray.originLon,ray.originDepth,ray.siteLat,ray.siteLon,ray.siteElev] = dbgetv(db,'origin.lat','origin.lon','origin.depth','site.lat','site.lon','site.elev');
    ray.siteElev = -1*ray.siteElev;
    ray.flatDist = deg2km(distance(ray.originLat,ray.originLon,ray.siteLat,ray.siteLon));
    
    
    % Site view
    [tmp.sta,tmp.lon,tmp.lat,tmp.elev] = dbgetv(db,'site.sta','site.lon','site.lat','site.elev');
    tmp.elev = -1*tmp.elev;
    site = [];
    [site.sta,m,~] = unique(tmp.sta);
    site.lat = tmp.lat(m);
    site.lon = tmp.lon(m);
    site.elev = tmp.elev(m);

catch
    error(['Problems with one or more database tables (origin, event, assoc, arrival, site)']);
end
dbclose(db);



% CREATE TRAVELTIME
for n = 1:numel(origin.orid)
    f = find(arrival.orid==origin.orid(n));
    arrival.travelTime(f) = 86400*(arrival.time(f)-origin.dnum(n));
end
arrival.travelTime = arrival.travelTime';
arrival.predTravelTime = arrival.travelTime + arrival.timeres;



