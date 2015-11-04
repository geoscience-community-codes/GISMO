function ml=Mlrichter(amax, R, a, b)
% default a & b after Lahr hypoellipse manual
if ~exist('a', 'var')
    a=1.6;
end
if ~exist('b', 'var')
    %b=-0.15;
    b=-0.2;
end
ml = log10(amax) + a * log10(R) + b;
