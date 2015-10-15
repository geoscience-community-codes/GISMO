function val = check(c,varargin)
   
   % Check various features of a correlation object.
   %
   % VAL = CHECK(C,'OFFSET') Check to see if traces have the same amount of
   % time before and after their respective trigger times. 
   % VAL = false means that the traces are not similarly aligned on their trigger times. 
   % VAL = true means that thet are, to within a tolerance of one sample period.
   %
   % VAL = CHECK(C,'STA') Check to see if traces have the same station codes.
   % VAL = false means that the traces do not all share the same station code. VAL
   % VAL = true means that they do. A match is sought only on the first three
   % characters of the station name (there are internal reasons for this).
   %
   % VAL = CHECK(C,'FREQ') Check to see if traces have the same frequency.
   % VAL = false means that the traces do not all share the same frequency. VAL
   % VAL = true means that they do.
   %
   % VAL = CHECK(C,'SAMPLES') Check to see if traces have the same station
   % codes. VAL = false means that the traces do not all share the same station
   % code. VAL = true means that they do.
   %
   % VAL = CHECK(C,'CHAN') Check to see if traces have the same channel codes.
   % VAL = false means that the traces do not all share the same channel code. VAL
   % = true means that they do.
   %
   % VAL = CHECK(C,'SCALE') Check to see if traces have similar maximum
   % amplitudes. This is a rough check to determine whether the traces have
   % been normalized. VAL = false means that at least one trace has a maxium
   % amplitude that is 50% larger than the mean of the other traces (zero
   % traces are ignored).
   %
   
   % Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   
   % GET INPUT PARAMETERS
   if ~isa(c,'correlation')
      disp('First input parameter must be a correlation object');
   end
   
   if isempty(varargin)
      error('Wrong number of inputs');
   end
   
   type = varargin{1};
   
   switch upper(type)
      case {'OFFSET'}
         val = do_offset(c);
      case {'STA'}
         val = do_stations(c);
      case {'CHAN'}
         val = do_channels(c);
      case {'FREQ'}
         val = do_frequency(c);
      case {'SAMPLES'}
         val = do_samples(c);
      case {'SCALE'}
         val = do_scale(c);
      case {'OFF','CHA','FRE','SAM','SCA'}
         error('please use full option name: OFFSET, CHAN, FREQ, SAMPLES, SCALE');
      otherwise
         error('CHECK requires a valid method as second parameter.');
   end
end

%% Check offsets
function isValid = do_offset(c)
   
   srt_offset = ( get(c,'Trig') - get(c,'Start') ) * 86400;
   end_offset = ( get(c,'End') - get(c,'Trig') ) * 86400;
   
   isValid = ( max(srt_offset) - min(srt_offset) ) <= get(c,'Period') && ...
      ( max(end_offset) - min(end_offset) ) <= get(c,'Period');
end


%% Check station codes
function isValid = do_stations(c)
   
   sta = get(c,'STA');
   sta = ensureCell(sta);
   isValid = isempty([sta{:}]) || all(strcmpi(sta(1), sta));
end

%% Check channel codes
function isValid = do_channels(c)
   
   chan = get(c,'CHAN');
   chan = ensureCell(chan);
   isValid = isempty([chan{:}]) || all(strcmpi(chan(1), chan));
end

%% Check frequencies
function isValid = do_frequency(c)
   isValid = true;
   w = get(c,'WAVES');
   x = get(w,'FREQ');
   if numel(x)>0       % not sure why this loop is needed but it works ???numel(x)
      tf = find(x==x(1));
      if length(find(tf)) ~= get(c,'traces')
         isValid = false;
      end
   end
end


%% Check number of samples in traces
function isValid = do_samples(c)
   isValid = true;
   w = get(c,'WAVES');
   x = get(w,'DATA_LENGTH');
   if numel(x)>0
      tf = find(x==x(1));
      if length(find(tf)) ~= get(c,'traces')
         isValid = false;
      end
   end
end


%% Check absolute amplitude of the traces
function isValid = do_scale(c)
   
   d = get(c,'DATA');
   x = max(abs(d));
   f = x>0;
   isValid = ( max(x) / mean(x(f)) ) <= 1.5;
end

function A = ensureCell(A)
   if ~iscell(A)
      chan = {A};
   end
end


