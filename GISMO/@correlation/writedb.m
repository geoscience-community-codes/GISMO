function writedb(c,dbOut,varargin)

%WRITEDB write antelope database tables
%  WRITEDB(C) writes an arrival table containing information pulled from
%  the correlation object.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date: $
% $Revision: $


    


% FOR TESTING ONLY %%%%%%%%%%%%%%%%%%%%%%%%
error('This function is still in development. Sorry - MEW');
c = correlation('demo');
phaseList = 'P';
dbOut = 'junk';


% READ & CHECK ARGUMENTS
if (numel(varargin>1))
    error('Wrong number of inputs');
end;

if ~isa(c,'correlation')
    disp('First input parameter must be a correlation object');
end

if ~isempty(get(c,'LAG'))
    disp('Note: Time corrections from LAG field have not been applied to traces. Consider using ADJUSTTRIG prior to writing out');
end;


% SET UP PHASE NAMES
if (numel(varargin==1))
    phaseList = varargin{1};
    if numel(phaseList)==get(c,'TRACES')
        phaseList = phaseList;
    elseif numel(phaseList)~=get(c,'TRACES') && numel(phaseList)~=1
        error('phase list argument must be of length 1 or N where N is the number of traces in the correlation object');
    elseif numel(phaseList)==1
        if ~isa(phaseList,'char')
            error('Phase name must be a character string');
        end
        phaseList = repmat(phaseList,get(c,'TRACES'),1);    
    end
elseif ~isempty(get(c,'CLUST'))
    disp('assigning phase names based on cluster field');
    phaseList = num2str(get(c,'CLUST'));    
else
    disp('assigning default phase name P');
    phaseList = repmat('P',get(c,'TRACES'),1);
end;


% 1 - check for explicit phase name array or scalar
% 2 - check for clusters
% 3 - assign default




trig = get(c,'TRIG');
sta = get(c,'STATION'); sta = sta{1};
chan = get(c,'CHANNEL'); chan = chan{1};

if antelope_exists
    % write out database table
    disp(['Writing table ' dbOut '.arrival']);
    db = dbopen(dbOut,'r+');
    db = dblookup(db,'','arrival','','');
    for n = 1:numel(trig)
        db.record = dbaddv(db,'sta',sta,'chan',chan,'time',datenum2epoch(trig(n)),'iphase',iphase)
    end    
    dbclose(db);
     
else
    % write out a simple text file
    disp(['Antelope toolbox not found. Writing text file ' dbOut '.txt instead']);
    fid = fopen([dbOut '.txt'],'w');
    for n = 1:numel(trig)
        fprintf(fid,'%7s %7s %s %5s\n',sta,chan,datestr(trig(n),'yyyy/mm/dd HH:MM:SS.FFF'),phaseList(n))
    end     
    fclose(fid);
end
    
    
    
    