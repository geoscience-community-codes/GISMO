function c = conv(c,varargin)

% c = CONV(c) convolves all traces with the final trace. By default the new
% correlation object has traces that are 2*N-1 samples long, where the
% original traces are of length N. Because all traces ...

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks


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


X = fft(double(c.W));             
Y = repmat( fft(double(c.W(keyTrace))) , 1 , traces );    

save

Z = ifft(X.*conj(Y));  
for n = 1:traces
    c.W(n) = set( c.W(n) , 'DATA' , Z(:,n) );
end
