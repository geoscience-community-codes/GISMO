function w = waveform(c,varargin)

%WAVEFORM Extract a waveform object.
%
% W = WAVEFORM(C) Extracts a waveform object from inside a correlation
% object. This is really just intuitive shorthand for W =
% GET(C,'WAVEFORM').
%
% W = WAVEFORM(C,INDEX) returns a waveform object W that includes only the
% traces specified by INDEX, where INDEX is a vector of trace indices.
%
% This function is particularly useful for manipulating waveforms using
% tools outside the correlation toolbox. 
% 
% Example:
%   % square the amplitudes of each trace (sign-sensitive)
%   w  = waveform(c);
%   w1 = (w.^2)
%   w2 = sign(w);
%   for n = 1:numel(w)
%        w(n) = w1(n) .* w2(n);
%   end
%   c = correlation(c,w);

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



if numel(varargin)==1
    if ~isa(varargin{1},'double')
       error('correlation:waveform','argument must be a numeric double'); 
    end
    index = varargin{1};
else
    index = 1:numel(c.W);
end
if max(index)>numel(c.W)
	error('correlation:waveform','index exceeds the number of traces'); 
end


w = c.W(index);