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
   
   
   % CHECK FOR RANGE
   if (length(varargin)==3) && isnumeric(varargin{2}) && isnumeric(varargin{3})
      c2 = crop(c,varargin{2},varargin{3});
      varargin = varargin(1:end-2);
   else
      c2 = c;
   end
   
   
   % CHECK FOR INDEX LIST
   if (length(varargin)==2) && isnumeric(varargin{1})
      index  = varargin{2};
      varargin = varargin(1:end-1);
   else
      index = 1:get(c,'Traces');
   end
   
   
   % CHOOSE NORMALIZATION TYPE
   if (length(varargin)==1) && ischar(varargin{1})
      method = varargin{1};
   elseif  (length(varargin)==1) && isnumeric(varargin{1})
      method = 'sca';
      scale = varargin{1};
   elseif  (nargin==1)
      method = 'max';
   else
      error('Incorrect inputs');
   end;
   
   
   % NORMALIZE EACH TRACES
   switch upper(method(1:3))
      case 'MAX'
         for i = index
            maxd = max(abs(c2.W(i)));
            if maxd ~= 0
               c.W(i) = c.W(i) /  maxd;
            end;
         end
         
      case 'SCA' % scaled
         for i = index
            c.W(i) = c.W(i) * scale;
         end
         
      case {'RMS', 'STD'}
         for i = index
            d2 = c2.traces(i).data;
            stdd = 0.5 * std(abs(d2));
            if stdd ~= 0
               c.W(i) = c.W(i) / stdd;
            end;
         end
   end
end

