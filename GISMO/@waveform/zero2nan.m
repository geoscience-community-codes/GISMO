function w = zero2nan(w,mgl)
%ZERO2NAN: This function takes a waveform with gaps that have been filled
%   with zeros and converts them to NaN values. This is the inverse of w =
%   fillgaps(w,0). An input mgl defines the minimum gap length to be
%   converted to NaN gaps, i.e. if only 5 consecutive zero values exist in
%   a given small gap, they will be converted to NaN values if mgl <= 5 and
%   left as zero values if mgl > 5
%
%USAGE: w = zero2nan(w,mgl)
%
%REQUIRED INPUTS: 
%   w - waveform object with zero-value gaps to be converted to NaN gaps
%   mgl - minimum gap length (datapoints) to convert to NaN values
%   
%OUTPUTS: w - waveform with gaps converted to NaN

% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

for nw = 1:numel(w)
   dat = get(w(nw),'data');
   z_cnt = 0; % zero count
   flag = 0;  % filled beginning of gap?
   for n = 1:length(dat)
      if abs(dat(n)) < 0.1,
         z_cnt = z_cnt+1;
         if z_cnt > mgl
            if flag == 0
               dat(n-mgl:n-1)=NaN;
               flag = 1;
            end
            dat(n) = NaN;
         end
      else
         z_cnt = 0;
         flag = 0;
      end
   end

   w(nw) = set(w(nw),'data',dat);
end