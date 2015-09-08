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
%  See also WAVEFORM/MEAN, WAVEFORM/MEDIAN, WAVEFORM/STD, NANVAR

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

Y = zeros(size(w));

%if the statistics toolbox is installed, use the builtin nanvar function to
%ignore NaN values during the variance calculation.
if ~isempty(ver('stats'))
    if exist('flag','var')
        for n = 1:numel(Y)
            Y(n) = nanvar(w(n).data,flag);
        end
    else
        for n = 1:numel(Y)
            Y(n) = nanvar(w(n).data);
        end
    end
else
    % the statistics toolbox is not installed, so any nan values will have
    % to be dealt with (ignored) manually.
    if exist('flag','var')
        for n = 1:numel(Y)
            d = w(n).data;
            %d = d(~isnan(d));
            Y(n) = var(d(~isnan(d)),flag);
        end
    else
        for n = 1:numel(Y)
            d = w(n).data;
            %d = d(~isnan(d));
            Y(n) = var(d(~isnan(d)));
        end
    end
end
