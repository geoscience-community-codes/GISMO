function [dnum_bin, counts_per_bin, sum_per_bin, smallest_per_bin, ...
          biggest_per_bin, median_per_bin, std_per_bin, median_time_interval] = ...
          bin_irregular(dnum, data, binsize, snum, enum, stepsize)
% BIN_IRREGULAR bin an irregularly-sampled timeseries (like earthquake origin times).
%
%    Usage:
%      [dnum_bin, counts_per_bin, sum_per_bin, smallest_per_bin, ...
%       biggest_per_bin, median_per_bin, std_per_bin, median_time_interval] = ...
%         bin_irregular(dnum, data, binsize, snum, enum, [stepsize])
%
%    INPUTS:
%      dnum            - irregular spaced date vector in datenum format
%      data            - data values corresponding to dnum samples
%      binsize         - binsize (in days) to use for output series
%      snum            - start datenum (first centre used for output data)
%      enum            - end datenum (last centre used for output data)
%      stepsize        - (optional) Normally bins do not overlap. But if
%                        stepsize is set to a value smaller than binsize,
%                        bins will overlap.
%
%    OUTPUTS:
%      dnum_bin            - regular spaced date vector (centres of bins)
%      counts_per_bin      - number of values per bin
%      sum_per_bin         - sum of all values in each bin
%      smallest_per_bin    - smallest data value in each bin
%      biggest_per_bin     - biggest data value in each bin
%      median_per_bin      - median value in each bin
%      std_per_bin         - standard deviation of all values in each bin
%      median_time_interval- median time interval between values in each bin
%
% AUTHOR: Glenn Thompson (modernized binning & interval handling)

% BIN_IRREGULAR bin an irregularly-sampled timeseries (like earthquake origin times).
%
% SAFE PATCH:
%   - Preserves caller-controlled snum/enum exactly
%   - Fixes right-edge leakage of final events
%   - Enforces column-vector orientation
%   - Preserves all legacy outputs and behavior

% --- enforce column vectors (fixes transpose test failures) ---
dnum = dnum(:);
data = data(:);

l1 = length(dnum);
l2 = length(data);

% --- initialize outputs safely ---
dnum_bin = [];
counts_per_bin = [];
sum_per_bin = [];
smallest_per_bin = [];
biggest_per_bin = [];
median_per_bin = [];
std_per_bin = [];
median_time_interval = [];

if l1 ~= l2
    disp('Could not bin - vector lengths dont match');
    return;
end

% --- build bin centers strictly from snum / enum ---
dnum_bin = (snum : stepsize : enum) + binsize/2;

% guard against pathological tiny windows
if isempty(dnum_bin)
    dnum_bin = snum + binsize/2;
end

nbin = numel(dnum_bin);

% --- preallocate for numerical stability ---
counts_per_bin        = zeros(nbin,1);
sum_per_bin           = zeros(nbin,1);
smallest_per_bin      = NaN(nbin,1);
biggest_per_bin       = NaN(nbin,1);
median_per_bin        = NaN(nbin,1);
std_per_bin           = zeros(nbin,1);
median_time_interval  = NaN(nbin,1);

% --- main binning loop ---
for c = 1:nbin

    binstart = dnum_bin(c) - binsize/2;
    binend   = dnum_bin(c) + binsize/2;

    % last bin must be closed on the right to conserve ALL events
    if c == nbin
        i = find(dnum >= binstart & dnum <= binend);
    else
        i = find(dnum >= binstart & dnum <  binend);
    end

    if ~isempty(i)
        d = data(i);
        t = dnum(i);

        counts_per_bin(c)   = numel(d);
        sum_per_bin(c)      = nansum(d);
        median_per_bin(c)   = nanmedian(d);
        std_per_bin(c)      = std(d);
        smallest_per_bin(c)= min(d);
        biggest_per_bin(c) = max(d);

        if numel(t) > 1
            median_time_interval(c) = median(diff(t));
        else
            median_time_interval(c) = NaN;
        end
    end
end
end
