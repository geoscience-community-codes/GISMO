function w = diff (w)
%DIFF Differentiate waveform
%   waveform = diff(waveform)
%   goes from Displacement -> Velocity -> Acceleration
%
%   Input Arguments
%       WAVEFORM: a waveform object   N-DIMENSIONAL
%
%   Uses matlab's DIFF function to differentiate.  The way it handles the
%   units may be a little kludegy.
%
%   See also DIFF, WAVEFORM/INTEGRATE

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

Nmax = numel(w);

allFreq = get(w,'freq');

allUnits = get(w,'units'); %cell if numel(w)>1, char otherwise

if ~isCell(allUnits)
    allUnits = {allUnits};
end

for I = 1 : Nmax
    w(I) = set(w(I),'data',diff(w(I).data) .* allFreq(I));
    tempUnits = allUnits{I};
    whereInUnits = strfind(tempUnits,' * sec');
    if isempty(whereInUnits)
        w(I) = set(w(I),'units', [tempUnits, ' / sec']);
    else
        tempUnits(whereInUnits(1) :whereInUnits(1)+5) = [];
        w(I) = set(w(I),'units',tempUnits);
    end
end

w = addhistory(w,'Differentiated');