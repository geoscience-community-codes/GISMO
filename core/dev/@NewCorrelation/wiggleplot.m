function wiggleplot(c,scale,ord,norm)
   
   % Private method. See ../plot for details.
   
   % Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   
   % PREP PLOT
   figure('Color','w','Position',[50 50 850 1100]);
   box on;
   % hold on;
   
   % LOOP THROUGH WAVEFORMS
   wstartrel = c.relativeStartTime(ord);
   freq = [c.traces(ord).samplerate]; % get(c.W(ord),'Fs');
   lengths = [c.traces(ord).nsamples];  %lengths = get(c.W(ord),'data_length');
   tr = nan(max(lengths),numel(ord)); %pre allocate with nan to not plot
   abs_max =  max(abs(c.traces(ord))); % max(abs(c.W(ord)));
   for count = 1:numel(ord)
      tr(1:lengths(count),count) = ...
         wstartrel(count) + (0:lengths(count)-1)' / freq(count);
   end;
   
   % scale is negative because it is reversed below
   if norm==0
      % GET MEAN TRACE AMPLITUDE FOR SCALING BELOW (when norm = 0)
      maxlist = max(abs(c.traces(ord)));
      normval = mean(maxlist);
      c.traces(ord) = forEach(c.traces(ord), @times, -scale ./ normval, 'loose');
      c.traces(ord) = forEach(c.traces(ord), @plus, 1:numel(ord), 'loose');
      %for n=1:c.ntraces;
      %   c.traces(ord(n)) = c.traces(ord(n)) .*( -scale ./ normval) + offsets(n);
      %end
      d=double(c.traces, 'nan');
      %d =  double(c.traces(ord) .*( -scale ./ normval) + offsets(:),'nan'); % do not normalize trace amplitudes
   else
      abs_max(abs_max==0) = 1; % ignore zero traces
      % TRACES(ORD) = TRACES(ORD) .* NORMALIZER(N) + OFFSET(N)
      
      % read: as  "For each Trace, multiply against BLAH"
      c.traces(ord) = forEach(c.traces(ord),'.*', -scale ./ abs_max, 'loose');
      c.traces(ord) = forEach(c.traces(ord), '+', 1:numel(ord), 'loose');
      d = double(c.traces,'nan');
      % d = double(c.W(ord) .* normalizer + offsets,'nan'); % normalize trace amplitudes
   end
   
   plot(tr,d,'b-','LineWidth',1);
   
   % adjust figure
   %axis([tmin tmax 0 length(ord)+1]);
   axis([min(tr(:)) max(tr(:)) 0 length(ord)+1]);
   set(gca,'YDir','reverse',...
      'YTick',1:length(ord),...
      'YTickLabel',datestr(c.trig(ord),'yyyy-mm-dd HH:MM:SS'),...
      'FontSize',6);
   
   xlabel('Relative Time,(s)','FontSize',8);
   
   maybeReplaceYticksWithStationNames(c,gca)
   
   %PRINT OUT FIGURE
   set(gcf, 'paperorientation', 'portrait');
   set(gcf, 'paperposition', [.25 .25 8 10.5] );
   %print(gcf, '-depsc2', 'FIG_alignwfm.ps')
   %!ps2pdf FIG_alignwfm.ps
   %!convert FIG_alignwfm.ps FIG_alignwfm.gif
   %!rm FIG_alignwfm.ps
end