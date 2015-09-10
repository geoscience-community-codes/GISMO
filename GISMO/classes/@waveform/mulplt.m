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
        dnum=datenum(w(wavnum)); 
        sta=get(w(wavnum),'station');
        chan=get(w(wavnum),'channel');
        ax(wavnum)=axes('Position',[left 0.95-wavnum*trace_height width trace_height]);   
        if alignWaveforms
            plot((dnum-min(dnum))*SECSPERDAY, data,'-k');
            set(gca, 'XLim', [0 maxduration*SECSPERDAY]);
        else
            plot(dnum, data,'-k');
            set(gca, 'XLim', [snum enum]);
        end
        ylabel(sprintf('%s\n%s ',sta,chan),'FontSize',10,'Rotation',90);
        set(gca,'YTick',[],'YTickLabel',['']);
        if wavnum<nwaveforms;
           set(gca,'XTickLabel',['']);
        end
%         if wavnum==1
%            title('','FontSize',10);
%         end
        %axis tight;
        
        % display mean on left, max on right
        a=axis;
        tpos=a(1)+(a(2)-a(1))*.02;
        dpos=a(3)+(a(4)-a(3))*.85;
        text(tpos,dpos,sprintf('%5.0f',nanmean(data)),'FontSize',10,'Color','b');
        tpos=a(1)+(a(2)-a(1))*.4;
        text(tpos,dpos,sprintf(' %s',datestr(starttimes(wavnum),30)),'FontSize',10,'Color','g');
        tpos=a(1)+(a(2)-a(1))*.9;
        text(tpos,dpos,sprintf('%5.0f',nanmax(abs(data))),'FontSize',10,'Color','r');
    end
    if exist('ax','var')
        linkaxes(ax,'x');
        %samexaxis();
        %hlink = linkprop(ax,'XLim');
        if ~alignWaveforms
            datetick('x', 'keeplimits');
        end
    end
end
