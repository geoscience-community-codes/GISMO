classdef Detection
%DETECTION Container for STA/LTA style detection metadata
%
% Supports:
%   • ChannelTag or {sta,chan}
%   • Antelope DB I/O
%   • Event association
%
% Glenn Thompson (refactored 2025)

% -------------------------------------------------------------------------
properties
    channelinfo      % cellstr of ChannelTag strings
    time             % datenum
    state            % cellstr
    filterString     % cellstr
    signal2noise     % numeric
    traveltime       % numeric
end

properties (Dependent)
    numel
end

% -------------------------------------------------------------------------
methods

% ======================= CONSTRUCTOR ===========================
function obj = Detection(sta, chan, time, state, filterString, signal2noise)

    if nargin == 0
        obj.channelinfo  = {};
        obj.time         = [];
        obj.state        = {};
        obj.filterString = {};
        obj.signal2noise = [];
        obj.traveltime   = [];
        return
    end

    % ---------- ChannelTag input ----------
    if isa(sta,'ChannelTag')

        ctag = sta;
        p = inputParser;
        p.addRequired('time', @isnumeric);
        p.addOptional('state', {}, @iscell);
        p.addOptional('filterString', {}, @iscell);
        p.addOptional('signal2noise', [], @isnumeric);
        p.parse(chan, time, state, filterString);

    % ---------- sta/chan cell input ----------
    else
        p = inputParser;
        p.addRequired('sta',  @iscell);
        p.addRequired('chan', @iscell);
        p.addRequired('time', @isnumeric);
        p.addOptional('state', {}, @iscell);
        p.addOptional('filterString', {}, @iscell);
        p.addOptional('signal2noise', [], @isnumeric);
        p.parse(sta, chan, time, state, filterString, signal2noise);

        ctag = ChannelTag.array('', p.Results.sta, '', p.Results.chan)';
    end

    obj.channelinfo  = ctag.string();
    obj.time         = p.Results.time;
    obj.state        = Detection.defaultCell(p.Results.state, numel(obj.time));
    obj.filterString = Detection.defaultCell(p.Results.filterString, numel(obj.time));
    obj.signal2noise = Detection.defaultNum(p.Results.signal2noise, numel(obj.time));
    obj.traveltime   = NaN(size(obj.time));
end

% ---------------- Dependent ----------------
function val = get.numel(obj)
    val = numel(obj.time);
end

% ======================= SUMMARY ===========================
function summary(obj, showall)

    if nargin < 2, showall = false; end
    N = obj.numel;

    fprintf('Number of detections: %d\n',N);

    if N <= 50 || showall
        for k = 1:N
            fprintf('%s  %s  %s  %.2f\n', ...
                obj.channelinfo{k}, ...
                datestr(obj.time(k)), ...
                obj.state{k}, ...
                obj.signal2noise(k));
        end
    else
        for k = 1:50
            fprintf('%s  %s  %s  %.2f\n', ...
                obj.channelinfo{k}, ...
                datestr(obj.time(k)), ...
                obj.state{k}, ...
                obj.signal2noise(k));
        end
        disp('* Only first 50 rows shown. Use summary(obj,true) to show all.');
    end
end

% ======================= SUBSET ===========================
function out = subset(obj, columnname, findval)
    %DETECTION.SUBSET  Safe subsetting by indices or by matching a column.
    %
    %   out = subset(obj, idx)
    %   out = subset(obj, 'state', 'D')
    %
    % Returns an empty Detection if:
    %   • obj is empty
    %   • idx is empty or out of range

    % ---- If base object is empty, just return empty ----
    if obj.numel == 0 || isempty(obj.channelinfo)
        out = Detection();
        return
    end

    % ---- Determine idx ----
    if nargin == 2
        % First arg is an index / logical mask
        idx = columnname;
    else
        % First arg is column name, second is value to match
        idx = find(strcmp(obj.(columnname), findval));
    end

    % ---- Normalize idx ----
    if islogical(idx)
        idx = find(idx);
    end
    idx = idx(:);                  % column vector
    idx = idx(~isnan(idx));        % drop NaNs just in case

    % ---- Clamp to valid range ----
    n = obj.numel;
    idx = idx(idx >= 1 & idx <= n);

    % ---- If nothing valid, return empty Detection ----
    if isempty(idx)
        out = Detection();
        return
    end

    % ---- Apply subsetting safely ----
    out = obj;
    out.channelinfo  = obj.channelinfo(idx);
    out.time         = obj.time(idx);
    out.state        = obj.state(idx);
    out.filterString = obj.filterString(idx);
    out.signal2noise = obj.signal2noise(idx);
    out.traveltime   = obj.traveltime(idx);
end

% ======================= APPEND ===========================
function self = append(a,b)

    newTime = [a.time b.time];
    [newTime,idx] = sort(newTime);

    self.channelinfo  = [a.channelinfo b.channelinfo];   self.channelinfo  = self.channelinfo(idx);
    self.state        = [a.state b.state];               self.state        = self.state(idx);
    self.filterString = [a.filterString b.filterString]; self.filterString = self.filterString(idx);
    self.signal2noise = [a.signal2noise b.signal2noise]; self.signal2noise = self.signal2noise(idx);
    self.traveltime   = [a.traveltime b.traveltime];     self.traveltime   = self.traveltime(idx);
    self.time         = newTime;
end

% ======================= ADD NETWORK PREFIX ===========================
function obj = addnetwork(obj, net)
    for k = 1:numel(obj.channelinfo)
        obj.channelinfo{k} = [net obj.channelinfo{k}];
    end
end

% ======================= PLOT ===========================
function plot(obj)

    tags = unique(obj.channelinfo);
    hf1 = figure; hold on;
    hf2 = figure; hold on;

    for k = 1:numel(tags)
        idx = strcmp(obj.channelinfo,tags{k});
        t = obj.time(idx);
        s = obj.signal2noise(idx);

        figure(hf1)
        plot(t,cumsum(ones(size(t))),'LineWidth',2);

        figure(hf2)
        [n,x] = hist(s,1:100);
        plot(x,100-cumsum(n)/sum(n)*100,'LineWidth',2);
    end
end

% ======================= ASSOCIATE ===========================
function catalogobj = associate(obj, maxTimeDiff, sites, source, varargin)
%ASSOCIATE  Associate detections into multi-station events
%
%   catalogobj = associate(detobj, maxTimeDiff)
%   catalogobj = associate(detobj, maxTimeDiff, sites)
%   catalogobj = associate(detobj, maxTimeDiff, sites, source)
%
% NAME–VALUE OPTIONS:
%   'MinStations' (default 2)
%   'RequireUniqueStations' (false)
%   'RequireUniqueChannels' (false)
%   'StateFilter' ({'D','ON'})
%   'PhaseFilter' ({})
%   'ClusteringMethod' ('sliding')
%   'Probabilistic' (false)

if nargin < 3 || isempty(sites),  sites  = []; end
if nargin < 4 || isempty(source), source = []; end

% ------------------------------
% Parse Options
% ------------------------------
p = inputParser;
p.addParameter('MinStations',2,@(x)isnumeric(x)&&x>=1);
p.addParameter('RequireUniqueStations',false,@islogical);
p.addParameter('RequireUniqueChannels',false,@islogical);
p.addParameter('StateFilter',{'D','ON'},@iscell);
p.addParameter('PhaseFilter',{},@iscell);
p.addParameter('ClusteringMethod','sliding',@ischar);
p.addParameter('Probabilistic',false,@islogical);
p.parse(varargin{:});
opt = p.Results;

if ~strcmpi(opt.ClusteringMethod,'sliding')
    error('Detection.associate:ClusteringNotImplemented', ...
          'Only ''sliding'' clustering is implemented.');
end

% ------------------------------
% State filtering
% ------------------------------
if ~isempty(opt.StateFilter) && ~isempty(obj.state)

    statecol = obj.state(:);
    keep = false(size(statecol));

    for k = 1:numel(opt.StateFilter)
        cmp = strcmp(statecol, opt.StateFilter{k});
        cmp = cmp(:);                 % ensure column
        if numel(cmp) > numel(keep)
            cmp = cmp(1:numel(keep));
        elseif numel(cmp) < numel(keep)
            tmp = false(size(keep));
            tmp(1:numel(cmp)) = cmp;
            cmp = tmp;
        end
        keep = keep | cmp;
    end

    idx = find(keep);

    if isempty(idx)
        catalogobj = Catalog();
        return
    end

    obj = obj.subset(idx);
end

% ------------------------------
% Phase filtering
% ------------------------------
if ~isempty(opt.PhaseFilter) && ~isempty(obj.state)

    statecol = obj.state(:);
    keep = false(size(statecol));

    for k = 1:numel(opt.PhaseFilter)
        cmp = strcmp(statecol, opt.PhaseFilter{k});
        cmp = cmp(:);
        if numel(cmp) > numel(keep)
            cmp = cmp(1:numel(keep));
        elseif numel(cmp) < numel(keep)
            tmp = false(size(keep));
            tmp(1:numel(cmp)) = cmp;
            cmp = tmp;
        end
        keep = keep | cmp;
    end

    idx = find(keep);

    if isempty(idx)
        catalogobj = Catalog();
        return
    end

    obj = obj.subset(idx);
end

% ------------------------------
% Travel-time reduction
% ------------------------------
if ~isempty(sites)
    obj.traveltime = NaN(size(obj.time));
    for c = 1:numel(sites)
        chanstr = sites(c).channeltag.string();
        idx = strcmp(obj.channelinfo, chanstr);
        obj.traveltime(idx) = sites(c).traveltime;
        obj.time(idx) = obj.time(idx) - sites(c).traveltime/86400;
    end
else
    obj.traveltime = zeros(size(obj.time));
end

% ------------------------------
% Sort (by reduced time)
% ------------------------------
if obj.numel == 0
    catalogobj = Catalog();
    return
end

[~,idx] = sort(obj.time);

idx = idx(idx >= 1 & idx <= obj.numel);

if isempty(idx)
    catalogobj = Catalog();
    return
end

obj = obj.subset(idx);

% ------------------------------
% Sliding window clustering
% ------------------------------
dt = maxTimeDiff / 86400;
N = obj.numel;

clusters = {};
i = 1; k = 1;

while i <= N
    j = find(obj.time >= obj.time(i) & obj.time <= obj.time(i)+dt);
    if numel(j) >= opt.MinStations
        clusters{k} = j;
        k = k + 1;
        i = max(j) + 1;
    else
        i = i + 1;
    end
end

if isempty(clusters)
    catalogobj = Catalog();
    return
end

% ------------------------------
% Build Events
% ------------------------------
arrivalobj = {};
firstDet   = [];
lastDet    = [];
otime      = [];
confidence = [];

eventnum = 0;

for k = 1:numel(clusters)

    detset = obj.subset(clusters{k});
    detset.time = detset.time + detset.traveltime/86400;

    ctag = ChannelTag(detset.channelinfo);
    sta  = get(ctag,'station');
    chan = get(ctag,'channel');

    if opt.RequireUniqueStations
        [~,ia] = unique(sta,'stable');
        detset = detset.subset(ia);
    end

    if opt.RequireUniqueChannels
        [~,ia] = unique(chan,'stable');
        detset = detset.subset(ia);
    end

    if detset.numel < opt.MinStations
        continue
    end

    eventnum = eventnum + 1;

    firstDet(eventnum) = min(detset.time);
    lastDet(eventnum)  = max(detset.time);
    otime(eventnum)    = firstDet(eventnum);

    arrivalobj{eventnum} = detection2arrival(detset);

    if opt.Probabilistic
        span = lastDet(eventnum) - firstDet(eventnum);
        density = detset.numel / max(span*86400,1);
        confidence(eventnum) = 1 - exp(-density);
    end
end

if isempty(otime)
    catalogobj = Catalog();
    return
end

if isempty(source)
    olon = [];
    olat = [];
else
    olon = source.lon * ones(size(otime));
    olat = source.lat * ones(size(otime));
end

catalogobj = Catalog( ...
    otime, olon, olat, [], [], {}, {}, ...
    'ontime', firstDet, ...
    'offtime', lastDet);

catalogobj.arrivals = arrivalobj;

if opt.Probabilistic
    catalogobj.confidence = confidence;
end

end % associate

% ======================= WRITE ===========================
function write(obj,outformat,outpath)
%DETECTION.WRITE Write a Detection object to disk

switch lower(outformat)

case {'csv','txt','xls'}
    T = table(obj.channelinfo(:),obj.time(:),obj.state(:),obj.signal2noise(:), ...
              'VariableNames',{'Channel','Time','State','SNR'});
    writetable(T,outpath);

case 'antelope'
    if ~admin.antelope_exists
        error('Antelope not available');
    end
    db   = antelope.dbopen(outpath,'r+');
    dbdet= antelope.dblookup_table(db,'detection');

    for k = 1:obj.numel
        ctag = ChannelTag(obj.channelinfo{k});
        dbdet.record = antelope.dbaddnull(dbdet);
        antelope.dbputv(dbdet, ...
          'sta',ctag.station, ...
          'chan',ctag.channel, ...
          'time',datenum2epoch(obj.time(k)), ...
          'state',obj.state{k}, ...
          'snr',obj.signal2noise(k));
    end
    antelope.dbclose(db);

otherwise
    error('Detection.write:UnsupportedFormat','Unknown format.');
end
end

end % methods

% ======================= STATIC METHODS ===========================
methods (Static)

function [detObj, sta, lta, sta_to_lta] = sta_lta(wave, varargin)
%DETECTION.STA_LTA  Short-Time-Average / Long-Time-Average event detector
%
% See class documentation for full help text (omitted here for brevity).

% Handle waveform arrays
if numel(wave) > 1
    detObj = Detection();
    for k = 1:numel(wave)
        d0 = Detection.sta_lta(wave(k),varargin{:});
        if isa(d0,'Detection') && d0.numel > 0
            detObj = detObj.append(d0);
        end
    end
    sta = []; lta = []; sta_to_lta = [];
    return
end

if ~isa(wave,'waveform') || isempty(wave)
    error('Detection.sta_lta:InputMustBeWaveform', ...
          'Input must be a non-empty waveform object');
end

wave = fillgaps(detrend(wave),'interp');
Fs   = get(wave,'freq');
y    = abs(get(wave,'data'));
t    = get(wave,'timevector');
ctag = get(wave,'ChannelTag');

l_sta = round(1 * Fs);
l_lta = round(8 * Fs);
th_on  = 2.0;
th_off = 1.6;
min_dur_days = 3/86400;
lta_mode = 'continuous';

for p = 1:2:numel(varargin)
    switch lower(varargin{p})
        case 'edp'
            v = varargin{p+1};
            l_sta = round(v(1)*Fs);
            l_lta = round(v(2)*Fs);
            th_on = v(3);
            th_off = v(4);
            min_dur_days = v(5)/86400;
        case 'lta_mode'
            lta_mode = lower(varargin{p+1});
    end
end

N = numel(y);
sta = zeros(N,1);
lta = zeros(N,1);
sta_to_lta = zeros(N,1);

sta(1:l_sta) = cumsum(y(1:l_sta))/l_sta;
lta(1:l_lta) = cumsum(y(1:l_lta))/l_lta;

for k = l_sta+1:l_lta
    sta(k) = sta(k-1) + (y(k)-y(k-l_sta))/l_sta;
end

sta_to_lta(1:l_lta) = sta(1:l_lta)./lta(1:l_lta);

EVENT_ON = false;
trig_array = [];
snr_val = [];
eventnum = 0;

for k = l_lta+1:N

    if EVENT_ON && strcmp(lta_mode,'frozen')
        lta(k) = lta_freeze_level;
    else
        lta(k) = lta(k-1) + (y(k)-y(k-l_lta))/l_lta;
    end

    sta(k) = sta(k-1) + (y(k)-y(k-l_sta))/l_sta;
    sta_to_lta(k) = sta(k)/lta(k);

    if ~EVENT_ON && sta_to_lta(k) >= th_on
        EVENT_ON = true;
        eventstart = t(k);
        lta_freeze_level = lta(k);
        snr_start = sta_to_lta(k);
    end

    if EVENT_ON && (sta_to_lta(k) <= th_off || k == N)
        EVENT_ON = false;
        eventend = t(k);

        if (eventend - eventstart) >= min_dur_days
            eventnum = eventnum + 1;
            trig_array(eventnum,:) = [eventstart eventend];
            snr_val(eventnum*2-1:eventnum*2) = [snr_start sta_to_lta(k)];
        end
    end
end

if eventnum == 0
    detObj = Detection();
    return
end

times   = reshape(trig_array',1,eventnum*2);
states  = repmat({'ON';'OFF'},eventnum,1);
filters = repmat({''},eventnum*2,1);
ctags   = repmat(ctag,eventnum*2,1);

detObj = Detection( ...
    ctags, ...
    times, ...
    states(:), ...
    filters(:), ...
    snr_val(:)' );

end

% ======================= PRIVATE HELPERS ===========================
function c = defaultCell(v,n)
    if isempty(v), c = repmat({''},1,n);
    else c = v; end
end

function x = defaultNum(v,n)
    if isempty(v), x = NaN(1,n);
    else x = v; end
end

function arr = detection2arrival(det)
    ctag = ChannelTag(det.channelinfo);
    arr = Arrival( ...
        cellstr(get(ctag,'station')), ...
        cellstr(get(ctag,'channel')), ...
        det.time, ...
        det.state, ...
        'signal2noise',det.signal2noise);
end

end % static methods
end % classdef
