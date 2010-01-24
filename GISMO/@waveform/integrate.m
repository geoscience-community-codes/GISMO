function w = integrate (w)
%INTEGRATE integrates a waveform signal
%   waveform = integrate(waveform)
%   goes from Acceleration -> Velocity, and from Velocity -> displacement
%
%   Input Arguments
%       WAVEFORM: a waveform object   N-DIMENSIONAL
%
%   Actual implementation  merely does a cumulative sum of the waveform's
%   samples, and updates the units accordingly.  These units may be a
%   little kludgey.
%
%
%   See also CUMSUM, WAVEFORM/DIFF

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/14/2009

Nmax = numel(w);

for I = 1 : Nmax
    w(I) = set(w(I),'data',cumsum(double(w(I))) ./ get(w(I),'freq'));
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