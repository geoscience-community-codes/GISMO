function site = db2stationcoordinates(staname, sitedb, epochdate);
% SITE = db2stationcoordinates(STANAME, SITEDB, EPOCHDATE) returns a structure containing the 
% longitude, latitude and elevation of station STANAME by reading a Datascope site database.
%
% If EPOCHDATE is given, ondate & offdate are checked against this for a
% match. Otherwise, only currently defined sites - records with a null offdate - are matched.
%
% AUTHOR: Glenn Thompson, UAF-GI
% $Date: $
% $Revision: -1 $

% SET NULLS
site.latitude = NaN;
site.longitude = NaN;
site.elev = NaN;

% GET THE CORRECT STATION RECORD FORM THE SITE TABLE
db = dbopen(sitedb, 'r');
db = dblookup_table(db, 'site');
debug.print_debug(4, 'Processing %s',staname);
if exist('epochdate', 'var')
    db2 = dbsubset(db, sprintf('(sta == "%s") && (ondate <= %f) && (offdate >= %f)',staname,epochdate,epochdate));
    if dbquery(db2, 'dbRECORD_COUNT')==0
        db2 = dbsubset(db, sprintf('(sta == "%s") && (ondate <= %f) && (offdate == NULL)',staname,epochdate));
    end
    if dbquery(db2, 'dbRECORD_COUNT')==0
        db2 = dbsubset(db, sprintf('sta == "%s" && offdate == NULL',staname));
    end
else
    db2 = dbsubset(db, sprintf('sta == "%s" && offdate == NULL',staname));
end

% GET THE STATION COORDINATES
if dbquery(db2, 'dbRECORD_COUNT') > 0
	site.latitude = dbgetv(db2, 'lat');
	site.longitude = dbgetv(db2, 'lon');
	site.elev = dbgetv(db2, 'elev');
end
dbclose(db);


