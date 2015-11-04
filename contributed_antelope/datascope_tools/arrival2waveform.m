function eqwf=arrival2waveform(arrivals, norigins, nstations, chanlist, ds)
%% Load waveforms for all arrivals

% We now have an array full of arrival times at stations.  We want to load
% those waveforms into a cell array of the same shape.

% Allocate the array
eqwf = cell(norigins,nstations);

fprintf(2,'Loading waveforms:\n');
% We'll go column by column
for ns = 1:nstations
	% Get channel names and create scnlobject
	channels = chanlist(ns,2:4);
	channels(strcmp('',channels)) = [];
	scnl = scnlobject(stations{ns},channels,'','');
	
	% Is this one or three components?
	if length(channels) == 3
		is_tc = true;
	else
		is_tc = false;
	end
	fprintf(2,'%s (%d of %d)...\n',stations{ns},ns,nstations);
	
	% Create a list of arrival times for this station
	satime_indices = find(eqtimes(:,ns) > 0);
	satimes = eqtimes(satime_indices,ns); % Usually better practice to use logical indexing directly instead of a find(), but we need the indexes themselves for later
	
	% Calculate actual start and end times
	end_times = satimes + enddelay/86400;
	start_times = satimes - delay/86400;
	
	% Load waveforms for this station and channels
	wtmp = waveform(ds,scnl,start_times,end_times);
	
	% Reshape to a Nx1 vector; sometimes waveform() returns unusual
	% dimensions (???)
	wtmp = wtmp(:);
	
	% If 3-component data, rearrange to put channels together
	if is_tc
		wtmp = reshape(wtmp,size(wtmp,1)/3,3);
	end
	
	% Store event arrival times in waveform objects, then store the
	% waveforms in our big cell array eqwf.  There doesn't seem to be an
	% obvious way to vectorize these steps.
	% Also store other fields retrieved from database
	for na = 1:size(wtmp,1)
		wtmp(na,:) = addfield(wtmp(na,:),'EVENT_START',satimes(na));
		wtmp(na,:) = addfield(wtmp(na,:),'ETYPE',cell2mat(arrivals.etype(eqindices(satime_indices(na),ns))));
 		wtmp(na,:) = addfield(wtmp(na,:),'ORID',arrivals.orid(eqindices(satime_indices(na),ns)));
		wtmp(na,:) = addfield(wtmp(na,:),'OTIME',arrivals.otime(eqindices(satime_indices(na),ns)));
		wtmp(na,:) = addfield(wtmp(na,:),'SEAZ',arrivals.seaz(eqindices(satime_indices(na),ns)));

		% Technically, there can be a different signal type for each picked
		% arrival.  Here we make the assumption that the value of stype for
		% the chosen iphase (typically P) applies to all components.  This
		% will need to be kept in mind if developing a classification
		% routine that makes use of stype, and training catalogues designed
		% accordingly.
		wtmp(na,:) = addfield(wtmp(na,:),'STYPE',arrivals.stype(eqindices(satime_indices(na),ns)));
		
		
		% Store waveforms in cell array.
		eqwf{satime_indices(na),ns} = wtmp(na,:);
	end
end

clear('wtmp'); % No longer needed so free up some space