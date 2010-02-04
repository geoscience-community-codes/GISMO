function c = set(c, prop_name, val)

% SET Set properties for correlation object
%
% c = SET(c,prop_name,val)
%
% see help correlation/get.m for valid property names

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



if nargin <= 1
    error('Not enough inputs');
end

if ~strcmpi(class(c),'correlation')
    error('First argument must be a correlation object');
end


switch upper(prop_name)
    case {'WAVEFORMS' 'WAVEFORM' 'WAVES'}
        c.W = reshape(val,length(val),1);
    case {'TRIG'}
        c.trig = reshape(val,length(val),1);
    case {'CORR'}
        c.C = val;
    case {'LAG'}
        c.L = val;
    case {'STAT'}
        c.stat = val;
    case {'LINK'}
        c.link = val;
    case {'CLUST'}
        c.clust = val;
    otherwise
        warning('can''t understand property name');
        help correlation/set
end;


