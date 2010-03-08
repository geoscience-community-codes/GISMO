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

%if the statistics toolbox is installed, use the builtin nanstd function to
%ignore NaN values during the variance calculation.
if ~isempty(ver('stats'))
    if (exist('flag','var') && (flag == 1))
        for n = 1:numel(Y)
            Y(n) = nanstd(w(n).data,1);
        end
    else
        for n = 1:numel(Y)
            Y(n) = nanstd(w(n).data);
        end
    end
    
else
    % the statistics toolbox is not installed, so any nan values will have
    % to be dealt with (ignored) manually.
    if (exist('flag','var') && (flag == 1))
        for n = 1:numel(Y)
            d = w(n).data;
            %d = d(~isnan(d));
            Y(n) = std(d(~isnan(d)),1);
        end
    else
        for n = 1:numel(Y)
            d = w(n).data;
            %d = d(~isnan(d));
            Y(n) = std(d(~isnan(d)));
        end
    end
end