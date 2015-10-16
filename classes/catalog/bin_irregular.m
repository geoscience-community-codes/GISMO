function [dnum_bin, counts_per_bin, sum_per_bin, smallest_per_bin, biggest_per_bin, median_per_bin, std_per_bin, median_time_interval] = bin_irregular(dnum, data, binsize, snum, enum, stepsize)
% BIN_IRREGULAR bin an irregularly-sampled timeseries (like earthquake origin times).
%
%    Usage:
%      [dnum_bin, counts_per_bin, sum_per_bin, smallest_per_bin, biggest_per_bin, median_per_bin, std_per_bin, median_time_interval] = bin_irregular(dnum, data, binsize, snum, enum, [stepsize])
%
%    INPUTS:
%      dnum            - irregular spaced date vector in datenum format
%      data            - data values corresponding to dnum samples
%      binsize         - binsize (in days) to use for output series
%      snum            - start datenum (first centre used for output data)
%      enum            - end datenum (last centre used for output data)
%      stepsize        - (optional) Normally bins do not overlap. But if stepsize is set to a value smaller than binsize, bins will overlap.
%
%    OUTPUTS:
%      dnum_bin        	- regular space date vector (centres of bins)
%      counts_per_bin  	- number of values per bin
%      sum_per_bin     	- sum of all values in each bin
%      smallest_per_bin 	- smallest data value in each bin
%      biggest_per_bin 	- biggest data value in each bin
%      median_per_bin  	- median value in each bin
%      std_per_bin     	- standard deviation of all values in each bin
%      median_time_interval - median time interval between values in each bin
%
%    See also: 

% AUTHOR: Glenn Thompson
% $Date$
% $Revision$
l1=length(dnum);
l2=length(data);
dnum_bin = [];
counts_per_bin = [];
sum_per_bin = [];
smallest_per_bin = [];
biggest_per_bin = [];
median_per_bin = [];
std_per_bin = [];
median_time_interval = [];

if (l1==l2) 
    dnum_bin = snum+binsize/2 : stepsize : enum-binsize/2; % centres of the bins
    for c=1:length(dnum_bin)
	binstart = dnum_bin(c) - binsize/2; % start of this bin
	binend = dnum_bin(c) + binsize/2;   % end of this bin
	i = find(dnum >= binstart & dnum < binend);
	if length(i)>0
		d = data(i);
		thisdnum = dnum(i);
		counts_per_bin(c) = length(d);
		sum_per_bin(c)=nansum(d);
		median_per_bin(c)=nanmedian(d);
		std_per_bin(c) = std(d);
        	smallest_per_bin(c)=min(d);
        	biggest_per_bin(c)=max(d);
		median_time_interval(c)=median(thisdnum(2:end)-thisdnum(1:end-1));
	else
		counts_per_bin(c) = 0;
		sum_per_bin(c) = 0;
		std_per_bin(c) = 0;
		median_per_bin(c) = NaN;
		smallest_per_bin(c)=NaN;
		biggest_per_bin(c)=NaN;
	end
    end
else
    disp('Could not bin - vector lengths dont match');
end

