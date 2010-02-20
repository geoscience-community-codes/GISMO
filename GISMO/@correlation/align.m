function c = align(c,varargin)

% c = ALIGN(c)
% This function resamples the traces in a correlation object so that one
% sample falls precisely on the trigger time. By aligning the samples in
% adjacent traces, traces can be stacked, differenced or otherwise
% manipulated sample by sample. 
% 
% c = ALIGN(c,ALIGNFREQ)
% Specify a new sampling frequency for the data.
%
% NOTE: Most applications will not require a direct call to this routine.
% It is used internally by several correlation routines. Note the slightly
% different usage than waveform/align. The correlation version is
% hardwired to align on the trigger time.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$




% READ & CHECK ARGUMENTS
if (nargin>2)
    error('Wrong number of inputs');
end;

if ~strcmpi(class(c),'correlation')
    error('First input must be a correlation object');
end

if nargin==2
    alignfreq = varargin{1};
else
    alignfreq = get(c,'Fs');
end
    
    
% CALL WAVEFORM/ALIGN
c.W = align(c.W,c.trig,alignfreq);
c = verify(c);







