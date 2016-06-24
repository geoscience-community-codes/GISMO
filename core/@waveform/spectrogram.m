function spectrogram( w, s )
%SPECTROGRAM Plot an IceWeb-style spectrogram
%   spectrogram(w, s) Creates an IceWeb style spectrogram by wrapping the
%   function iceweb.spectrogram_iceweb(). If s is omitted it defaults to:
%       spectralobject(1024, 924, 10, [60 120]);
%
% For greater control, call that
%   iceweb.spectrogram_iceweb() directly, or use spectralobject/specgram or
%   spectralobject/specgram2 (not clear how these differ). Note that
%   spectrogram_iceweb() is significantly faster.

% Glenn Thompson 2016/05/19 to provide a simple, fast way to geenrate nice
% spectrograms without having to delve into specgram and specgram2
if numel(w)>1
    w = reshape(w, numel(w), 1);
end
if ~exist('s','var')
    s = spectralobject(1024, 924, 10, [60 120]);
end
iceweb.spectrogram_iceweb(s, w, 0.75);

    
