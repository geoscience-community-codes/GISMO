function list_waveform_metrics(cobj, list_arrival_metrics_instead)
%LIST_WAVEFORM_METRICS For each event in a Catalog object, list the metrics for each station-channel.
% For this to work, the addwaveforms() and addmetrics() methods must have been run on a Catalog object.
%
% Inputs:
%	cobj                         = a Catalog object to which waveforms, or Arrival waveforms have been added
%	list_arrival_metrics_instead = an optional argument. Can be true or false. default: false
%
% list_waveform_metrics(catalogObj) List amplitude for each station-channel for each event. Catalog.addwaveforms()
%      and Catalog.addmetrics() must have been run. For example, the metrics for event 1 can be viewed with:
%          get(catalogObj.waveforms{1}, 'metrics')
%
% 
% list_waveform_metrics(catalogObj, true) List amplitude for each Arrival in each event. Arrival.addwaveforms()
%      and Arrival.addmetrics() and Arrival.associate() must have been run. For example, the metrics for event 1 can be viewed with:
%          get(catalogObj.arrivals{1}.waveforms, 'metrics')


    if ~exist('list_arrival_metrics_instead', 'var')
        list_arrival_metrics_instead = false;
    end
    
    if list_arrival_metrics_instead
        numevents = numel(cobj.arrivals);
        if numevents == 0
            disp('No Arrivals found in Catalog. You may need to run Detection.associate() or Arrival.associate()')
        end
    else
        numevents = numel(cobj.waveforms);
        if numevents == 0
            disp('No Waveforms found in Catalog. You may need to run Catalog.addwaveforms() and Catalog.addmetrics()')
        end
    end


    % get a complete list of channel tags
    ctags = [];
    numctags = 0;
    mintime = Inf;
    maxtime = -Inf;
    for eventnum=1:numevents
        if list_arrival_metrics_instead
            w = cobj.arrivals{eventnum}.waveforms;
        else
            w = cobj.waveforms{eventnum};
        end
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
    
    % titles
    disp('Maximum Amplitude____________________')
    fprintf('\nEvent\tdd-mmm-yyyy hh:mm:ss\tJulianDay');
    
    for ctagnum = 1:numel(ctags)
        thischan = get(ctags(ctagnum),'channel');
        %fprintf('\t%s', ctags(ctagnum).string());
        fprintf('\t%s', thischan(1:3));
    end
    fprintf('\n.....\t....................\t.........');
    for ctagnum = 1:numel(ctags)
        if strfind(get(ctags(ctagnum),'channel'),'D')
            fprintf('\t(Pascals)');
        else
            fprintf('\t(nm/sec)');
        end
    end
    fprintf('\n');
    
   
    % now go through different metrics of interest, and list for each
    % event for each channel
    for eventnum=1:numevents
        fprintf('%5d:', eventnum);
        if list_arrival_metrics_instead
        	w = cobj.arrivals{eventnum}.waveforms;
	else
		w = cobj.waveforms{eventnum};
	end
        wctags = get(w,'ChannelTag');
        a = [];
        t = Inf;
        for ctagnum = 1:numel(ctags)
            a(ctagnum) = -1;
            thisctag = ctags(ctagnum);
            
            idx = find(ismember(wctags.string(), thisctag.string()));
            if idx
                m = get(w(idx(1)),'metrics');
                a(ctagnum) = max(abs([m.minAmp m.maxAmp]));
                t = min([m.minTime m.maxTime t]);
            end
        end
        jday = datenum2julday(t);
        fprintf('\t%s\t%3d', datestr(t),mod(jday,1000));
        for ctagnum = 1:numel(ctags)
            if a(ctagnum)>=0
                fprintf('\t%15.1f', a(ctagnum));
            else
                fprintf('\t%s', '               '); %change whats here but keept o 15 characters if need change in table
            end
        end
        fprintf('\n');
    end
