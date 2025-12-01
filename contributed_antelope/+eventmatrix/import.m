function [EQTC, EQWF, meta] = import(dbname, chanfile, starttime, endtime, phase, pretrig, posttrig, varargin)
%EVENTMATRIX.IMPORT Modern replacement for legacy import_events
%
% Uses Catalog + Arrival core GISMO classes.
%
% [EQTC, EQWF, META] = eventmatrix.import( ...
%     dbname, chanfile, starttime, endtime, phase, pretrig, posttrig, ds )
%
% META contains:
%   - stations
%   - orids
%   - otimes

fprintf('[eventmatrix] Loading channel list...\n');
stations = eventmatrix.readChanFile(chanfile);

%% Load catalog using modern GISMO
fprintf('[eventmatrix] Loading catalog via Catalog.retrieve...\n');

cat = Catalog.retrieve('antelope', dbname);

cat = cat.subset('time', [starttime endtime]);

arr = cat.arrivals;
arr = arr.subset('iphase', phase);

if isempty(arr.time)
    error('No arrivals found for requested phase.');
end

%% Attach waveforms using modern Arrival API
fprintf('[eventmatrix] Loading waveforms via Arrival.addwaveforms...\n');

if isempty(varargin)
    ds = datasource('antelope', dbname);
else
    ds = varargin{1};
end

arr = arr.addwaveforms(ds, pretrig, posttrig);

%% Organize into Event × Station matrix
fprintf('[eventmatrix] Organizing into event-station matrix...\n');

[EQWF, meta] = eventmatrix.organizeByEventStation(arr, stations);

%% Convert to threecomp where possible
EQTC = eventmatrix.toThreeComp(EQWF, meta);

fprintf('[eventmatrix] Done.\n');
end