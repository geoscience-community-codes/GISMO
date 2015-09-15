function mulplt(w, alignWaveforms)
%MULPLT Plot multiple waveform objects in a figure. is inspired by the 
%Seisan program of the same name
%   mulplt(w, alignWaveforms) 
%   where:
%       w = a vector of waveform objects
%       alignWaveforms is either true or false (default)
%   mulplt(w) will plot a record section, i.e. each waveform is plotted
%   against absolute time.
%   mulplt(w, true) will align the waveforms on their start times.

% Glenn Thompson 2014/11/05, generalized after a function I wrote in 2000
% to operate on Seisan files only

    %w = waveform_nonempty(w); % get rid of empty waveform objects
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
    figure
    trace_height=0.9/nwaveforms;
    left=0.1;
    width=0.8;
    for wavnum = 1:nwaveforms
        data=get(w(wavnum),'data');
        dnum=get(w(wavnum),'timevector'); 
        sta=get(w(wavnum),'station');
        chan=get(w(wavnum),'channel');
        ax(wavnum)=axes('Position',[left 0.95-wavnum*trace_height width trace_height]);   
        if alignWaveforms
            plot((dnum-min(dnum))*SECSPERDAY, data,'-k');
            set(gca, 'XLim', [0 maxduration*SECSPERDAY]);
        else
            plot((dnum-snum)*SECSPERDAY, data,'-k');
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
        text(0.02,0.85, sprintf('%5.0f',nanmean(abs(data))),'FontSize',10,'Color','b','units','normalized');
        text(0.4,0.85,sprintf(' %s',datestr(starttimes(wavnum),30)),'FontSize',10,'Color','g','units','normalized');
        text(0.9,0.85,sprintf('%5.0f',nanmax(abs(data))),'FontSize',10,'Color','r','units','normalized');
    end
    
    if exist('ax','var')
        linkaxes(ax,'x');
        
        % enable update x tick labels after zoom
%         h = zoom(gcf);
%         set(h,'ActionPostCallback',{@myzoomcallback,ax});
%         set(h,'Enable','on');

    end
    
    originalXticks = get(gca,'XTickLabels');
    
    f = uimenu('Label','X-Ticks');
%     uimenu(f,'Label','seconds since start time','Callback',{@secondssince, originalXticks});
%     uimenu(f,'Label','absolute time','Callback',{@datetickplot, snum, SECSPERDAY});
    uimenu(f,'Label','time range','Callback',{@daterange, snum, SECSPERDAY});
    uimenu(f,'Label','quit','Callback','disp(''exit'')',... 
           'Separator','on','Accelerator','Q');
end

% function myzoomcallback(obj,evd,AX)
%     %datetick(AX,'x',20,'keeplimits');
%     xlim = get(AX(1),'XLim');
%     xticks = linspace(xlim(1), xlim(2), 11);
%     set(AX(end),'XTick', xticks, 'XTickLabels', xticks);    
% end

% function secondssince(obj, evt, originalXticks)
%     set(gca, 'xtickLabels', originalXticks);
% end
% 
% 
% function datetickplot(obj, evt, snum, SECSPERDAY)
%     xticks = get(gca, 'xtick');
%     ticklabels = datestr(snum + xticks/SECSPERDAY, 15);
%     set(gca, 'xtickLabels', ticklabels);
% end

function daterange(obj, evt, snum, SECSPERDAY)
    xlim = get(gca, 'xlim');
    xticks = linspace(xlim(1), xlim(2), 11);
    dnum = snum + xlim/SECSPERDAY;
    datestr(dnum,'yyyy-mm-dd HH:MM:SS.FFF')
end


