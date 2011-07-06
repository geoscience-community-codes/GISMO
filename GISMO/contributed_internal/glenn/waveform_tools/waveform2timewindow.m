function wt=waveform2timewindow(w);
% t=waveform2timewindow(w)
% creates a structure start, stop and maxDiff
% from a vector of waveform objects
% Glenn Thompson, 2007-8

wt.start = [];
wt.stop = [];
start0 = [];
stop0 = [];

for c=1:length(w)
	start0(c) = get(w(c), 'start');
	stop0(c)  = get(w(c), 'end');
end
wt.start = min(start0);
wt.stop  = max(stop0);
wt.maxDiff = max(stop0) - min(stop0);

