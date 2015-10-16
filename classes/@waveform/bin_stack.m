function stk = bin_stack(w,bin,ovr)
   
   %BIN_STACK: Stack input waveforms with N waveforms per stack. The number N
   %    is specified by input 'bin'. The input 'ovr' specifies the amount of
   %    overlap between bins.
   %
   %USAGE: stk = bin_stack(w,bin,ovr)
   %    If input w contains 100 waveforms then:
   %    stk = bin_stack(w,20,0) % stk has 5 stacks of 20 waveforms
   %    stk = bin_stack(w,5,0)  % stk has 20 stacks of 5 waveforms
   %    stk = bin_stack(w,20,10)  % stk has 9 stacks of 20 waveforms
   %
   %INPUTS:  w   - Input waveform
   %         bin - Bin size of stacked waveforms
   %         ovr - Number of overlapping events between bins
   %
   %OUTPUTS: stk - Array of stacked waveforms
   
   % Author: Dane Ketner, Alaska Volcano Observatory
   % $Date$
   % $Revision$
   
   nw = numel(w);
   inc = bin-ovr;
   n=1;
   while 1
      if (n-1)*inc+bin > nw
         return
      else
         stk(n) = stack(w((n-1)*inc+1:(n-1)*inc+bin));
         n=n+1;
      end
   end
end