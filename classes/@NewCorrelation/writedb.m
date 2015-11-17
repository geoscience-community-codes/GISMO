function writedb(c,dbOut,varargin)

%WRITEDB write antelope database tables
%  WRITEDB(C,DBOUT) writes an arrival table into the database DBOUT. The
%  arrival contains the station and channel names. The phase arrival time
%  is set to the trigger field in the correlation object. If the cluster
%  field is filled in C, then the phase names are assigned as cXX where XX
%  is the cluster number. If the cluster field is not filled, a default
%  phase name of P is assigned. If the table DBOUT.arrival already exists,
%  new entries are appended to it. Duplicate entries to the database will
%  NOT be skipped.
%
%  WRITEDB(C,DBOUT,PHASENAME) Assign an explicit PHASENAME. PHASENAME is
%  a cell array containing character phase names. The cell array must be
%  of length 1 or of length N, where N is the number of traces in the
%  corelation object.
% 
%  WRITEDB(C,DBOUT,'detection') Writes a detection table instead of an
%  arrival table. The filter field is left null by default. Rows for
%  detection ON and OFF states are not included. On state='D' rows are
%  written.
%
%  WRITEDB(C,DBOUT,'detection','filterString') Fills the filter field on
%  the detection table with the string given by filterString.
%
%  WRITEDB checks for the Antelope toolbox for Matlab. If it does not
%  exist, WRITEDB writes a simple text file DBOUT.txt which contains
%  station, channel, arrival times and phase names.


% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



% READ & CHECK ARGUMENTS
if numel(varargin)>2
    error('Wrong number of inputs');
end;

if ~ischar(dbOut)
    disp('Second input parameter must be a text string');
end

if ~isempty(get(c,'LAG'))
    disp('Note: Time corrections from LAG field have not been applied to traces. Consider using ADJUSTTRIG prior to writing out');
    disp(' ');
end;


% SELECT TABLE TYPE
ISDETECTION = 0;
if numel(varargin)>=1 || ~admin.antelope_exists
    if strcmpi(varargin{1},'detection')
        ISDETECTION = 1;
    end
end


% ASSIGN ARGUMENTS FOR ARRIVAL TABLE
if ~ISDETECTION
    if numel(varargin)==1
        phaseList = varargin{1};
        if numel(phaseList)== c.ntraces
            phaseList = phaseList;
        elseif numel(phaseList)~= c.ntraces && numel(phaseList)~=1
            error('phase list argument must be cell array of length 1 or N, where N is the number of traces in the correlation object');
        elseif numel(phaseList)==1
            if ischar(phaseList)
                phaseList = {phaseList};
            end
            phaseList = repmat(phaseList, c.ntraces,1);
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
        phaseList = repmat({'P'},c.ntraces,1);
    end;
    
end

    
    
% ASSIGN ARGUMENTS FOR DETECTION TABLE
if ISDETECTION
    if numel(varargin)>=2
        if ischar(varargin{2})
            filterString = varargin(2);
        elseif iscell(varargin{2}) && (numel(varargin{2})==1)
            filterString = varargin{2};
        end
    else
        filterString = 'not_specified';
    end
end

        
        

% WRITE ARRIVAL TABLE OR TEXT FILE
if ~ISDETECTION
    trig = get(c,'TRIG');
    sta = get(c,'STATION'); %sta = sta{1};
    chan = get(c,'CHANNEL'); %chan = chan{1};
    if admin.antelope_exists
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
end



% WRITE DETECTION TABLE
if ISDETECTION
    trig = get(c,'TRIG');
    sta = get(c,'STATION');
    chan = get(c,'CHANNEL');
    % TODO: check for database table
    disp(['Writing database table ' dbOut '.detection']);
    db = dbopen(dbOut,'r+');
    db = dblookup(db,'','detection','','');
    nMax = length(trig);
    disp('     ');
    for n = 1:nMax
        arid = dbnextid( db,'arid');
        db.record = dbaddv(db,'sta',sta{n},'chan',chan{n},'time',datenum2epoch(trig(n)),'state','D','filter',filterString);
        fprintf('\b\b\b\b\b\b%5.0f%%',n/nMax*100);
    end
    fprintf('\n');
    dbclose(db);
    
    
    
end




