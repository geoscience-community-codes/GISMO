% Tremor range is 1-5 Hz
% Swarm events are 0.5-15 Hz
fobj = filterobject('b', [1 5], 2);
wtremor = filtfilt(fobj, w);
wevents = w - wtremor;
cobj = Detect.sta_lta(wevents, 'edp', event_detection_params)

% RSAM
rsam_tremor = waveform2rsam(wtremor, 'method', 'median')
rsam_events = waveform2rsam(wevents, 'method', 'max')

