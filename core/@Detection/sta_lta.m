function [detObj, sta, lta, sta_to_lta] = sta_lta(wave, varargin)
%DETECTION.STA_LTA  Short-Time-Average / Long-Time-Average event detector
%
% Returns a Detection object with ON/OFF trigger times.

% ---------------- Handle waveform arrays ----------------
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

% ---------------- Validate input ----------------
if ~isa(wave,'waveform') || isempty(wave)
    error('Detection.sta_lta:InputMustBeWaveform', ...
          'Input must be a non-empty waveform object');
end

% ---------------- Preprocess ----------------
wave = fillgaps(detrend(wave),'interp');
Fs   = get(wave,'freq');
y    = abs(get(wave,'data'));
t    = get(wave,'timevector');
ctag = get(wave,'ChannelTag');

N = numel(y);

% ---------------- Default parameters ----------------
l_sta = round(1 * Fs);
l_lta = round(8 * Fs);
th_on  = 2.0;
th_off = 1.6;
min_dur_days = 3/86400;
lta_mode = 'continuous';

% ---------------- Parse overrides ----------------
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

% ---------------- Safety checks ----------------
l_sta = max(1, min(l_sta, N-1));
l_lta = max(l_sta+1, min(l_lta, N-1));

% ---------------- Allocate ----------------
sta = zeros(N,1);
lta = zeros(N,1);
sta_to_lta = zeros(N,1);

sta(1:l_sta) = cumsum(y(1:l_sta)) / l_sta;
lta(1:l_lta) = cumsum(y(1:l_lta)) / l_lta;

for k = l_sta+1:l_lta
    sta(k) = sta(k-1) + (y(k)-y(k-l_sta))/l_sta;
end

sta_to_lta(1:l_lta) = sta(1:l_lta)./lta(1:l_lta);

% ---------------- Trigger logic ----------------
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

            trig_array(eventnum,1) = eventstart;
            trig_array(eventnum,2) = eventend;

            snr_val(2*eventnum-1,1) = snr_start;
            snr_val(2*eventnum  ,1) = sta_to_lta(k);
        end
    end
end

% ---------------- No detections ----------------
if eventnum == 0
    detObj = Detection();
    return
end

% ---------------- Build Detection ----------------
times   = reshape(trig_array',[],1);          % 2N × 1
states  = repmat({'ON';'OFF'},eventnum,1);   % 2N × 1
filters = repmat({''},2*eventnum,1);
ctags   = repmat(ctag,2*eventnum,1);

detObj = Detection( ...
    ctags, ...
    times, ...
    states, ...
    filters, ...
    snr_val );

end
