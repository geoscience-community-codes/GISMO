classdef Tracefilter
   %Tracefilter Simple filtering for Traces
   %   replaces filterobject
   
   properties
      type = 'B';  % could be 'B'andpass, 'H'ighpass, or 'L'lowpass
      cutoff = [0.8 5];  % filter cutoffs [lower bound, upper bound]
      poles = 2;
      
   end
   
   methods
      function f = Tracefilter(filtType, cutoff_, poles_)
         % TRACEFILTER constructor for a filter object
         switch nargin
            case 1
               if isa(filtType,'filterobject')
                  % convert from the old filterobject
                  f.type = get(filtType,'type');
                  f.cutoff = get(filtType,'cutoff');
                  f.poles = get(filtType,'poles');
               else
                  error('unknown Tracefilter usage');
               end
            case 3
               f.type = filtType;
               f.cutoff = cutoff_;
               f.poles = poles_;
            otherwise
               disp('Invalid arguments in TraceFilter constructor');
         end
      end
      function f = set.type(f, val)
            assert(numel(f) == 1, 'only can set type for one Tracefilter at a time');
         if ~ischar(val) || numel(val) ~= 1
            error('filter TYPE must be ''B'', ''H'', or ''L'', not a %s',class(val));
         end
         if ismember(upper(val),'BHL')
            [f.type] = deal(upper(val));
         else
            error('Unrecognized value for TYPE.  Should be B,H,or L.  :<%s>' , val);
         end
      end
      function f = set.cutoff(f, val)
            assert(numel(f) == 1, 'only can set cutoff for one Tracefilter at a time');
         if ~isnumeric(val)
            error('Cutoff frequency should be numeric, not %s',class(val));
         end
         switch f.type
            case 'B'
               assert(numel(val) == 2, 'Expected cutoff to be [lower upper]');
               f.cutoff = val;
               
            case {'H', 'L'}
               assert(numel(val) == 1, 'Expected single number for cutoff');
               f.cutoff = val;
         end
      end
      function f = set.poles(f, val)
         assert(numel(f) == 1, 'only can set poles for one Tracefilter at a time');
         if val >=0,
            f.poles = round(val);
         else
            warning('Poles cannot be negative!');
         end
      end
      
      function trace = filtfilt(f, trace, NYQ)
         %FILTFILT - filterobject implementation of FILTFILT, use on waveform Object
         %   waveform = filtfilt(filterobject, waveform);
         %   waveform = filtfilt(filterobject, data, NYQ);
         %
         %      'filtfilt' is a function that filters data at a specified
         %      cutoff frequency with zero time shift.
         %
         %      INPUT values are as follows:
         %        "filterobject" is a filter object
         %        "waveform" is one or more waveform objects
         %        "data" is any data vector (generally of type DOUBLE).
         %        "NYQ" is the nyquist frequency
         %
         %
         %  See also FILTFILT, BUTTER
         
         % VERSION: 1.0 of filter objects
         % AUTHOR: Celso Reyes
         % LASTUPDATE: 1/30/2007
         
         % Check, if w is a number array, just quick & dirty it...
         if isnumeric(trace)
            WN = f.cutoff / NYQ;
            [b, a] = getButter(f,WN);
            trace = filtfilt(b, a, trace);
            
         elseif isa(trace,'Trace')
            assert(numel(f) == 1, 'can only filter using a single Tracefilter at a time');
            HASGAP = arrayfun(@(x) any(isnan(x.data)), trace);
            if any(HASGAP(:))
               warning('Filterobject:filtfilt:hasNaN',...
                  ['Waveform(s) contain data gaps (NaN values). This '...
                  'will cause filtfilt to return an answer of all NaN.  To prevent '...
                  'this, use waveform/fillgaps to replace NaN with an appropriate'...
                  ' value.  \nSee help waveform/fillgaps.']);
            end
            
            nyquists = f.cutoff ./ trace.nyquist();
            
            for n = 1 : numel(trace);
               [b, a] = getButter(f,nyquists(n));
               trace(n).data = filtfilt(b, a,trace(n).data);
            end
            
            histstr = 'Filtered: Type:%s    Cutoff: [%s]   Poles: %d';
            trace = trace.addhistory(sprintf(histstr, f.type, num2str(f.cutoff), f.poles));
         end
         %- - - -  helper function - - - - %
         function [b, a] = getButter(f, nyq)
            switch f.type
               case 'H';
                  [b,a] = butter(f.poles, nyq, 'high');
               case 'B';
                  [b,a] = butter(f.poles, nyq);
               case 'L';
                  [b,a] = butter(f.poles, nyq, 'low');
            end
         end % getButter
      end
   end
end
