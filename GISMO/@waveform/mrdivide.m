function C = mrdivide(W,B) 
%MRDIVIDE (/) Slash or right matrix divide for WAVEFORMS.

% VERSION: 1.0 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/15/2009

if ~(isnumeric(B))
    error('Waveform:mrdivide:invalidNumeratorClass',...
      'Cannot divide by a %s, must be numeric', class(B));
end

C = set(W, 'data', get(W,'data') / double(B));

C = addhistory(C, ['Divided by ' num2str(B)]);