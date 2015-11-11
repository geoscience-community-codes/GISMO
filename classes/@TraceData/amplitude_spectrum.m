      function [A, phi, f] = amplitude_spectrum(td)
         %amplitude_spectrum   Simple method to compute amplitude
         %   spectrum for a trace. Uses the MATLAB fft function.
         %   [A, phi, f] = amplitude_spectrum(td)
         %
         %   Inputs:
         %       td - a single TraceData
         %
         %   Outputs:
         %       A - the amplitude coefficients
         %       phi - the phase coefficients
         %       f - the frequency values corresponding to elements of A and phi
         %
         %   Example:
         %       [A phi, f] = amplitude_spectrum(td)
         %       plot(f,A);
         %       xlabel('Frequency (Hz)')
         %       ylabel('Amplitude');
         %
         %   See also fft
         %   Glenn Thompson, November 21, 2014
         
         %TODO: Rename this to amplitudespectrum or move it elsewhere
         
         N = length(td.data);
         NFFT = 2 ^ nextpow2(N); % Next power of 2 from length of y
         Y = fft(td.data, NFFT); % X will have same length as signal, and will be complex with a magnitude and phase
         A = 2 * abs(Y(1:NFFT/2+1)) / N;
         phi = angle(Y);
         f = td.samplerate / 2 * linspace(0,1,NFFT/2+1);
      end