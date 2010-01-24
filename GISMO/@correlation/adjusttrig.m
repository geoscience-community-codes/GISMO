function c = adjusttrig(c,varargin);

% ADJUSTTRIG adjusts the trigger times of each trace. The first use below
% applies a uniform time shift to the triggers. All other uses adjust the
% trigger times based on the cross correlation lag times. These uses
% require the LAG field to be filled and delete it afterward.
% 
% ADJUSTTRIG(c,TIMESHIFT)
% Shifts all of the trigger times by TIMESHIFT seconds. A positive
% TIMESHIFT moves the zero alignment to the left on a trace plot, and a
% negative TIMESHIFT to the right. (Does not use or delete the LAG field.)
%
% ADJUSTTRIG(c)
% Same as ADJUSTTRIG(c,'MIN') below.
%
% ADJUSTTRIG(c,'MIN')
% Trigger times are adjusted relative to the trace with the minimum mean 
% lag time. This is the default setting.
%
% ADJUSTTRIG(c,'MIN',MAXLAG) removes all traces that are shifted by more than 
% MAXLAG seconds. This approach is useful when you believe the original
% trigger 
% times are already accurate to within MAXLAG seconds. This function can be
% duplicated as:
%	lag = GET(c,'LAG');
%	keep = find(abs(mean(lag))<MAXLAG)
%	c = subset(c,keep);
%
% ADJUSTTRIG(c,'INDEX')
% Trigger times are adjusted relative to the final trace in the waveform
% list. This position is often occupied by a stack of the other traces or
% some other master waveform. The INDEX method allows trace times to be
% adjusted relative to this master waveform.
%
% ADJUSTTRIG(c,'INDEX',TRACENUM)
% Same as ADJUSTTRIG(c,'INDEX') except that traces are aligned relative to
% the trace specified by TRACENUM.
%
% ADJUSTTRIG(c,'LSQ')
% Aligns traces by their least squares best fit delay time stored in the
% stat field. If GETSTAT has not been run yet, ADUSTTRIG will automatically
% call it.
% 
% NOTE that the different methods of adjusting the trigger times acheive 
% quite different results because they are solving different problems. 
% While this may seem obvious the results can be counter-intuitive, especially 
% for the LSQ solver.

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks



% CHECK ARGUMENTS
if ~strcmpi(class(c),'correlation')
    error('First input must be a correlation object');
end;
if length(varargin)>2
	error('Too many arguments');
end;


% SELECT SUBROUTINE
if length(varargin)>=1 && isa(varargin{1},'double')      % use shifttriggers
    trigshift = varargin{1};
    c = shifttriggers(c,trigshift);
else
    % check if LAG field in filled                    % use adjusttriggers
    if isempty(get(c,'LAG'))
        error('LAG field must be filled in input object');
        error('See correlation/adjusttrig function');
    end;
    if length(varargin)>=1 && isa(varargin{1},'char')
        calctype = upper(varargin{1});
    else
        calctype = 'MIN';	% default
    end;
    if length(varargin)==2
        dosubset = varargin{2};
    else
        dosubset = 0;
    end;
    c = adjusttriggers(c,calctype,dosubset);
end


% SHIFT TRIGGER TIMES UNIFORMLY
function c = shifttriggers(c,trigshift)
c.trig = c.trig + trigshift/86400;


% ALIGN TRIGGER TIMES
function c = adjusttriggers(c,calctype,index)


if calctype(1:3)=='LSQ'
    if size(c.stat,1)==0
        c = getstat(c);
    end;
    tshift = c.stat(:,4);
    c.trig = c.trig - tshift/86400;
    c.L = [];

elseif calctype(1:3)=='MIN'
    [tmp,centerevent] = min(abs(mean(c.L)));
    tshift = double(c.L(centerevent,:)');	% in seconds
    c.trig = c.trig - tshift/86400;
    c.L = [];

% "index" method is a bit ad hoc. It co-ops the "index" term, originally
% created for the 'MIN' method.
elseif calctype(1:3)=='IND'
    if length(index) > 1
        error('INDEX method must specify only a single value');
    elseif index==0
       index = get(c,'TRACES'); 
    end
    tshift = double(c.L(index,:)');	% in seconds
    c.trig = c.trig - tshift/86400;
    c.L = [];

elseif calctype(1:3)=='CLU'
    disp('CLUSTER OPTION NOT FUNCTIONAL YET');
    if size(c.link,1)==0
        c = linkage(c);
        DOLINK = 1;
    end;
    if size(c.clust,1)==0
        c = cluster(c,.6);
        DOCLUST = 1;
    end;
    % *** NEEDS NEW VERSION OF FIND WITH ORDERED CLUSTERS
    for n = 1:max(find(c,'big',2))   % do all clusters with more than 2 traces
        f = find(c.clust==n);
        c1 = subset(c,f);
        c1 = adjusttrig(c1,'min',index);  % check use of index
        c.trig(f) = c1.trig;
        c.W(f) = c1.W;
    end
    if DOLINK==1
       c.link = []; 
    end
    if DOCLUSTER==1
       c.clust = []; 
    end
    
else
    disp('Argument not recognized');
end;


% remove traces shifted beyond MAXLAG

if (index~=0) 
    f = find(abs(tshift)<=index);
    c = subset(c,f);
end;

