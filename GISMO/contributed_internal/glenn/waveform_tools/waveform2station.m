function station=waveform2station(w)
for c=1:length(w)
	station(c).name = get(w(c), 'station');
	station(c).channel = get(w(c), 'channel');
end
