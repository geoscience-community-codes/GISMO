function A = getval(OBJ,PROP)

% Function to extract a cell array from an 
% object and convert it into an array of values. 
% Basically it applies the {} operator to all 
% values in the array.
%
% NOTE: This routine is only valid for properties that returns a single
% value per waveform.
%

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


A = [];
Ao = get(OBJ,PROP);
for i = 1:length(Ao)
    A = cat(1,A,Ao{i});
end;
%A = A';
