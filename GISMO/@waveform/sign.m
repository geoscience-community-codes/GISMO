function w = sign(w)
%SIGN Signum function for waveforms.
% WAVEFORM = SIGN(WAVEFORM)
% see sign

for n=1:numel(w)
  w(n) = set(w(n),'data',sign(double(get(w(n),'data'))));
end
w = addhistory(w, 'Each data point changed to its sign (-1, 0, or 1)');
