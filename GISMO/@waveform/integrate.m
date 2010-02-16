function w = integrate (w,method)
%INTEGRATE integrates a waveform signal
%   waveform = integrate(waveform, [method])
%   goes from Acceleration -> Velocity, and from Velocity -> displacement
%
%   wave = integrate(waveform)  or  
%   wave = integrate(waveform,'cumsum') performs integration by summing the
%   data points with the cumsum function, taking into account time interval
%   and updating the units as appropriate.
%
%   waveform = integrate(waveform, 'trapz') as above, but uses matlab's
%   cumtrapz function to perform the integration.

%   Input Arguments
%       WAVEFORM: a waveform object   N-DIMENSIONAL
%       METHOD: either 'cumtrapz' or 'cumsum'  [default is cumsum]
%
%   Actual implementation  merely does a cumulative sum of the waveform's
%   samples, and updates the units accordingly.  These units may be a
%   little kludgey.
%
%
%   See also CUMSUM, CUMTRAPZ, WAVEFORM/DIFF

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision $

Nmax = numel(w);
allfreq = get(w,'freq');

if ~exist('method','var')
    method = 'cumsum';
end

switch lower(method)
    case 'cumsum'
        integratefn = str2func('cumsum');
    case 'trapz'
        integratefn = str2func('cumtrapz');
    otherwise
        error('Waveform:integrate:unknownMethod',...
            'Unknown integration method.  Valid methods are ''cumsum'' and ''trap''');        
end

for I = 1 : Nmax
    w(I) = set(w(I),'data',integratefn(w(I).data) ./ allfreq(I));
    tempUnits = get(w(I),'units');
    whereInUnits = strfind(tempUnits,' / sec');
    if isempty(whereInUnits)
        w(I) = set(w(I),'units', [tempUnits, ' * sec']);
    else
        tempUnits(whereInUnits(1) :whereInUnits(1)+5) = [];
        w(I) = set(w(I),'units',tempUnits);
    end
    %w(I) = set(w(I),'units', [get(w(I),'units'), ' * sec']);
end

w = addhistory(w,'Integrated');