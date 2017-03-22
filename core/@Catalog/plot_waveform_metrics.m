function plot_waveform_metrics(cobj)
    wcell =  cobj.waveforms;
    numevents = numel(wcell);
    if numevents == 0
        return
    end

    % get a complete list of channel tags
    ctags = [];
    numctags = 0;
    mintime = Inf;
    maxtime = -Inf;
    for eventnum=1:numevents
        w = wcell{eventnum};
        [snum enum]=gettimerange(w);
        if min(snum)<mintime
            mintime = min(snum);
        end
        if max(enum)>maxtime
            maxtime = max(enum);
        end        
        ctags = unique([ctags; get(w,'ChannelTag')]);
    end
    timediff = maxtime-mintime;

    % 1 subplot per channel tag
    figure
    for eventnum=1:numevents
        w = wcell{eventnum};
        for wavnum=1:numel(w)
            ctag = get(w(wavnum),'ChannelTag');
            idx = find(ismember(ctags.string(), ctag.string()));
            m = get(w(wavnum),'metrics');

            hold on
            subplot(numel(ctags), 1, idx)

            plot(m.maxTime, max(abs([m.maxAmp m.minAmp])), 'b*');
            
            u = get(w(wavnum),'units');
            ylabel(sprintf('%s\n%s',ctag.string(),u));
            set(gca,'XLim',[mintime-timediff/10 maxtime+timediff/10]);
            datetick('x','keeplimits')
        end
    end
end
    
    