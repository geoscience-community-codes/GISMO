function c = adjusttrig(c,varargin)
   
   % ADJUSTTRIG  adjusts the trigger times of each trace
   %   C = ADJUSTTRIG(C) The first use below applies a uniform time shift to
   %   the triggers. All other uses adjust the trigger times based on the
   %   cross correlation lag times. These uses require the LAG field to be
   %   filled and delete it afterward.
   %
   %   C = ADJUSTTRIG(C,TIMESHIFT) Shifts all of the trigger times by TIMESHIFT
   %   seconds. A positive TIMESHIFT moves the zero alignment to the left on a
   %   trace plot, and a negative TIMESHIFT to the right. (Does not use or
   %   delete the LAG field.)
   %
   %   C = ADJUSTTRIG(C) Same as ADJUSTTRIG(C,'MIN') below.
   %
   %   C = ADJUSTTRIG(C,'MIN') Trigger times are adjusted relative to the trace with
   %   the minimum mean lag time. This is the default setting.
   %
   %   C = ADJUSTTRIG(C,'MEDIAN') trigger times are adjusted by their median lag
   %   time with all other traces. This can be advantageous when working within
   %   a single cluster of similar waveforms.
   %
   %   C = ADJUSTTRIG(C,'MIN',MAXLAG) removes all traces that are shifted by more
   %   than MAXLAG seconds. This approach is useful when you believe the
   %   original trigger times are already accurate to within MAXLAG seconds.
   %   This function can be duplicated as:
   %       lag = GET(C,'LAG');
   %       keep = find(abs(mean(lag))<MAXLAG)
   %       c = subset(C,keep);
   %
   %   C = ADJUSTTRIG(C,'INDEX') Trigger times are adjusted relative to the final
   %   trace in the waveform list. This position is often occupied by a stack of
   %   the other traces or some other master waveform. The INDEX method allows
   %   trace times to be adjusted relative to this master waveform.
   %
   %   C = ADJUSTTRIG(C,'INDEX',TRACENUM) Same as ADJUSTTRIG(c,'INDEX') except that
   %   traces are aligned relative to the trace specified by TRACENUM.
   %
   %   C = ADJUSTTRIG(C,'LSQ') Aligns traces by their least squares best fit delay
   %   time stored in the stat field. If GETSTAT has not been run yet, ADUSTTRIG
   %   will automatically call it.
   %
   %   NOTE that the different methods of adjusting the trigger times acheive
   %   quite different results because they are solving different problems.
   %   While this may seem obvious the results can be counter-intuitive, especially
   %   for the LSQ solver.
   
   % Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   % TODO: the current argument handling is done in a poor way that shows the
   % function's growth. It is currently not possible to use the MAXLAG argument
   % with the INDEX modifier. To change this, it would be best to rewrite the
   % argument handling.
   
   narginchk(1,3)  % min: (c), max: (c, method, value)
   
   if nargin == 1; 
      varargin(1) = {'MIN'};
   end
   
   adjustByMethod = ischar(varargin{1});
   adjustByTime = isnumeric(varargin{1});
   assert(adjustByMethod || adjustByTime, ...
      'unknown argument for either timeshift or method');
   
   if adjustByTime
      % varargin{1} is seconds to shift
      c.trig = c.trig + varargin{1}/86400; % change ALL triggers uniformly
      return
   end
   
   % Adjusting the traces via a specified method
    
   assert(~isempty(c.lags),...
      'LAG field must be filled in input object.\n See correlation/adjusttrig function');
   
   calctype = upper(varargin{1});
   
   if strncmp(calctype,'MIN',3) && (length(varargin)==2)
      c = alignTriggerTimes(c,calctype, varargin{2});
   else
      c = alignTriggerTimes(c, calctype, 0);
   end;
end

function c = alignTriggerTimes(c,alignMethod,index)
   switch alignMethod(1:3)
      case 'LSQ'
         [c, tshift] = leastSquaresAlign(c);
      case 'MIN'
         [c, tshift] = alignToMin(c);
      case 'MED'
         [c, tshift] = alignToMedian(c);
      case 'IND'
         % index contains the trace number of interest
         [c, tshift] = alignToTrace(c, index);
      case 'CLU'
         % index contains ???
         error('CLUSTER OPTION NOT FUNCTIONAL YET');
         c = alignToClusters(c, index);
      otherwise
         error('Unknown trigger adjustment method');
   end
   
   % "index" method is a bit ad hoc. It co-ops the "index" term, originally
   % created for the 'MIN' method.
      
   % remove traces shifted beyond MAXLAG
   
   if (index~=0)
      f = find(abs(tshift)<=index);
      c = subset(c,f);
   end;
end

function [c, tshift] = leastSquaresAlign(c)
   if size(c.stat,1)==0
      c = c.getstat();
   end;
   tshift = c.stat(:,4);
   c.trig = c.trig - tshift/86400;
   c.lags = [];
end

function [c, tshift] = alignToMin(c)
   [~,centerevent] = min(abs(mean(c.lags)));
   tshift = double(c.lags(centerevent,:)');	% in seconds
   c.trig = c.trig - tshift/86400;
   c.lags = [];
end

function [c, tshift] = alignToMedian(c)
   tshift = double(median(c.lags)');
   c.trig = c.trig - tshift/86400;
   c.lags = [];
end

function [c, tshift] = alignToTrace(c, traceNumber)
   assert(numel(traceNumber)==1 || numel(traceNumber)==0, ...
      'INDEX method must specify only a single value');
   if traceNumber==0
      traceNumber = c.ntraces;
   end
   tshift = double(c.lags(traceNumber,:)');	% in seconds
   c.trig = c.trig - tshift/86400;
   c.lags = [];
end

function [c, tshift] = alignToClusters(c, index)
   tshift = nan; %not included or figured out from code
   % NOT FUNCTIONAL YET
   DOLINK = size(c.link,1)==0;
   if DOLINK
      c = linkage(C);
   end
   
   DOCLUSTER = size(c.clust,1)==0;
   if DOCLUSTER
      c = cluster(c,.6);
   end
   
   % *** NEEDS NEW VERSION OF FIND WITH ORDERED CLUSTERS
   for n = 1:max(find(c,'big',2))   % do all clusters with more than 2 traces
      f = find(c.clust==n);
      c1 = subset(c,f);
      c1 = c1.adjusttrig('min',index);  % check use of index
      c.trig(f) = c1.trig;
      c.traces(f) = c1.traces;
   end
   
   if DOLINK
      c.link = [];
   end
   
   if DOCLUSTER
      c.clust = [];
   end
end