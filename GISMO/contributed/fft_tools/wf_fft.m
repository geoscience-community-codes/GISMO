function w = wf_fft(w);

% WAVEFORM = WF_FFT(WAVEWFORM)  calculate frequency spectrum of a waveform.
% The results of the fast fourier transform is added as new fields
% in the waveform:
%   FFT_FREQ is a vector of frequencies with N samples
%   FFT_AMP is a vector of spetral amplitudes
%   FFT_PHASE is a vector of phases
%   FFT_DOM is the scalar frequency of the maximum amplitude 
%           peak (or dominant frequency. This could change)

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks


% CHECK ARGUMENTS
if ~strcmpi(class(w),'waveform')
    error('First input must be a waveform object');
end


% STEP THROUGH WAVFORMS ADDING NEW FIELDS
[N,M] = size(w);
for i = 1:N*M
    Fn = get(w(i),'NYQ');
    x = get(w(i),'DATA');
    NFFT=2.^(ceil(log(length(x))/log(2)));  % Next highest power of 2
    FFTX=fft(x,NFFT);                       % Take fft, padding with zeros.
    NumUniquePts = ceil((NFFT+1)/2);
    FFTX=FFTX(1:NumUniquePts);              % throw out neg frequencies
    MX=abs(FFTX);                           % Take magnitude of X
    MX=MX*2;                                % Multiply by 2 
    MX=MX/length(x);                        
    PX=phase(FFTX);                           % Take magnitude of X
    f=(0:NumUniquePts-1)*2/NFFT;            
    f=f*Fn;
    w(i) = addfield(w(i),'FFT_FREQ',f');
    w(i) = addfield(w(i),'FFT_AMP',MX);
    w(i) = addfield(w(i),'FFT_PHASE',PX);
    a = find(MX == max(MX));
    w(i) = addfield(w(i),'FFT_DOM',f(a));
end;



