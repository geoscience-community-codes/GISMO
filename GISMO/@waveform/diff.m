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

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/14/2009

Nmax = numel(w);

for I = 1 : Nmax
    w(I) = set(w(I),'data',diff(double(w(I))) .* get(w(I),'freq'));
    tempUnits = get(w(I),'units');
    whereInUnits = strfind(tempUnits,' * sec');
    if isempty(whereInUnits)
        w(I) = set(w(I),'units', [tempUnits, ' / sec']);
    else
        tempUnits(whereInUnits(1) :whereInUnits(1)+5) = [];
        w(I) = set(w(I),'units',tempUnits);
    end
end

w = addhistory(w,'Differentiated');