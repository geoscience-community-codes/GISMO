function fh=plot_panels(w, alignWaveforms)
%PLOT_PANELS Plot multiple waveform objects as separate linked panels
%   PLOT_PANELS(w, alignWaveforms) 
%   where:
%       w = a vector of waveform objects
%       alignWaveforms is either true or false (default)
%   PLOT_PANELS(w) will plot each waveform is plotted against absolute time.
%   PLOT_PANELS(w, true) will align the waveforms on their start times.
%
% Along the top of each trace are displayed 3 numbers in different colors:
%   blue - the mean offset of the trace
%   green - the start date/time of the trace
%   red - the maximum amplitude of the trace

% Glenn Thompson 2014/11/05, generalized after a function written in 2000
% to operate on Seisan files only

    if numel(w)==0
        warning('no waveforms to plot')
        return
    end
    
    if ~exist('alignWaveforms', 'var')
            alignWaveforms = false;
    end
    
    % get the first start time and last end time
    [starttimes endtimes]=gettimerange(w);
    snum = nanmin(starttimes);
    enum = nanmax(endtimes);
    
    % get the longest duration - in mode=='align' 
    durations = endtimes - starttimes;
    maxduration = nanmax(durations);
    SECSPERDAY = 60 * 60 * 24;
    
    nwaveforms = numel(w);
    fh=figure;
    trace_height=0.9/nwaveforms;
    left=0.1;
    width=0.8;
    for wavnum = 1:nwaveforms
        data=get(w(wavnum),'data');
        dnum=get(w(wavnum),'timevector'); 
        try
            sta=get(w(wavnum),'station');
            chan=get(w(wavnum),'channel');
        catch
            sta='';
            chan='';
        end
        offset = nanmean(data);
        y=data-offset;
        ax(wavnum)=axes('Position',[left 0.98-wavnum*trace_height width trace_height]);   
        if alignWaveforms
            plot((dnum-min(dnum))*SECSPERDAY, y,'-k');
            set(gca, 'XLim', [0 maxduration*SECSPERDAY]);
        else
            plot((dnum-snum)*SECSPERDAY, y,'-k');
            set(gca, 'XLim', [0 enum-snum]*SECSPERDAY);
        end
%         xlim = get(gca, 'XLim');
%         set(gca,'XTick', linspace(xlim(1), xlim(2), 11));
        ylabel(sprintf('%s\n%s ',sta,chan),'FontSize',10,'Rotation',90);
        set(gca,'YTick',[],'YTickLabel',['']);
        if wavnum<nwaveforms;
           set(gca,'XTickLabel',['']);
        end
        
        % display mean on left, max on right
        
        text(0.02,0.85, sprintf('%5.0f',offset),'FontSize',10,'Color','b','units','normalized');
        text(0.4,0.85,sprintf(' %s',datestr(starttimes(wavnum),'yyyy-mm-dd HH:MM:SS.FFF')),'FontSize',10,'Color','g','units','normalized');
        text(0.9,0.85,sprintf('%5.0f',nanmax(abs(y))),'FontSize',10,'Color','r','units','normalized');
    end
    xlabel('Time (s)');
    if exist('ax','var')
        linkaxes(ax,'x');
        
        % enable update x tick labels after zoom
%         h = zoom(gcf);
%         set(h,'ActionPostCallback',{@myzoomcallback,ax});
%         set(h,'Enable','on');

    end

    
    originalXticks = get(gca,'XTickLabel');
    
    f = uimenu('Label','X-Ticks');
%     uimenu(f,'Label','seconds since start time','Callback',{@secondssince, originalXticks});
%     uimenu(f,'Label','absolute time','Callback',{@datetickplot, snum, SECSPERDAY});
    uimenu(f,'Label','time range','Callback',{@daterange, snum, SECSPERDAY});
    uimenu(f,'Label','quit','Callback','disp(''exit'')',... 
           'Separator','on','Accelerator','Q');
end

function daterange(obj, evt, snum, SECSPERDAY)
    xlim = get(gca, 'xlim');
    xticks = linspace(xlim(1), xlim(2), 11);
    dnum = snum + xlim/SECSPERDAY;
    datestr(dnum,'yyyy-mm-dd HH:MM:SS.FFF')
end


