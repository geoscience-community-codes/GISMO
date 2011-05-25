function catalog = aeic_total_catalog(varargin)

%AEIC_TOTAL_CATALOG Read in the complete AEIC Total earthquake catalog
%  CATALOG = AEIC_TOTAL_CATALOG reads the entire "Total" database of AEIC
%  earthquakes. The output field CATALOG is a structure containing field
%  names that adhere farily closely to their database definitions and
%  should be self explanatory. Origin time is given in Matlab date format.
%
% CATALOG = AEIC_TOTAL_CATALOG(DATABASE) specifies the path and name where
% the database can be found. If not specified the DATABASE name defaults to
% the location on the Seismology Linux Network. This function may work
% generically on other databases. However the table requirements and the
% preferred magnitude algorithm are tailoered specifically to the AEIC
% Total database.
%
% For each event AEIC_TOTAL_CATALOG distills the multiple possible 
% magnitudes into a single creates a "preferred magnitude" based on the 
% following order of preference:
%        1. Hrvd Mw
%        2. AEIC Mw
%        3. AEIC Ms
%        4. AEIC mb
%        5. AEIC ml
% Events with no magnitude are removed from the catalog. Md magnitudes are
% not currently considered (I believe tall Md magnitudes also have an ml).

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date:$
% $Revision:$


% CHECK ARGUMENTS
if ~antelope_exists
    error('This function requires Antelope');
end
if numel(varargin)>0
    dbName = varargin{1};
else
    dbName = '/home/admin/databases/AEIC_CATALOG/Total';
end;


% LOAD EVENTS FROM NETMAG TABLE WITH Mw MAGNITUDES
db = dbopen(dbName,'r');
db = dblookup(db,'','origin','','');
db1 = dblookup(db,'','netmag','','');
db = dbjoin(db,db1);
db = dbsubset(db,'magtype==''mw''');
[mw.orid,mw.magtype,mw.magnitude,mw.auth] = dbgetv(db,'orid','magtype','magnitude','netmag.auth');
dbclose(db);


% SELECT THE PREFERRED AUTH FOR Mw WHEN MULTIPLES EXIST
% Order hrvd before aeic
mw.auth = lower(mw.auth);
% order hrvd before aeic authored solutions
[tmp index] = sort(mw.auth);
index = flipud(index);
mw.orid = mw.orid(index);
mw.magtype = mw.magtype(index);
mw.magnitude = mw.magnitude(index);
mw.auth = mw.auth(index);
% remove duplicate Mw slecting prefered author
[tmp index tmp1] = unique(mw.orid);
mw.orid = mw.orid(index);
mw.magtype = mw.magtype(index);
mw.magnitude = mw.magnitude(index);
mw.auth = mw.auth(index);


% LOAD ORIGIN TABLE CATALOG
db = dbopen(dbName,'r');
db = dblookup(db,'','origin','','');
db = dbsort(db,'orid');
[catalog.time,catalog.lat,catalog.lon,catalog.depth,catalog.orid] = dbgetv(db,'time','lat','lon','depth','orid');
[catalog.nass,catalog.ndef,catalog.etype,catalog.auth] = dbgetv(db,'nass','ndef','etype','auth');
[catalog.ml,catalog.mb,catalog.ms] = dbgetv(db,'ml','mb','ms');
dbclose(db);
catalog.time = epoch2datenum(catalog.time);
f = find(catalog.ml==-999);     catalog.ml(f) = NaN;
f = find(catalog.mb==-999);     catalog.mb(f) = NaN;
f = find(catalog.ms==-999);     catalog.ms(f) = NaN;
catalog.mw = NaN * catalog.ml;


% ADD Mw TO ORIGIN CATALOG WHEN IT EXISTS
for n = 1:numel(mw.orid)
    f = find(catalog.orid==mw.orid(n));
    if numel(f)~=1
        error('orid mismatch');
    else
        catalog.mw(f) = mw.magnitude(n);
        %disp(['Updated orid ' num2str(catalog.orid(f)) '  ' num2str(mw.orid(n)) ]);
    end
end


% CREATE A PREFERRED MAGNITUDE
catalog.prefMagType = repmat({'none'},size(catalog.ml));
catalog.prefMagnitude = NaN * catalog.ml;
% set pref magnitude as ml
f = find(~isnan(catalog.ml));
catalog.prefMagType(f) = {'ml'};
catalog.prefMagnitude(f) = catalog.ml(f);
% set pref magnitude as mb
f = find(~isnan(catalog.mb));
catalog.prefMagType(f) = {'mb'};
catalog.prefMagnitude(f) = catalog.mb(f);
% set pref magnitude as ms
f = find(~isnan(catalog.ms));
catalog.prefMagType(f) = {'ms'};
catalog.prefMagnitude(f) = catalog.ms(f);
% set pref magnitude as mw
f = find(~isnan(catalog.mw));
catalog.prefMagType(f) = {'mw'};
catalog.prefMagnitude(f) = catalog.mw(f);


% REMOVE EVENTS WITH NO MAGNITUDE
f = find(~isnan(catalog.prefMagnitude));
numEventsAll = num2str(numel(catalog.prefMagnitude));
numEventsWithMag = num2str(numel(f));
catalog.time          = catalog.time(f);
catalog.lat           = catalog.lat(f);
catalog.lon           = catalog.lon(f);
catalog.depth         = catalog.depth(f);
catalog.orid          = catalog.orid(f);
catalog.nass          = catalog.nass(f);
catalog.ndef          = catalog.ndef(f);
catalog.etype         = catalog.etype(f);
catalog.auth          = catalog.auth(f);
catalog.ml            = catalog.ml(f);
catalog.mb            = catalog.mb(f);
catalog.ms            = catalog.ms(f);
catalog.mw            = catalog.mw(f);
catalog.prefMagType   = catalog.prefMagType(f);
catalog.prefMagnitude = catalog.prefMagnitude(f);


% STATUS LINE
dateEarliest = datestr(min(catalog.time),'yyyy/mm/dd HH:MM:SS');
dateMostRecent = datestr(max(catalog.time),'yyyy/mm/dd HH:MM:SS');
disp(['  Retrieved ' numEventsWithMag ' earthquakes with magnitudes (out of ' numEventsAll ' total)']);
disp(['       Earliest:    ' dateEarliest ]);
disp(['       Most recent: ' dateMostRecent ]);
disp('');

