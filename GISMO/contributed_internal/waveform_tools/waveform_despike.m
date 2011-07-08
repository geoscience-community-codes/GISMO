function [w] = waveform_despike(w);
% [w] = waveform_despike(w);
% Glenn Thompson, 2009

y = get(w, 'data'); 
[y, ip] = despike( y );
set(w, 'data', y);

