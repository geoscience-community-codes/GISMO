function writedb(c,dbOut,varargin)

%WRITEDB write antelope database tables
%  WRITEDB(C,DBOUT) writes an arrival table into the database DBOUT. 
%  The arrival contains the station and channel names. The phase arrival
%  time is set to trigger field in the correlation object. If the cluster
%  field is filled in C, then the phase names are assigned as cXX where
%  XX is the cluster number. If the cluster field is not filled, a default
%  phase name of P is assigned. If the table DBOUT.arrival already exists,
%  new entries are appended to it. Duplicate entries to the database will
%  not be skipped.
%
%  WRITEDB(C,DBOUT,PHASENAME) Assign an explicit PHASENAME.
% 
%  WRITEDB checks for the Antelope toolbox for Matlab. If it does not
%  exist, WRITEDB writes a simple text file DBOUT.txt which contains
%  station, channel, arrival times and phase names.


% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date: $
% $Revision: $



% READ & CHECK ARGUMENTS
if numel(varargin)>1
    error('Wrong number of inputs');
end;

if ~isa(c,'correlation')
    disp('First input parameter must be a correlation object');
end

if ~isa(dbOut,'char')
    disp('Second input parameter must be a text string');
end

if ~isempty(get(c,'LAG'))
    disp('Note: Time corrections from LAG field have not been applied to traces. Consider using ADJUSTTRIG prior to writing out');
    disp(' ');
end;



% SET UP PHASE NAMES
if numel(varargin)==1
    phaseList = varargin{1};
    if numel(phaseList)==get(c,'TRACES')
        phaseList = phaseList;
    elseif numel(phaseList)~=get(c,'TRACES') && numel(phaseList)~=1
        error('phase list argument must be of length 1 or of length N, where N is the number of traces in the correlation object');
    elseif numel(phaseList)==1
        if ~isa(phaseList,'char')
            error('Phase name must be a string of 4 or fewer characters');
        end
        phaseList = repmat({phaseList},get(c,'TRACES'),1);
    end
elseif ~isempty(get(c,'CLUST'))
    disp('assigning phase names based on cluster field');
    clust = get(c,'CLUST');
    phaseList = cell(size(clust));
    for n = 1:numel(clust)
        phaseList(n) = {['c' num2str(clust(n),'%02.0f')]};
    end
else
    disp('assigning default phase name "P"');
    phaseList = repmat({'P'},get(c,'TRACES'),1);
end;



% WRITE DATABASE OR TEXT FILE
trig = get(c,'TRIG');
sta = get(c,'STATION'); %sta = sta{1};
chan = get(c,'CHANNEL'); %chan = chan{1};
if antelope_exists
    % TODO: check for database table
    disp(['Writing database table ' dbOut '.arrival']);
    db = dbopen(dbOut,'r+');
    db = dblookup(db,'','arrival','','');
    nMax = length(trig);
    disp('     ');
    for n = 1:nMax
        arid = dbnextid( db,'arid');
        db.record = dbaddv(db,'sta',sta{n},'chan',chan{n},'time',datenum2epoch(trig(n)),'iphase',phaseList{n},'auth','corr/writedb');
        fprintf('\b\b\b\b\b\b%5.0f%%',n/nMax*100);
    end    
    fprintf('\n');
    dbclose(db);
else
    % write out a simple text file
    disp(['Antelope toolbox not found. Writing text file ' dbOut '.txt instead']);
    fid = fopen([dbOut '.txt'],'w');
    for n = 1:numel(trig)
        fprintf(fid,'%-7s %-7s %-s %5s\n',sta,chan,datestr(trig(n),'yyyy/mm/dd HH:MM:SS.FFF'),phaseList{n});
    end     
    fclose(fid);
end
    
    
    
    