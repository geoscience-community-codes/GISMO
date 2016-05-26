function spectrogram( w )
%SPECTROGRAM Plot an IceWeb-style spectrogram
%   spectrogram(w) Creates an IceWeb style spectrogram by wrapping the
%   function iceweb.spectrogram_iceweb(). For greater control, call that
%   function directly, or use spectralobject/specgram or
%   spectralobject/specgram2 (not clear how these differ). Note that
%   spectrogram_iceweb() is significantly faster.

% Glenn Thompson 2016/05/19 to provide a simple, fast way to geenrate nice
% spectrograms without having to delve into specgram and specgram2
if numel(w)>1
    w = reshape(w, numel(w), 1);
end
s = spectralobject(1024, 924, 10, [60 120]);
iceweb.spectrogram_iceweb(s, w);
