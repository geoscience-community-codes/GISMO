function Y = std(w,flag)
%STD Standard deviation of a waveform
%  Y = STD(W), where W is an N-dimensional waveform object returns the
%  standard deviation within each waveform, normalized by N-1
%
%  Y = STD(W,1) returns the standard deviation within each waveform,
%  normalized by N
%
%  Note: NaN values are ignored entirely
%
%  See also WAVEFORM/MEAN, WAVEFORM/MEDIAN, NANSTD

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

Y = zeros(size(w));

if (exist('flag','var') && (flag == 1))
    for n = 1:numel(Y)
        Y(n) = nanstd(w(n).data,1);
    end
else
    for n = 1:numel(Y)
        Y(n) = nanstd(w(n).data);
    end
end
        