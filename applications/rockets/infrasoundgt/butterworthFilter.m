function wfilt = butterworthFilter(w, filterType, corners, numpoles)
disp('Filtering waveform data...')
wfilt = detrend(w);
f=filterobject(filterType, corners, numpoles);
wfilt=filtfilt(f,wfilt);
