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
   % Modified: Celso Reyes: rewrote algorithm to elimenate looping (2x faster)
   %                        results differ because old method converted
   %                        5 zeros only if mgl <5 (not <=5)
   % $Date$
   % $Revision$
   
   for nw = 1:numel(w)
      closeToZero = abs(w(nw).data) < 0.1; % 0.1 was already chosen -CR
      
      % --- the logic below should be pulled into a new function, since it is
      % shared across a couple different areas, such as waveform/clean -- %
      firstZeros = find(diff([false; closeToZero(:)]) == 1);
      lastZeros = find(diff([closeToZero(:); false]) == -1);
      assert(numel(firstZeros) == numel(lastZeros));
      nContiguousZeros = lastZeros - firstZeros + 1;
      firstZeros(nContiguousZeros < mgl) = [];
      lastZeros(nContiguousZeros < mgl) = [];
      
      for c=1:numel(firstZeros)
         w(nw).data(firstZeros(c) : lastZeros(c)) = NaN;
      end
   end
   
   %{   
      % old method
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
   %}