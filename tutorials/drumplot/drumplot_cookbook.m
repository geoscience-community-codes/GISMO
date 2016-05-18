%% drumplot cookbook
% GISMO can generate a helical drum recorder plot and superimpose on it the
% events from a Catalog object. This Catalog object can also come from
% running a STA/LTA detector on a waveform.

%% Load 1 day of data for REF.EHZ on 2009.03.22
ctag = ChannelTag('AV.REF.-.EHZ')
snum = datenum(2009,3,22);
enum=snum+1;
ds = datasource('sac', 'SACDATA/REF.EHZ.2009-03-22T00:00:00.000000Z.sac');
w=waveform(ds, ctag, snum, enum);


%% fill gaps, detrend, band pass filter
w = fillgaps(w, 'interp');
w = detrend(w);
fobj = filterobject('b', [0.5 15], 2);
w = filtfilt(fobj, w);

%% plot waveform
figure
plot(w)

%% extract up to 1 hour of data and plot with 5 minutes per line
starttime = get(w,'start');
w2=extract(w, 'time', starttime, min([get(w,'end') starttime + 1/24]) )
h2 = drumplot(w2, 'mpl', 5);
build(h2)

%% STA/LTA
sta_seconds = 0.7;
lta_seconds = 7.0;
thresh_on = 3;
thresh_off = 1.5;
minimum_event_duration_seconds = 2.0;
pre_trigger_seconds = 0;
post_trigger_seconds = 0;
event_detection_params = [sta_seconds lta_seconds thresh_on thresh_off ...
    minimum_event_duration_seconds];
[cobj,sta,lta,sta_to_lta] = Detection.sta_lta(w2, 'edp', event_detection_params, ...
    'lta_mode', 'frozen');

set(gca, 'XLim', [44*60 48*60])
%% Plot detections
h3 = drumplot(w2, 'mpl', 5, 'catalog', cobj);
build(h3)

%% save the data from w2
x = get(w2,'data');
t = get(w2,'timevector');
save signal_to_use_for_amplitude_duration_exercise

