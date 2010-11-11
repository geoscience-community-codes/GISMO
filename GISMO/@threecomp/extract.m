function pm = extract(TC,varargin)

%EXTRACT particle motion parameters from a threecomp object
% PM = EXTRACT(TC,[START END]) extracts particle motion parameters from a single
% threecomp object. START and END are Matlab times which bracket the
% extraction. The output structure, PM, is the same size as threecomp
% object TC and has similar fields. However, instead of the particle motion
% fields being represented by waveforms (as in TC), they are scalar values
% that represent mean or median measures over the time interval defined by
% START and END.
%
% PM = EXTRACT(TC,[START END],[REC_THRESHOLD, PLAN_THRESHOLD]) The azimuth
% and inclination coefficients only have meaning if the degfree of
% rectilinearity, and sometimes, planarity, is high. The threshold terms
% allow users to set minimum rectilinearity and planarity values. The time
% range set by START and END is scanned for sufficiently high
% rectilinearity and planarity. Only those time steps which meet the
% threshold values are included in the mean/median calculations. The
% default values of this term err on the inclusive side [0.5 0].
%
% see also threecomp/describe

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


if ~isa(TC,'threecomp')
    error('Threecomp:extract:badArgument', ...
        ['First argument must be a threecomp object.']);
end


% GET TIME WINDOW
if length(varargin)>=1
    if isa(varargin{1},'double') && numel(varargin{1})==2
        times = reshape(varargin{1},1,2);
    else
            error('Threecomp:exgtract:badArgument','second argument must be a two element timer vector');
    end
else
   error('Threecomp:exgtract:wrongNumberArguments','incorrect number of arguments'); 
end


% GET THRESHOLDS
if length(varargin)>=2
    if isa(varargin{2},'double') && numel(varargin{2})==2
        thresholds = reshape(varargin{2},1,2);
    else
        error('Threecomp:exgtract:badArgument','third argument must be a two element timer vector');
    end
else
    thresholds = [0.5 0];
end



% EXTRACT VALUES FOR EACH
for n = 1:length(TC)
    [pm(n)] = do_one(TC(n),times,thresholds,n);
end
pm = reshape(pm,size(TC));




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract a single set of particle motions
function pm = do_one(TC,times,thresholds,num)


if all(times>datenum('01/01/1900')) && all(times<datenum('01/01/2100'))
    times = times;
elseif all(abs(times)<100000)
    times = times./86400 + TC.trigger;
else
    error('Threecomp:exgtract:badTimeFormat','time format not recognized');
end


% EXTRACT MEAN PARTICLE MOTIONS
pm.rectilinearity = double(extract(TC.rectilinearity,'TIME',times(1),times(2)));
pm.planarity = double(extract(TC.planarity,'TIME',times(1),times(2)));
pm.energy = double(extract(TC.energy,'TIME',times(1),times(2)));
pm.azimuth = double(extract(TC.azimuth,'TIME',times(1),times(2)));
pm.inclination = double(extract(TC.inclination,'TIME',times(1),times(2)));


% GET MEAN TERMS ABOVE THRESHOLDS
f = find( pm.rectilinearity>=thresholds(1) & pm.planarity>=thresholds(2) );
pm.rectilinearity = mean(pm.rectilinearity(f));
pm.planarity = mean(pm.planarity(f));
pm.energy = mean(pm.energy(f));
pm.azimuth = median(pm.azimuth(f));
pm.inclination = median(pm.inclination(f));
pm.time = mean(times);

% TODO: include some type pf error estimate for angular parameters

