function w=waveform_wrapper(scnl, snum, enum, ds);
% WAVEFORM_WRAPPER try multiple datasource objects in 
% "all" and "single" modes, until we either have a waveform
% for each scnl between times given, or have exhausted all
% options.
%
% This function is useful if you have multiple source datasources
% that might contain the data you care about. For each scnlobject
% requested, every datasource will be tried, and the one that returns 
% the most data will be used.  
%
% 	W = waveform_wrapper(SCNL, SNUM, ENUM, DATASOURCES)
%
%	Inputs:
%		scnl - a vector of scnlobject's 
%		snum - start date/time in datenum format
%		enum - end date/time in datenum format
%		datasources - a vector of datasources to try
%
% 	The main advantage of this wrapper for automation is that
% 	if ds is a vector of different datasources, it will try all of them.
%
% 	It will also try to create waveform objects with a single call of waveform,
% 	but if this fails, it will call waveform for each scnl in turn.
%
%	See also: scnlobject, waveform, datasource, datenum


% AUTHOR: Glenn Thompson, UAF-GI
% $Date: $
% $Revision: -1 $

debug.printfunctionstack('>');

% get datasource
if isempty(ds)
    debug.print_debug('No valid datasource. Exiting.',1);
	w=[];	
    return;
end

numscnls = numel(scnl); % assumes station channel pairs

% scnlgot will record which scnls we've got data for, and which we haven't
% initially set scnlgot for each scnl to 0.
scnlgot = zeros(numscnls,1);

% start off with blank waveform objects
for c=1:numscnls
	w(c) = waveform;
	w(c) = set(w(c), 'station', get(scnl(c), 'station') );
	w(c) = set(w(c), 'channel', get(scnl(c), 'channel') );
end


%% loop over all data sources until some data found
% - all station mode for speed
debug.print_debug('- ALL STATIONS MODE',2);
finished = false;
for dsi=1:length(ds)

	% for informational purposes only, record where we get data from
	datapath='';
	if strcmp(get(ds(dsi), 'type'), 'antelope')
        % if dbopen command not recognised it means Antelope not installed
        % - skip to next datasource
        dummy = help('dbopen')
        if isempty(dummy)
            continue;
        end
		datapath = getfilename(ds(dsi), scnl(1), snum);
	else
		datapath = get(ds(dsi), 'server');
	end
	if strcmp(class(datapath), 'cell')
		datapath = datapath{1};
	end

	scnltoget = scnl(scnlgot==0);
	if (length(scnltoget)==0)
		debug.print_debug('- Got data for all scnls',2);
		finished = true;
		break;
	else
		debug.print_debug(sprintf('- There are still %d scnls to get waveform objects for', length(scnltoget)), 2);
	end
%	try	
		if length(scnltoget)>0
			debug.print_debug(sprintf('- Attempting to load waveform data for %d remaining stations (of %d total) from %s to %s',length(scnltoget),numscnls,datestr(snum,31),datestr(enum,31)),0);
			print_waveform_call(snum, enum, scnltoget, ds(dsi))
                       	w_new = waveform(ds(dsi), scnltoget, snum, enum); 
		else
			continue;
		end
%	catch ME
%		print_debug('waveform failed',1); 
%		w_new = [];
%	end
	if ~isempty(w_new)
		[w, scnlgot] = deal_waveforms(w, w_new, scnlgot, 'all', datapath);
	end
end	

% - individual station mode to fill in blanks
if ~finished 
	debug.print_debug('- SINGLE CHANNEL MODE',2);
	for dsi=1:length(ds)

		% for informational purposes only, record where we get data from
		datapath='';
		if strcmp(get(ds(dsi), 'type'), 'antelope')
			datapath = getfilename(ds(dsi), scnl(1), snum);
		else
			datapath = get(ds(dsi), 'server');
		end
		if strcmp(class(datapath), 'cell')
			datapath = datapath{1};
		end

		scnltoget = scnl(scnlgot==0);
		if (length(scnltoget)==0)
			debug.print_debug('- Got data for all scnls',2);
			finished = true;
			break;
		else
			debug.print_debug(sprintf('- There are still %d scnls to get waveform objects for', length(scnltoget)), 2);
		end
		for c=1:numscnls	
			if scnlgot(c)==0
				try	
					if length(scnltoget)>0
						debug.print_debug(sprintf('- Attempting to load waveform data for %s-%s from %s to %s',get(scnl(c),'station'),get(scnl(c),'channel'),datestr(snum,31),datestr(enum,31)),0);
						print_waveform_call(snum, enum, scnltoget(c), ds(dsi))
        	 				w_new = waveform(ds(dsi), scnltoget(c), snum, enum); 
					else
						continue;
					end
				catch ME
					debug.print_debug('waveform failed',1); 
					w_new = [];
				end
				if ~isempty(w_new)
					[w, scnlgot] = deal_waveforms(w, w_new, scnlgot, 'single', datapath);
				end
			end	
		end
	end
end	
% now remove any waveforms which are empty
%w = w(find(scnlgot==1));

% report what waveforms we got and where they came from 
for i=1:numel(w)
	sta0 = get(w(i), 'station');
	chan0 = get(w(i), 'channel');
	ds0 = get(w(i), 'ds');
	mode0 = get(w(i), 'mode');
	dl0 = get(w(i), 'data_length');
	debug.print_debug(sprintf('- waveform %d: got %d samples for %s-%s from %s in mode %s',i,dl0,sta0,chan0,ds0,mode0),2);
end
debug.print_debug(sprintf('- Got %d waveform objects\n', length(w)),1);
%print_debug(sprintf('< %s', mfilename),1)
debug.printfunctionstack('<');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [w,scnlgot] = deal_waveforms(w, w_new, scnlgot, mode, datapath)
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
			% w_new(j) corresponds to scnl(i)
			nsamp_before = get(w(i), 'data_length');
			if (nsamp > nsamp_before) 
				w(i) = addfield(w_new(j), 'mode', mode);
				w(i) = addfield(w(i), 'ds', datapath);
				if (nsamp > 0.99 * nsamp_expected)
					scnlgot(i)=1;
				end
			end
			break;
		end
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function print_waveform_call(snum, enum, scnl, ds)
disp('Waveform call:')
for c=1:length(scnl)
	fprintf('\tscnl(%d) = scnlobject(''%s'', ''%s'', ''%s'', ''%s'');\n',c, get(scnl(c), 'station'), get(scnl(c), 'channel'), get(scnl(c), 'network'), get(scnl(c), 'location'));
end
if (strcmp(get(ds, 'type'), 'winston'))
	fprintf('\tds = datasource(''winston'', ''%s'', %d);\n', get(ds, 'server'), get(ds, 'port'));
end
if (strcmp(get(ds, 'type'), 'antelope'))
	filenames = getfilename(ds, scnl(1), snum);
	fprintf('\tds = datasource(''antelope'', ''%s'');\n', filenames{1});
end
fprintf('\tw = waveform(ds, scnl, %f, %f)\n', snum, enum);
