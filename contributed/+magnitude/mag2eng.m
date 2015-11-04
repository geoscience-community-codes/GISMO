function eng=mag2eng(mag);
% MAG2ENG Convert (a vector of) energy(/ies) into (a vector of) equivalent magnitude(s).
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
%   See also eng2mag

% AUTHOR: Glenn Thompson
% $Date$
% $Revision$

% for events without a magnitude, change it to -0.5 for energy calculation purposes

	mag(find(isnan(mag))) = -0.5;
	eng = power(10, (1.5 * mag + 4.7));


