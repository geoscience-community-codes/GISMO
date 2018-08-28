function write_waveform_metrics_to_antelope( cobj, dbpath1, dbpath2 )
%WRITE_METRICS_TO_ANTELOPE Write metrics to a CSS3.0 database
%   Detailed explanation goes here

% Pseudocode:
%   1. Make a copy of the database dbpath1 to dbpath2
%   2. For each arrival without an amp in the arrival table, add the amp & per value. 
%   3. For each arrival with an amp in the arrival table, compare the amp &
%   per values. Are they consistent?
%   4. Create an event row & origin row for each event.
%   5. Associate arrivals in each event to the origin.
%   6. For each waveform metric for each arrival waveform, add a wfmeas
%   row.
%   7. For each waveform metric for each event waveform, add a wfmeas
%   row.
%   Other related code:
%   - a. a function that reads an Antelope database into a Catalog object
%   including arrival, assoc, wfmeas - recreating the whole saved Catalog
%   object.
%   - b. a function to plot a Catalog object. this would call a function to
%   plot arrival objects, and another function to plot metrics of waveform objects.

% Pseudocode:
%   1. Make a copy of the database dbpath1 to dbpath2
    cmdstr = sprintf('dbcp %s %s', dbpath1, dbpath2);
    result = eval(cmdstr);
    
%   2. For each arrival without an amp in the arrival table, add the amp & per value. 
    cobj.arrivals.write(dbpath2);

%   3. For each arrival with an amp in the arrival table, compare the amp &
%   per values. Are they consistent?
    % Probably easier to do this when computing arrival amplitudes!

%   4. Create an event row & origin row for each event.
    cobj.write('antelope', dbpath2); % this also does netmag and stamag

%   5. Associate arrivals in each event to the origin.
    % add this to cobj.write()
    
%   6. For each waveform metric for each arrival waveform, add a wfmeas
%   row.
    cobj.arrivals.
%   7. For each waveform metric for each event waveform, add a wfmeas
%   row.
%   Other related code:
%   - a. a function that reads an Antelope database into a Catalog object
%   including arrival, assoc, wfmeas - recreating the whole saved Catalog
%   object.
%   - b. a function to plot a Catalog object. this would call a function to
%   plot arrival objects, and another function to plot metrics of waveform objects.

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

