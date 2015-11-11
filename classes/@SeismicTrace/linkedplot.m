function linkedplot(T, alignTraces)
   %linkedplot   Plot multiple waveform objects as separate linked panels
   %   T.linkedplot where T is a vector of SeismicTrace will plot all
   %   traces against absolute time (starting at time 0)
   %
   %   T.linkedplot(alignTraces), where alignTraces is either true or
   %   false.  If TRUE, then waveforms are aligned based on their start
   %   times. (Default: FALSE)
   %
   %   Example:
   %      T.linkedplot(true)
   %
   %   See also: plot
   
   % Glenn Thompson 2014/11/05, generalized after a function I wrote in 2000
   % to operate on Seisan files only
   
   if numel(T)==0
      warning('no traces to plot')
      return
   end
   
   if ~exist('alignWaveforms', 'var')
      alignTraces = false;
   end
   
   % get the first start time and last end time
   starttimes = [T.mat_starttime];
   % endtimes = T.timeLastSample();
   SECSPERDAY = 86400;
   grabendtime = @(X) (X.mat_starttime + (numel(X.data)-1) / (X.samplerate * SECSPERDAY));
   endtimes = arrayfun(grabendtime, T);
   endtimes(endtimes < starttimes) = starttimes(endtimes<starttimes); %no negative values!
   % [starttimes endtimes]=gettimerange(T);
   snum = min(starttimes(~isnan(starttimes)));
   enum = max(endtimes(~isnan(endtimes)));
   
   % get the longest duration - in mode=='align'
   durations = endtimes - starttimes;
   maxduration = max(durations(~isnan(durations)));
   
   nwaveforms = numel(T);
   figure
   trace_height=0.9/nwaveforms;
   left=0.1;
   width=0.8;
   ax = zeros(1,nwaveforms);
   for wavnum = 1:nwaveforms
      myw = T(wavnum);
      dnum = myw.sampletimes;
      ax(wavnum) = axes('Position',[left, 0.95-wavnum*trace_height, width, trace_height]);
      if alignTraces
         plot((dnum-min(dnum))*SECSPERDAY, myw.data,'-k');
         set(gca, 'XLim', [0 maxduration*SECSPERDAY]);
      else
         plot((dnum-snum)*SECSPERDAY, myw.data,'-k');
         set(gca, 'XLim', [0 enum-snum]*SECSPERDAY);
      end
      ylabel(myw.channelinfo.string,'FontSize',10,'Rotation',90);
      set(gca,'YTick',[],'YTickLabel','');
      if wavnum<nwaveforms;
         set(gca,'XTickLabel','');
      end
      
      % display mean on left, max on right
      text(0.02,0.85, sprintf('%5.0f',mean(abs(myw.data(~isnan(myw.data))))),'FontSize',10,'Color','b','units','normalized');
      text(0.4,0.85,sprintf(' %s',datestr(starttimes(wavnum),30)),'FontSize',10,'Color','g','units','normalized');
      text(0.9,0.85,sprintf('%5.0f',max(abs(myw.data(~isnan(myw.data))))),'FontSize',10,'Color','r','units','normalized');
   end
   
   if exist('ax','var')
      linkaxes(ax,'x');
   end
   
   % originalXticks = get(gca,'XTickLabel');
   
   f = uimenu('Label','X-Ticks');
   uimenu(f,'Label','time range','Callback',{@daterange, snum, SECSPERDAY});
   uimenu(f,'Label','quit','Callback','disp(''exit'')',...
      'Separator','on','Accelerator','Q');
   
   function daterange(~, ~, snum, SECSPERDAY)
      xlim = get(gca, 'xlim');
      %xticks = linspace(xlim(1), xlim(2), 11);
      mydate = snum + xlim/SECSPERDAY;
      datestr(mydate,'yyyy-mm-dd HH:MM:SS.FFF')
   end
end
