function mag=eng2mag(eng);
% ENG2MAG Convert a (vector of) magnitude(s) into a (vector of) equivalent energy(/ies).
%   
%   Conversion is based on the the following formula from Hanks and Kanamori (1979):
%
%      mag = log10(energy)/1.5 - 4.7
%
%   That is, energy (Joules) is roughly proportional to the peak amplitude to the power of 1.5.
%   This obviously is based on earthquake waveforms following a characteristic shape.
%   For a waveform of constant amplitude, energy would be proportional to peak amplitude
%   to the power of 2.
%
%   For Montserrat data, when calibrating against events in the SRU catalog, a factor of
%   3.7 was preferred to 4.7.
%
%   See also mag2eng

% AUTHOR: Glenn Thompson
% $Date$
% $Revision$


	mag = (log10(eng) - 4.7) / 1.5; 	

