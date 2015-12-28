function c = norm(c,varargin)
   
   % C = NORM(C)
   % This function normalizes the amplitudes of all traces.
   %
   % C = NORM(C,'max')
   % Normalize to the maximum absolute value of each trace.
   % This is the default.
   %
   % C = NORM(C,'std')
   % Normalize to one half of the standard deviation of the absolute value of
   % each trace.
   %
   % C = NORM(C,METHOD,PRETRIG,POSTTRIG) Normalize traces based on the segment
   % of data specified by PRETRIG and POSTTRIG. This is useful for scaling an
   % entire trace based on the amplitude of a particular arrival. METHOD may
   % be either 'max' or 'std'.
   %
   % C = NORM(C,SCALE)
   % Multiply each trace by SCALE factor, where SCALE is a scalar number.
   %
   % C = NORM(C,...,INDEX) Apply normalization/scaling only to the traces in
   % INDEX. INDEX must appear as the third argument to NORM.
   %
   
   % Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   
   % READ & CHECK ARGUMENTS
   
   % TODO: fine tune the way traces are reassigned.
   
   %SPECIFY THE NORMALIZATION METHOD
   method = normalizationMethod(varargin);
   c = cropIfRequested(c, varargin);
   
   % determine the index
   if numel(varargin) == 2 % NORM(C, METHOD / SCALE, INDEX)
      index = varargin{2};
   else
      index = 1:c.ntraces;
   end
      
   % NORMALIZE EACH TRACE
   switch upper(method(1:3))
      case 'MAX'
         for i = index
            maxd = max(abs(c.traces(i)));
            if maxd ~= 0
               c.traces(i) = c.traces(i) ./  maxd;
            end;
         end
         
      case 'SCA' % scaled
            c.traces(index) = c.traces(index) .* scale;
         
      case {'RMS', 'STD'}
         for i = index
            d2 = c.traces(i).data;
            stdd = 0.5 * std(abs(d2));
            if stdd ~= 0
               c.traces(i) = c.traces(i) ./ stdd;
            end;
         end
   end
end

function m = normalizationMethod(val)
   if isempty(val)
      m = 'max';
   elseif isnumeric(val{1})
      m = 'sca';
   elseif ischar(val{1})
      m = val{1};
   else
      error('unknown normalization method');
   end
end

function c = cropIfRequested(c, vals)
   if numel(vals) == 3
      c = crop(c,vals{2:3});
   end
end

