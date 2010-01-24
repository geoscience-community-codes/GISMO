function correlation_dianostics(varargin)

% Test correlation toolbox
%
% CORRELATION_DIAGNOSTICS('CONSTRUCTOR')
% Load and construct correlation objects in a variety of ways to test the
% construction function.

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks



if nargin==0
   error('at least one argument is required'); 
end

if nargin==1 && strncmpi(varargin{1},'CON',3)
    testconstructor;
else
   error('Arguments not recognized'); 
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FUNC: Test various constructor calls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function testconstructor()
c1 = correlation;
%
c2 = correlation('DEMO');
%
w = get(c2,'WAVEFORM');
c3 = correlation(w);
%
trig = get(w,'START') + 1/86400;
c4 = correlation(w,trig);
%
c5 = correlation(50);
%
correlation('README');
% 
correlation('COOK_BOOK');











