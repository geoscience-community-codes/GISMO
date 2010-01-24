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
%  See also WAVEFORM/MEAN, WAVEFORM/MEDIAN, STD

% VERSION: 1.0 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/21/2008

Y = zeros(size(w));

if (exist('flag','var') && (flag == 1))
    for n = 1:numel(Y)
        d = double(w(n));
        d = d(~isnan(d));
        Y(n) = std(d,1);
    end
else
    for n = 1:numel(Y)
        d = double(w(n));
        d = d(~isnan(d));
        Y(n) = std(d);
    end
end
        