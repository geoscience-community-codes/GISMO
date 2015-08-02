function c = deconv(c,varargin)

% c = DECONV(c) convolves all traces with the final trace. By default the new
% correlation object has traces that are 2*N-1 samples long, where the
% original traces are of length N. Because all traces ...
% 
% ** NOTE TO USERS: Though most plotting routines normalize adjacent traces
% to comparable amplitudes for display, the real trace amplitudes often
% very by orders of magnitudes. Depending on the features the user is
% trying to highlight, it may make sense to normalize the trace amplitudes
% before stacking. This can be performed with the NORM function.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$





error('This code is not yet functional. Sorry - MEW');

% READ & CHECK ARGUMENTS
if (nargin>2)
    error('Wrong number of inputs');
end;

if ~strcmpi(class(c),'correlation')
    error('First input must be a correlation object');
end



% GENERAL PARAMETERS
c = verify(c);
traces = get(c,'Traces');
keyTrace = traces;


X = fft(double(c.W));      % all traces       
Y = repmat( fft(double(c.W(keyTrace))) , 1 , traces );   % single trace 




%Z = ifft(X ./ Y);  
e = 0.01 * sum(abs(Y(:,1)).^2);
numerator = X .* conj(Y) ;
denominator = abs(Y).^2 + e ;
%denominator = Y .* conj(Y) + e ;
Z = ifft( numerator ./ denominator );

save

for n = 1:traces
    c.W(n) = set( c.W(n) , 'DATA' , Z(:,n) );
end
