function [w] = waveform_despike(w);
% [w] = waveform_despike(w);
% Glenn Thompson, 2009
[m, n] = size(w);
for i = 1 : numel(w)
  y = get(w(i), 'data'); 
  [y, ip] = despike( y );
  w(i) = set(w(i), 'data', y);
end
w = reshape(w, m, n);

