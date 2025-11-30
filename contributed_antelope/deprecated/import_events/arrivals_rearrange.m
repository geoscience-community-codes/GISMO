function [sta_index, orid_index, eqtimes, eqindices, nstations, norigins] = arrivals_rearrange(arrivals, stations)
%% Arrange info from earthquake catalogue into a more useful format

% We want a column for each station and a row for each earthquake (origin).
% Store arrival times in this format for now, so we can later replace them
% with loaded waveforms.

% Number of stations.  Use user-specified list and order (rather than
% unique values from arrivals table) for greater flexibility.
nstations = length(stations);

% Number of earthquakes
norigins = length(arrivals.unique_orids);

% Allocate an array to store arrival times
eqtimes = zeros(norigins,nstations);

% Allocate an additional array to store the indices, so we can retrieve
% other data (e.g. event type) later
eqindices = zeros(norigins,nstations);

% Now go through each arrival and place it in the array
for n = 1:length(arrivals.orid)
	sta_index = find(strcmp(arrivals.sta{n},stations),1);
	orid_index = find(unique_orids == arrivals.orid(n),1); % Could do something more efficient here; orid is sorted in ascending order so a find is not really necessary
	eqtimes(orid_index,sta_index) = arrivals.atime(n);
	eqindices(orid_index,sta_index) = n;
end