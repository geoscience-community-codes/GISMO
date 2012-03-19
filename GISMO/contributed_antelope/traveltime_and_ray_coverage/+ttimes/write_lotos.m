function write_lotos(dbName)

%WRITE_LOTOS write files for LOTOS tomography codes. 
% WRITE_LOTOS(dbName) creates two files in the current directory called
% rays.dat and stat_ft.dat. These are suitable input for the LOTOS
% tomography codes. For information about the LOTOS codes, see:
%    Koulakov, I. (2009), BSSA, 194?214, doi:10.1785/0120080013.
%
% see also ttimes.dbload

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date: 2010-07-02 14:24:55 -0800 (Fri, 02 Jul 2010) $
% $Revision: 242 $ 



% LOAD DATABASE
[origin,site,arrival,ray] = ttimes.dbload(dbName);


% ADD STATION NUMBERS
site.stationNum = 1:numel(site.sta);
for n = 1:numel(site.stationNum)
    f = find(strcmp(site.sta(n),arrival.sta));
   arrival.stationNum(f) = site.stationNum(n); 
end
arrival.stationNum =  arrival.stationNum';
 

% CREATE PHASE NUMBER PARAMETER
f = find(strcmp(arrival.iphase,'P'));
arrival.phaseNum(f) = 1;
f = find(strcmp(arrival.iphase,'S'));
arrival.phaseNum(f) = 2;
f = find( ~strcmp(arrival.iphase,'S') & ~strcmp(arrival.iphase,'P') );
if ~isempty(f)
    error('Problem parsing S and P phase names');
end
arrival.phaseNum = arrival.phaseNum';


% WRITE RAY FILE
fid = fopen('rays.dat','w');
for n = 1:numel(origin.orid)
    f = find(arrival.orid==origin.orid(n));
    fprintf(fid,'%15.5f%15.5f%15.5f%15.0f     %s\n',origin.lon(n),origin.lat(n),origin.depth(n),numel(f),datestr(origin.dnum(n),'yyyy-mm-dd HH:MM:SS'));
    for nArr = 1:numel(f)
        index = f(nArr);
        fprintf(fid,'%15.0f%8.0f%12.5f\n',arrival.phaseNum(index),arrival.stationNum(index),arrival.travelTime(index));
    end
end
fclose(fid);
    

% WRITE STATION FILE
fid = fopen('stat_ft.dat','w');
for n = 1:max(site.stationNum)
    fprintf(fid,'%15.5f%15.5f%15.5f%15s\n',site.lon(n),site.lat(n),site.elev(n),site.sta{n});
end
fclose(fid);

