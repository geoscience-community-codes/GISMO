function w=waveform_wrapper(chantag, snum, enum, ds);
% WAVEFORM_WRAPPER try multiple datasource objects in 
% "all" and "single" modes, until we either have a waveform
% for each chantag between times given, or have exhausted all
% options.
%
% This function is useful if you have multiple source datasources
% that might contain the data you care about. For each channeltag
% requested, every datasource will be tried, and the one that returns 
% the most data will be used.  
%
% 	W = waveform_wrapper(SCNL, SNUM, ENUM, DATASOURCES)
%
%	Inputs:
%		chantag - a vector of type channeltag 
%		snum - start date/time in datenum format
%		enum - end date/time in datenum format
%		datasources - a vector of datasources to try
%
% 	The main advantage of this wrapper for automation is that
% 	if ds is a vector of different datasources, it will try all of them.
%
% 	It will also try to create waveform objects with a single call of waveform,
% 	but if this fails, it will call waveform for each channeltag in turn.
%
%	See also: channeltag, waveform, datasource, datenum


% AUTHOR: Glenn Thompson, UAF-GI
% $Date: $
% $Revision: -1 $

    debug.printfunctionstack('>');

    % change channel tag if this is MV network because channels in wfdisc table
    % are like SHZ_--
    for c=1:numel(chantag)
        if strcmp(chantag(c).network, 'MV')
            chantag(c).channel = sprintf('%s_--',chantag(c).channel);
        end
    end

    % get datasource
    if isempty(ds)
        debug.print_debug(1,'No valid datasource. Exiting.');
        w=[];	
        return;
    end

    numchantags = numel(chantag); 

    % chantaggot will record which chantags we've got data for, and which we haven't
    % initially set chantaggot for each chantag to 0.
    chantaggot = zeros(numchantags,1);

    % start off with blank waveform objects
    for c=1:numchantags
        w(c) = waveform;
    %	w(c) = set(w(c), 'station', get(scnl(c), 'station') );
    %	w(c) = set(w(c), 'channel', get(scnl(c), 'channel') );
        w(c) = set(w(c), 'station', chantag(c).station);
        w(c) = set(w(c), 'channel', chantag(c).channel);
        w(c) = set(w(c), 'start', snum);
    end


    %% loop over all data sources until some data found
    % - all station mode for speed
    debug.print_debug(2,'- ALL STATIONS MODE');
    finished = false;
    for dsi=1:length(ds)

        % for informational purposes only, record where we get data from
        datapath='';
        if strcmp(get(ds(dsi), 'type'), 'antelope')
            % if dbopen command not recognised it means Antelope not installed
            % - skip to next datasource
            dummy = help('dbopen');
            if isempty(dummy)
                continue;
            end
            datapath = getfilename(ds(dsi), chantag(1), snum);
        else
            datapath = get(ds(dsi), 'server');
        end
        if strcmp(class(datapath), 'cell')
            datapath = datapath{1};
        end

        chantagtoget = chantag(chantaggot==0);
        if (length(chantagtoget)==0)
            debug.print_debug(2,'- Got data for all chantags');
            finished = true;
            break;
        else
            debug.print_debug(2, sprintf('- There are still %d chantags to get waveform objects for', length(chantagtoget)));
        end
        try	
            if length(chantagtoget)>0
                debug.print_debug(0, sprintf('- Attempting to load waveform data for %d remaining stations (of %d total) from %s to %s',length(chantagtoget),numchantags,datestr(snum,31),datestr(enum,31)));
                %print_waveform_call(snum, enum, chantagtoget, ds(dsi))
                save lastwaveformcall.mat ds chantag snum enum
                w_new = waveform(ds(dsi), chantagtoget, snum, enum); 
            else
                continue;
            end
        catch ME
            print_waveform_call(snum, enum, chantagtoget, ds(dsi))
            debug.print_debug(1,'waveform failed'); 
            w_new = [];
        end
        if ~isempty(w_new)
            [w, chantaggot] = deal_waveforms(w, w_new, chantaggot, 'all', datapath);
        end
    end	

    % - individual station mode to fill in blanks
    if ~finished 
        debug.print_debug(2,'- SINGLE CHANNEL MODE');
        for dsi=1:length(ds)

            % for informational purposes only, record where we get data from
            datapath='';
            if strcmp(get(ds(dsi), 'type'), 'antelope')
                datapath = getfilename(ds(dsi), chantag(1), snum);
            else
                datapath = get(ds(dsi), 'server');
            end
            if strcmp(class(datapath), 'cell')
                datapath = datapath{1};
            end

            chantagtoget = chantag(chantaggot==0);
            if (length(chantagtoget)==0)
                debug.print_debug(2,'- Got data for all chantags');
                finished = true;
                break;
            else
                debug.print_debug(2,sprintf('- There are still %d chantags to get waveform objects for', length(chantagtoget)));
            end
            
            for c=1:numchantags	
                if chantaggot(c)==0
                    try	
                        if length(chantagtoget)>0
                            %debug.print_debug(sprintf('- Attempting to load waveform data for %s-%s from %s to %s',get(scnl(c),'station'),get(scnl(c),'channel'),datestr(snum,31),datestr(enum,31)),0);
                            save lastwaveformcall.mat ds chantag snum enum chantagtoget c
                            w_new = waveform(ds(dsi), chantag(c), snum, enum); 
                        else
                            continue;
                        end
                    catch ME
                        print_waveform_call(snum, enum, chantag(c), ds(dsi))
                        debug.print_debug(1,'waveform failed'); 
                        w_new = [];
                    end
                    if ~isempty(w_new)
                        [w, chantaggot] = deal_waveforms(w, w_new, chantaggot, 'single', datapath);
                    end
                end	
            end
        end
    end	
    % now remove any waveforms which are empty
    %w = w(find(chantaggot==1));

    % report what waveforms we got and where they came from 
    for i=1:numel(w)
        sta0 = get(w(i), 'station');
        chan0 = get(w(i), 'channel');
        %ds0 = get(w(i), 'ds');
        %mode0 = get(w(i), 'mode');
        dl0 = get(w(i), 'data_length');
        %debug.print_debug(sprintf('- waveform %d: got %d samples for %s-%s from %s in mode %s',i,dl0,sta0,chan0,ds0,mode0),2);
        debug.print_debug(2,sprintf('- waveform %d: got %d samples for %s-%s',i,dl0,sta0,chan0));
    end
    debug.print_debug(1,sprintf('- Got %d waveform objects\n', length(w)));
    %print_debug(sprintf('< %s', mfilename),1)
    debug.printfunctionstack('<');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [w,chantaggot] = deal_waveforms(w, w_new, chantaggot, mode, datapath)
% take arrays of waveforms we just got, and waveforms we already have 
    for i=1:numel(w)
        sta = get(w(i), 'station');
        chan = get(w(i), 'channel');
        for j = 1:numel(w_new)
            sta_new = get(w_new(j), 'station');
            chan_new = get(w_new(j), 'channel');
            nsamp = get(w_new(j), 'data_length');
            freq = get(w_new(j), 'freq');
            nsamp_expected = freq * 600;
            if (strcmp(sta_new, sta) & strcmp(chan_new, chan))
                % w_new(j) corresponds to chantag(i)
                nsamp_before = get(w(i), 'data_length');
                if (nsamp > nsamp_before) 
                    w(i) = addfield(w_new(j), 'mode', mode);
                    w(i) = addfield(w(i), 'ds', datapath);
                    if (nsamp > 0.99 * nsamp_expected)
                        chantaggot(i)=1;
                    end
                end
                break;
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function print_waveform_call(snum, enum, chantag, ds)

    disp('Waveform call:')
    for c=1:numel(chantag)
        fprintf('\tchantag(%d) = channeltag(''%s'')\n', c, string(chantag(c)));
    end
    if (strcmp(get(ds, 'type'), 'winston'))
        fprintf('\tds = datasource(''winston'', ''%s'', %d);\n', get(ds, 'server'), get(ds, 'port'));
    end
    if (strcmp(get(ds, 'type'), 'antelope'))
        filenames = getfilename(ds, chantag(1), snum);
        fprintf('\tds = datasource(''antelope'', ''%s'');\n', filenames{1});
    end
    fprintf('\tw = waveform(ds, chantag, %f, %f)\n', snum, enum);
end
