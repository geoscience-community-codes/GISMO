function w = uminus(w)
%-  Unary minus.
%   -A negates the elements of A.
%
%   B = UMINUS(A) is called for the syntax '-A' when A is an object.

%   Copyright 1984-2005 The MathWorks, Inc.
%   $Revision: 1.9.4.4 $  $Date: 2005/06/21 19:36:38 $

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 5/2/2007
for n=1:numel(w)
    w(n) = set(w(n),'data', - double(w(n)));
end
