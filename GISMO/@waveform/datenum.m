function dnum = datenum(W)
%DATENUM returns datenum's corresponding to waveform's data as a double type
%   dnum = datenum(waveform)
%
%   Input Arguments
%       WAVEFORM: a waveform object   1xN DIMENSIONAL

%   Output Arguments
%       DNUM: datenum's corresponding to WAVEFORM
%
%   example:
%       dnum = datenum(w);
%
% See also DATENUM
%
% Notes: 
% (1) dnum = get(w, 'timevector') achieves the same result as this function.
%     But it makes more sense to overload the "datenum" function, as done here.
% (2) To plot against dates, you do not need to call this function, just use:
%	plot(w, 'xunit', 'date');
%
% To do: 
% This function be modified to work on a matrix of waveforms, using size, numel, reshape etc.
% Currently it only works on a vector of waveforms.
%
% AUTHOR: Glenn Thompson, Geophysical Institute, Univ. of Alaska Fairbanks

[snum, enum] = gettimerange(W);
for c=1:length(snum)
    fs = get(W(c), 'freq');
    t = snum(c) : 1/fs/86400 : enum;
    l = length(get(W, 'data'));
    if length(t) > l
        t = t(1:l);
    end
    dnum{c} = t;
        
end
if length(dnum)==1
    dnum = dnum{1};
end
