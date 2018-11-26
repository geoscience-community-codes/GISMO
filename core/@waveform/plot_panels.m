function plot_panels(w, varargin)
%PLOT_PANELS Plot multiple waveform objects as separate linked panels
%   PLOT_PANELS(w, varargin) 
%   where:
%       w = a vector of waveform objects
%       alignWaveforms is either true or false (default)
%   PLOT_PANELS(w) will plot each waveform is plotted against absolute time.
%   PLOT_PANELS(w, 'alignWaveforms', true) will align the waveforms on their start times.
%   PLOT_PANELS(w, 'arrivals', ArrivalObject) will superimpose arrival
%                                             times on the waveforms.
%   PLOT_PANELS(w, 'detections', DetectionObject) will superimpose
%                                         detection times on the waveforms.
%   PLOT_PANELS(w, 'visible', 'off') will prevent the plot showing on the
%                                    screen.
%   By default, plot_panels(..) will show 3 text labels for each waveform
%   trace. On the left, the start time. In the middle, the mean. On the
%   right, the maximum amplitude of the waveform. This is equivalent to
%   PLOT_PANELS(w, 'labels', {'time';'mean';'amplitude'}). To prevent any
%   of these showing up, use:
%   PLOT_PANELS(w, 'labels', {}).
%
% Along the top of each trace are displayed 3 numbers in different colors:
%   blue - the mean offset of the trace
%   green - the start date/time of the trace
%   red - the maximum amplitude of the trace

% Glenn Thompson 2014/11/05, generalized after a function written in 2000
% to operate on Seisan files only

    w = iceweb.waveform_remove_empty(w);

    if numel(w)==0 || isempty(w)
        warning('no waveforms to plot')
        return
    end
    
    p = inputParser;
    p.addParameter('alignWaveforms', false, @isnumeric); % optional name-param pairs
    p.addParameter('visible', 'on', @isstr)
    p.addParameter('labels', {'time';'mean';'amplitude'}, @iscell)
    p.addParameter('arrivals', [])
    p.addParameter('detections', [])
    p.parse(varargin{:});
    alignWaveforms = p.Results.alignWaveforms;
    visibility = p.Results.visible;
    if isa(p.Results.arrivals, 'Arrival')
        arrivalobj = p.Results.arrivals;
    end
    if isa(p.Results.detections, 'Detection')
        detectionobj = p.Results.detections;
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
    previousfignum = get_highest_figure_number();
    fh=figure(previousfignum+1);
    set(fh,'visible',visibility);
    trace_height=0.87/nwaveforms;
    left=0.12;
    width=0.78;
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
        % if sampling rate > 1 Hz, assume this is raw data, if < 1 Hz
        % assume RSAM data
        if get(w(wavnum),'freq')>1
            offset = nanmean(data); % raw waveform data, 2 sided
        else
            offset = 0; % RSAM data, absolute, 1 sided
        end
        y=data-offset;
        y(isnan(y))=0;
        ax(wavnum)=axes('Position',[left 0.98-wavnum*trace_height width trace_height]);   
        
        % arrivals
        if exist('arrivalobj','var')
            %disp('- adding arrivals to panel plot')
            hold on
            thisctag = strrep(string(get(w(wavnum),'ChannelTag')),'-','');
            Index = find(ismember(arrivalobj.channelinfo, thisctag));
            for arrnum=1:numel(Index)
                arrtime = arrivalobj.time(Index(arrnum));
                if alignWaveforms
                    relarrtime = (arrtime-min(dnum))*SECSPERDAY;
                else
                    relarrtime = (arrtime-snum)*SECSPERDAY;
                end
                plot([relarrtime relarrtime], [min(y) max(y)],'r', 'LineWidth',3);
            end
            %hold off
        end
        
        % detections
        if exist('detectionobj','var')
            disp('- adding detections to panel plot')
            hold on
            thisctag = strrep(string(get(w(wavnum),'ChannelTag')),'-','')
            Index = find(ismember(detectionobj.channelinfo, thisctag))
            for detnum=1:numel(Index)
                dettime = detectionobj.time(Index(detnum));
                if alignWaveforms
                    reldettime = (dettime-min(dnum))*SECSPERDAY;
                else
                    reldettime = (dettime-snum)*SECSPERDAY;
                end
                reldettime
                plot([reldettime reldettime], [min(y) max(y)],'r', 'LineWidth',3);
            end
            %hold off
        end        
        
        % metrics
        try 
            m = get(w(wavnum),'metrics');
            hold on
            if alignWaveforms
                relmintime = (m.minTime-min(dnum))*SECSPERDAY;
                relmaxtime = (m.maxTime-min(dnum))*SECSPERDAY;
            else
                relmintime = (m.minTime-snum)*SECSPERDAY;
                relmaxtime = (m.maxTime-snum)*SECSPERDAY;
            end
            plot([relmintime relmaxtime], [m.minAmp m.maxAmp],'g','LineWidth',3);
            %hold off
        end
        
        % waveform data
        if alignWaveforms
            plot((dnum-min(dnum))*SECSPERDAY, y,'-k');
            set(gca, 'XLim', [0 maxduration*SECSPERDAY]);
        else
            plot((dnum-snum)*SECSPERDAY, y,'-k');
            set(gca, 'XLim', [0 enum-snum]*SECSPERDAY);
        end
%         xlim = get(gca, 'XLim');
%         set(gca,'XTick', linspace(xlim(1), xlim(2), 11));

        if all((get(w(wavnum),'data'))>=0) % added for RSAM data
            ylims = get(gca, 'YLim');
            set(gca, 'YLim', [0 ylims(2)]);
        end
        if length(chan)>3
            chan = chan(1:3);
        end
        ylabel(sprintf('%s\n%s ',sta,chan),'FontSize',10,'Rotation',90);
        set(gca,'YTick',[],'YTickLabel',['']);
        if wavnum<nwaveforms;
           set(gca,'XTickLabel',['']);
        end
        
        % display mean on left, max on right
        tracemax = nanmax(abs(detrend(y)));
        ustr = get(w(wavnum),'units');
        if strcmp(ustr,'null')
            ustr = '';
        end
        
        if any(strcmp(p.Results.labels,'mean'))
            text(0.5,0.85, sprintf('%4.2e %s',offset,ustr),'FontSize',6,'Color','b','units','normalized');
        end
        if any(strcmp(p.Results.labels,'time'))
            text(0.02,0.85,sprintf('%s',datestr(starttimes(wavnum),'yyyy-mm-dd HH:MM:SS.FFF')),'FontSize',8,'Color','g','units','normalized');
        end
        if any(strcmp(p.Results.labels,'amplitude'))
            text(0.85,0.85,sprintf('%4.2e %s',tracemax,ustr),'FontSize',8,'Color','r','units','normalized');
        end
        

%         if exist('arrivalobj','var')
%             %disp('- adding arrivals to panel plot')
%             hold on
%             thisctag = strrep(string(get(w(wavnum),'ChannelTag')),'-','');
%             Index = find(ismember(arrivalobj.channelinfo, thisctag));
%             for arrnum=1:numel(Index)
%                 arrtime = arrivalobj.time(Index(arrnum));
%                 if alignWaveforms
%                     relarrtime = (arrtime-min(dnum))*SECSPERDAY;
%                 else
%                     relarrtime = (arrtime-snum)*SECSPERDAY;
%                 end
%                 plot([relarrtime relarrtime], [min(y) max(y)],':r');
%             end
%             hold off
%         end        
            
        hold off
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


