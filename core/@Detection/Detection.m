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

    % ---------- Blank constructor ----------
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
    obj.state        = defaultCell(p.Results.state, numel(obj.time));
    obj.filterString = defaultCell(p.Results.filterString, numel(obj.time));
    obj.signal2noise = defaultNum(p.Results.signal2noise, numel(obj.time));
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
        for k=1:N
            fprintf('%s  %s  %s  %.2f\n', ...
                obj.channelinfo{k}, ...
                datestr(obj.time(k)), ...
                obj.state{k}, ...
                obj.signal2noise(k));
        end
    else
        for k=1:50
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

    if nargin == 2
        idx = columnname;
    else
        idx = find(strcmp(obj.(columnname), findval));
    end

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

    self.channelinfo  = [a.channelinfo b.channelinfo]; self.channelinfo  = self.channelinfo(idx);
    self.state        = [a.state b.state];             self.state        = self.state(idx);
    self.filterString = [a.filterString b.filterString]; self.filterString = self.filterString(idx);
    self.signal2noise = [a.signal2noise b.signal2noise]; self.signal2noise = self.signal2noise(idx);
    self.traveltime   = [a.traveltime b.traveltime];   self.traveltime   = self.traveltime(idx);
    self.time         = newTime;
end

% ======================= ADD NETWORK PREFIX ===========================
function obj = addnetwork(obj, net)
    for k=1:numel(obj.channelinfo)
        obj.channelinfo{k} = [net obj.channelinfo{k}];
    end
end

% ======================= PLOT ===========================
function plot(obj)

    tags = unique(obj.channelinfo);
    hf1 = figure; hold on;
    hf2 = figure; hold on;

    for k=1:numel(tags)
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

function catalogobj = associate(obj, maxTimeDiff, sites, source, varargin)
%ASSOCIATE  Associate detections into multi-station events
%
%   catalogobj = associate(detobj, maxTimeDiff)
%
%   Groups detections into events whenever two or more detections occur
%   within maxTimeDiff seconds of each other. The earliest detection in
%   each group becomes the event origin time.
%
%   catalogobj = associate(detobj, maxTimeDiff, sites)
%   Applies differential travel-time correction before association.
%
%   catalogobj = associate(detobj, maxTimeDiff, sites, source)
%   Also populates event latitude/longitude.
%
%   catalogobj = associate(..., 'Name',Value,...)
%
%   Name–Value Options:
%     'MinStations'              (default = 2)
%     'RequireUniqueStations'    (default = false)
%     'RequireUniqueChannels'    (default = false)
%     'StateFilter'              (default = {'D','ON'})
%     'PhaseFilter'              (default = {})
%     'ClusteringMethod'         (default = 'sliding')
%     'Probabilistic'            (default = false)
%
%   Output Catalog:
%     • ontime, offtime
%     • arrivals (Arrival objects)
%     • lat, lon (optional)
%     • confidence (optional)
%
%   See also: Detection, Arrival, Catalog

% ------------------------------
% Backward compatibility
% ------------------------------
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

% ------------------------------
% Enforce implemented clustering
% ------------------------------
if ~strcmpi(opt.ClusteringMethod,'sliding')
    error('Detection.associate:ClusteringNotImplemented', ...
          'Only ''sliding'' clustering is currently implemented.');
end

% ------------------------------
% State filtering
% ------------------------------
if ~isempty(opt.StateFilter)
    keep = false(size(obj.time));
    for k = 1:numel(opt.StateFilter)
        keep = keep | strcmp(obj.state,opt.StateFilter{k});
    end
    obj = obj.subset(find(keep));
end

% ------------------------------
% Phase filtering
% ------------------------------
if ~isempty(opt.PhaseFilter)
    keep = false(size(obj.time));
    for k = 1:numel(opt.PhaseFilter)
        keep = keep | strcmp(obj.state,opt.PhaseFilter{k});
    end
    obj = obj.subset(find(keep));
end

if obj.numel < opt.MinStations
    catalogobj = Catalog();
    return
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
% Sort by reduced time
% ------------------------------
[~,idx] = sort(obj.time);
obj = obj.subset(idx);

% ------------------------------
% Sliding window clustering
% ------------------------------
dt = maxTimeDiff / 86400;
N = obj.numel;

clusters = {};
i = 1;
k = 1;

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
firstDet = [];
lastDet = [];
otime = [];
confidence = [];

eventnum = 0;

for k = 1:numel(clusters)

    detset = obj.subset(clusters{k});

    % Undo reduction
    detset.time = detset.time + detset.traveltime/86400;

    % Enforce uniqueness
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

% ------------------------------
% Create Catalog
% ------------------------------
if isempty(source)
    olon = [];
    olat = [];
else
    olon = source.lon * ones(size(otime));
    olat = source.lat * ones(size(otime));
end

catalogobj = Catalog( ...
    otime, ...
    olon, ...
    olat, ...
    [], [], {}, {}, ...
    'ontime', firstDet, ...
    'offtime', lastDet);

catalogobj.arrivals = arrivalobj;

if opt.Probabilistic
    catalogobj.confidence = confidence;
end

end



% ======================= WRITE ===========================
function write(obj,outformat,outpath)
    %DETECTION.WRITE Write a Detection object to disk
    %
    % detectionObject.write('antelope', 'mydb', 'css3.0') writes the
    % detectionObject to a CSS3.0 database called 'mydb' using
    % Antelope. Requires Antelope and Antelope Toolbox. 
    % 
    % Support for other output formats, e.g. Seisan, will be added
    % later.

    % Glenn Thompson, 15 August 2018
    switch lower(outformat)

    case {'csv','txt','xls'}
        T=table(obj.channelinfo(:),obj.time(:),obj.state(:),obj.signal2noise(:), ...
                'VariableNames',{'Channel','Time','State','SNR'});
        writetable(T,outpath);

    case 'antelope'
        if ~admin.antelope_exists
            error('Antelope not available');
        end
        db=antelope.dbopen(outpath,'r+');
        dbdet=dblookup_table(db,'detection');

        for k=1:obj.numel
            ctag=ChannelTag(obj.channelinfo{k});
            dbdet.record=dbaddnull(dbdet);
            dbputv(dbdet, ...
              'sta',ctag.station, ...
              'chan',ctag.channel, ...
              'time',datenum2epoch(obj.time(k)), ...
              'state',obj.state{k}, ...
              'snr',obj.signal2noise(k));
        end
        dbclose(db);
    end
end

methods(Static)

function [detObj, sta, lta, sta_to_lta] = sta_lta(wave, varargin)
%DETECTION.STA_LTA  Short-Time-Average / Long-Time-Average event detector
%
%   detObj = Detection.sta_lta(wave)
%   detObj = Detection.sta_lta(wave, 'edp', [l_sta l_lta th_on th_off min_dur])
%   detObj = Detection.sta_lta(wave, 'lta_mode', MODE)
%
%   [detObj, sta, lta, sta_to_lta] = Detection.sta_lta(...)
%
% DESCRIPTION
%   Detection.sta_lta applies a classic STA/LTA trigger algorithm to a
%   waveform object and returns a Detection object containing paired
%   'ON' and 'OFF' detections for each triggered event. The method supports
%   waveform arrays and automatically concatenates detections across
%   multiple channels.
%
%   This method is CI-safe (no plotting) and returns an empty Detection
%   object if no events are detected.
%
% INPUTS
%   wave   - A GISMO waveform object (scalar or array). Gaps are interpolated
%            and the signal is detrended internally before detection.
%
% NAME–VALUE PAIR OPTIONS
%
%   'edp'   [l_sta l_lta th_on th_off min_dur]
%       Event Detection Parameters (numeric 1×5 vector):
%         l_sta     – STA window length (seconds)
%         l_lta     – LTA window length (seconds)
%         th_on     – Trigger ON threshold (STA/LTA ratio)
%         th_off    – Trigger OFF threshold (STA/LTA ratio)
%         min_dur   – Minimum event duration (seconds)
%
%       Default: [1 8 2.0 1.6 3]
%
%   'lta_mode'  (string)
%       Post-trigger LTA behavior:
%         'continuous'  – LTA continues updating during events (default)
%         'frozen'      – LTA is frozen at trigger ON
%         'grow'        – LTA grows continuously after trigger ON
%
% OUTPUTS
%   detObj        - Detection object containing ON/OFF trigger pairs
%   sta           - Short-term average time series
%   lta           - Long-term average time series
%   sta_to_lta    - STA/LTA ratio time series
%
% DETECTION OBJECT CONTENTS
%   Each detected event produces two rows:
%     • State = 'ON'  at trigger start time
%     • State = 'OFF' at trigger end time
%
%   Fields populated:
%     • channelinfo
%     • time
%     • state
%     • signal2noise (STA/LTA ratio at ON and OFF)
%
% EXAMPLES
%
%   % Basic detection
%   det = Detection.sta_lta(w);
%
%   % Custom STA/LTA parameters
%   det = Detection.sta_lta(w,'edp',[0.5 10 2.5 1.8 1]);
%
%   % Detection on waveform array
%   det = Detection.sta_lta(waveArray);
%
%   % Full pipeline to event Catalog
%   det = Detection.sta_lta(w);
%   cat = det.associate(3,'MinStations',2);
%
% NOTES
%   • This detector is amplitude-based only; no frequency or waveform
%     similarity constraints are applied.
%   • Without travel-time reduction, closely spaced independent events
%     may merge into a single associated event.
%   • For multi-parameter event definition, combine with:
%         Detection.associate
%         Arrival
%         Catalog
%
% SEE ALSO
%   Detection, Detection.associate, Arrival, Catalog, waveform
%
% Author:
%   Glenn Thompson, after contributed code from Dane Ketner (AVO)
%   Refactored into Detection class, CI-safe, 2025

% ------------------------------
% Varargin validation
% ------------------------------
if rem(numel(varargin),2) ~= 0
    error('Detection.sta_lta:InvalidArguments', ...
          'Arguments must be name–value pairs.');
end

% ------------------------------
% Handle waveform arrays
% ------------------------------
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

% ------------------------------
% Validate waveform
% ------------------------------
if ~isa(wave,'waveform') || isempty(wave)
    error('Detection.sta_lta:InputMustBeWaveform', ...
          'Input must be a non-empty waveform object');
end

wave = fillgaps(detrend(wave),'interp');
Fs   = get(wave,'freq');
y    = abs(get(wave,'data'));
t    = get(wave,'timevector');
ctag = get(wave,'ChannelTag');

% ------------------------------
% Defaults
% ------------------------------
l_sta = round(1 * Fs);
l_lta = round(8 * Fs);
th_on  = 2.0;
th_off = 1.6;
min_dur_days = 3/86400;
lta_mode = 'continuous';

% ------------------------------
% Parse options
% ------------------------------
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

% ------------------------------
% Initialize STA/LTA
% ------------------------------
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

% ------------------------------
% Detection loop
% ------------------------------
EVENT_ON = false;
eventstart = 0;
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

% ------------------------------
% Build Detection object
% ------------------------------
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


end % Static methods


end % classdef

% ======================= LOCAL HELPERS ===========================
function c = defaultCell(v,n)
    if isempty(v), c = repmat({''},1,n);
    else c=v; end
end

function x = defaultNum(v,n)
    if isempty(v), x = NaN(1,n);
    else x=v; end
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


