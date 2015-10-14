function [A, phi, f] = amplitude_spectrum(w)
    % waveform.amplitude_spectrum Simple method to compute amplitude
    % spectrum for a waveform object. Uses the MATLAB fft function.
    %   [A, phi, f] = amplitude_spectrum(w)
    %
    %   Inputs:
    %       w - a single waveform object (not a vector of waveforms)
    %
    %   Outputs:
    %       A - the amplitude coefficients
    %       phi - the phase coefficients
    %       f - the frequency values corresponding to elements of A and phi
    %
    %   Example:
    %       [A phi, f] = amplitude_spectrum(w)
    %       plot(f,A); 
    %       xlabel('Frequency (Hz)')
    %       ylabel('Amplitude');
    %
    %   Glenn Thompson, November 21, 2014
    
	% Check input is a waveform object
	if ~isa(w, 'waveform')
		warning('Not a waveform object')
		return
    end
    
    Fs= get(w, 'freq');
    signal=get(w, 'data');
    N=length(signal);
    NFFT = 2^nextpow2(N); % Next power of 2 from length of y
    Y=fft(signal,NFFT); % X will have same length as signal, and will be complex with a magnitude and phase
    A=2*abs(Y(1:NFFT/2+1))/N;
    phi = angle(Y);
    f = Fs/2*linspace(0,1,NFFT/2+1);
end