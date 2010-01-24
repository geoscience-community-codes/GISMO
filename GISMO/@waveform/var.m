function Y = var(w,flag)
%VAR Variance of a waveform's data
%  Y = var(W), where W is an N-dimensional waveform object returns the
%  variance of the data within each waveform, normalized by N-1
%
%  Y = var(W,1) returns the variance within each waveform,
%  normalized by N.  
%
%  Y = var(W,weights), where weights is a vector the same length as the
%  number of data samples, applies the weights to the variance.
%
% See the help for MATLAB's built in VAR for more details.
%
% Note: NAN values are completely ignored.
%
%  See also WAVEFORM/MEAN, WAVEFORM/MEDIAN, WAVEFORM/STD, VAR

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/21/2008

Y = zeros(size(w));
if exist('flag','var')
    for n = 1:numel(Y)
        d = double(w(n));
        d = d(~isnan(d));
        Y(n) = var(d,flag);
    end
else
    for n = 1:numel(Y)
        d = double(w(n));
        d = d(~isnan(d));
        Y(n) = var(d);
    end
end
        