function W = hilbert(W, n)
%HILBERT (for WAVEFORM objects) Discrete-time analytic Hilbert transform.
%   waveform = hilbert(waveform)
%   waveform = hilbert(waveform, N);
%
% THIS version only returns the abs value in the waveform.  If you want to
% keep the imaginary values, then you should use the built-in hilbert
% transform.  ie.  Don't feed it a wavform object, feed it a vector... - CR
%
%
% See also FFT, IFFT, for details and the meaning of "N" see HILBERT

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

for idx = 1:numel(W)
    d = W(idx).data;
    if exist('n','var'),
        d = abs(hilbert(d,n));
    else
        d = abs(hilbert(d));
    end
    W(idx) = set(W(idx),'data',d);
end
W  = addhistory(W ,'Hilbert transform');