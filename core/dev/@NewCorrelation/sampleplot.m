function sampleplot(c,scale,ord)
   
   % Private method. See ../plot for details.
   
   % Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   
   % PREP PLOT
   figure('Color','w','Position',[50 50 850 1100]);
   box on; hold on;
   
   
   % LOOP THROUGH WAVEFORMS
   tmin =  999999;
   tmax = -999999;
   count = 0;
   for i = ord
      count = count + 1;
      d = c.traces(i).data;            %%%d = c.w(:,i);
      d = scale * d/max(abs(d));		% apply a uniform amplitude scale;
      d = -1 * d; 				% because scale is reversed below
      wstartrel = c.relativeStartTime(i);
      %wstartrel = 86400*(c.traces(i).firstsampletime()-c.trig(i));	% relative start time (trigger is at zero)
      tr = wstartrel + [ 0:length(d)-1]'/ c.traces(i).samplerate;
      plot(tr,d+count,'b.','LineWidth',1);
      % save min and max relative trace times
      if tr(1) < tmin
         tmin = tr(1);
      end;
      if tr(end) > tmax
         tmax = tr(end);
      end;
      
   end;
   
   
   % adjust figure
   axis([tmin tmax 0 length(ord)+1]);
   set(gca,'YDir','reverse');
   set(gca,'YTick',1:length(ord));
   set(gca,'YTickLabel',datestr(c.trig(ord)),'FontSize',6);
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
