function ml=Mlrichter(amax, R, a, b)
% MLRICHTER Compute a Richter local magnitude
%  ml=Mlrichter(amax, R, a, b)
%
%   amax = maximum amplitude measured from seismology
%   R = distance from earthquake to station (in km or degrees?)
%   
%   equation is:
%       ml = log10(amax) + a * log10(R) + b;
%
%   from Lahr hypoellipse manual, defaults are a=1.6 & b=-0.2

% Glenn Thompson
if ~exist('a', 'var')
    a=1.6;
end
if ~exist('b', 'var')
    b=-0.2;
end
ml = log10(amax) + a * log10(R) + b;
