function wiggleinterferogram(c,scale,type,norm,range)
   
   % Private method. See ../plot for details.
   
   % Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   
   
   % EXTRACT IMAGE
   udfields = c.traces(1).userdata;
   if ~isfield(udfields,'interferogram_time')  || ...
         isempty(udfields.interferogram_time)
      error('PLOT INTERFER method can only be used following INTERFEROGRAM function');
   end
   I.time  = c.traces(1).userdata.interferogram_time; %get(w(1),'INTERFEROGRAM_TIME');
   I.index = c.traces(1).userdata.interferogram_index; %get(w(1),'INTERFEROGRAM_INDEX');
   I.CC    = c.traces(1).userdata.interferogram_maxcorr; %get(w(1),'INTERFEROGRAM_MAXCORR');
   I.LL    = c.traces(1).userdata.interferogram_lag; %get(w(1),'INTERFEROGRAM_LAG');
   
   % SET COLOR SCALE FOR LAG PLOT
   I.LL = I.LL ./ range;
   
   I.LL(I.LL < -1) = -1; % eliminate negative outliers
   I.LL(I.LL > 1) = 1; %eliminate positive outliers
   
   I.LL = 31.5 * I.LL;
   I.LL = round(I.LL + 32.5);                       % shift to positive indices
   
   I.TRANS = I.CC - 0.6;
   I.TRANS(I.TRANS < 0) = 0;
   I.TRANS = round(0.75*10*I.TRANS);
   I.LL = I.LL + 64*I.TRANS;
   
   
   % PREP PLOT
   figure('Color','w','Position',[50 50 850 1100]);
   box on; hold on;
   
   
   % FIX ORDER OF TRACES
   ord = 1:c.ntraces;
   
   
   % GET MEAN TRACE AMPLITUDE FOR SCALING BELOW (when norm = 0)
   maxlist = nan(size(ord));
   n=1;
   for i = ord
      maxlist(n) = max(abs( c.traces(i).data ));
      n=n+1;
   end;
   normval = mean(maxlist);
   
   
   % ADD IMAGE
   if strncmpi(type,'C',1)
      imagesc(I.time,I.index,I.CC);
      colormap(c,'LTC');
      colorbar;
      hold on;
   elseif strncmpi(type,'L',1)
      h = image(I.time,I.index,I.LL);
      colormap(jet);
      %caxis([-1 1]);
      cmap = load('colormap_lag.txt');
      invcmap = 1 - cmap;
      cmap = 1 - [0*invcmap ; 0.33*invcmap ; 0.66*invcmap ; 1*invcmap];
      colormap(cmap);
      hcb = colorbar;
      set(hcb,'YLim',[193 256]);
      set(hcb,'YTick',193+64 * (0:.125:1) );
      set(hcb,'YTickLabel',range * (-1:.25:1));
      
      hold on;
   else
      error('Plot type not recognized.');
   end
         
   % --------------------------------
   wstartrel = c.relativeStartTime(ord);
   freq = [c.traces(ord).samplerate];
   lengths = [c.traces(ord).nsamples];
   tr = nan(max(lengths),numel(ord)); %pre allocate with nan to not plot
   abs_max =  max(abs(c.traces(ord)));
   for count = 1:numel(ord)
      tr(1:lengths(count),ord(count)) = ...
         wstartrel(count) + (0:lengths(count)-1)'/freq(count);
   end;
   
   % scale is negative because it is reversed below
   if norm==0
      % GET MEAN TRACE AMPLITUDE FOR SCALING BELOW (when norm = 0)
      maxlist = max(abs(c.traces(ord)));
      normval = mean(maxlist);
      for n=1:numel(ord)
         c.traces(ord(n)) = c.traces(ord(n)) .*( -scale ./ normval) + n;
      end
      d = double(c.traces,'nan');
      %d =  double(c.W(ord) .*( -scale ./ normval)+ [1:numel(ord)]','nan'); % do not normalize trace amplitudes
   else
      abs_max(abs_max==0) = 1; % ignore zero traces
      
      d = double(c.W(ord) .* (-scale ./ abs_max) + (1:numel(ord))','nan'); % normalize trace amplitudes
   end
   
   plot(tr,d,'k-','LineWidth',1.5);
   % ------------------------------------------------------
   % adjust figure
   axis([min(tr(:)) max(tr(:)) 0 length(ord)+1]);
   %axis([tmin tmax 0 length(ord)+1]);
   set(gca,'YDir','reverse');
   set(gca,'YTick',1:length(ord));
   set(gca,'YTickLabel',datestr(c.trig(ord)),'FontSize',6);
   xlabel('Relative Time,(s)','FontSize',8);
   
   
   maybeReplaceYticksWithStationNames(c,gca)
   
   %PRINT OUT FIGURE
   set(gcf, 'paperorientation', 'landscape');
   set(gcf, 'paperposition', [.25 .25 10.5 8] );
   try
      if strncmpi(type,'C',1)
         print(gcf, '-depsc2', 'FIG_interferogram_corr.ps')
      else
         print(gcf, '-depsc2', 'FIG_interferogram_lag.ps')
      end
   catch
      disp('Warning: Unable to save figure in current directory.');
   end
end


