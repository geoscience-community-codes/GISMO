function ml=Mlrichter(amax, R, a, b, g)
% MLRICHTER Compute a Richter local magnitude
%  ml=Mlrichter(amax, R, a, b, g)
%
%   amax = maximum amplitude measured from seismology
%   R = distance from earthquake to station (in km)
%   
%   equation is:
%       ml = log10(amax) + a * log10(R) + b;
%
%   from Lahr hypoellipse manual Chapter 4.2, defaults are a=1.6 & b=-0.15
%   this also agrees with Wikipedia for distances less than 200 km

% Glenn Thompson
if ~exist('a', 'var')
    a=1.6;
end
if ~exist('b', 'var')
    b=-0.15;
end
if ~exist('g', 'var') % station correction
    g=0;
end
ml = log10(amax) + a * log10(R) + b + g;

if r<0.1 | r>200
    warning('this Ml formula only for stations 0.1-200 km from quake');
end
