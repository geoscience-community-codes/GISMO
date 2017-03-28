function plot_panels(w, alignWaveforms, arrivalobj)
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

    w = iceweb.waveform_remove_empty(w);

    if numel(w)==0 || isempty(w)
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
    previousfignum = get_highest_figure_number();
    fh=figure(previousfignum+1);
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
        text(0.5,0.85, sprintf('%4.2e %s',offset,ustr),'FontSize',6,'Color','b','units','normalized');
        text(0.02,0.85,sprintf('%s',datestr(starttimes(wavnum),'yyyy-mm-dd HH:MM:SS.FFF')),'FontSize',8,'Color','g','units','normalized');
        text(0.85,0.85,sprintf('%4.2e %s',tracemax,ustr),'FontSize',8,'Color','r','units','normalized');
        

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


