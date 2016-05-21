function s = add_spectral_data(w)
    % add_spectral_data Simple method to compute frequency
    % spectrum for a vector waveform object. Uses the MATLAB fft function.
    %   w = add_spectral_data(w)
    %
    %   Inputs:
    %       w - a waveform object (or vector of waveform objects)
    %
    %   Outputs:
    %       s - a structure for each waveform containing:
    %           f - the frequency values corresponding to elements of amp and phi
    %           amp - amplitude spectrum values
    %           phi - phase angle values (in radians)
    %           peakf - peak frequency
    %           meanf - mean frequency
    %           freqindex - frequency index (Buurman & West)
    %           freqratio - frequency ratio (Rodgers)
    %
    %   Example 1 (for a single waveform object, w):
    %       s = add_spectral_values(w)
    %       semilogx(s.f, s.amp)
    %       xlabel('Frequency (Hz)')
    %       ylabel('Amplitude');
    %       
    %   Example 2 (for a waveform vector, w)
    %       s = add_spectral_values(w);
    %       t = get(w, 'start')
    %       peakf = [s.peakf];
    %       plot(t, peakf,'o')
    %       datetick('x')
    %
    %   Glenn Thompson, May 21, 2016 after amplitude_spectrum function of November 21, 2014.
    
	% Check input is a waveform object
	if ~isa(w, 'waveform')
		warning('Not a waveform object')
		return
    end
    
    for count = 1:numel(w)
        Fsamp= get(w(count), 'freq');
        signal=get(w(count), 'data');
        Nsignal=length(signal);
        NFFT = 2^nextpow2(Nsignal); % Next power of 2 from length of y
        Y=fft(signal,NFFT); % X will have same length as signal, and will be complex with a magnitude and phase
        NumUniquePts = NFFT/2 + 1; % Mike uses ceil((N+1)/2) in wf_fft
        A=2*abs(Y(1:NumUniquePts))/Nsignal;
        phi = angle(Y(1:NumUniquePts));
        f = Fsamp/2*linspace(0,1,NumUniquePts);
        
        % add spectrum vectors to a structure
        s(count).f = f; % frequencies
        s(count).amp = A'; % amplitude 
        s(count).phi = phi'; % phase angle in radians
        
        % peak frequency
        s(count).peakf = f(find(A == max(A)));
        
        % mean frequency
        s(count).meanf = sum(s(count).f.*s(count).amp)/sum(s(count).amp);
        
        % frequency ratio
        Al = mean(A(find(f >= 1 & f <= 2)));
        Ah = mean(A(find(f >= 10 & f <= 20)));
        s(count).freqindex = log10(Ah/Al);
        
        % frequency ratio
        Al = mean(A(find(f >= 1 & f <= 5)));
        Ah = mean(A(find(f >= 5 & f <= 15)));
        s(count).freqratio= log2(Ah/Al);
       
    end
end