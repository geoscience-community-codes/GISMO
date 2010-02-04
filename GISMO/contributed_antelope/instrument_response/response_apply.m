function w = response_apply(w,resp)

%RESPONSE_APPLY applies an instrument response to a waveform.
% W = RESPONSE_APPLY(W,RESP) adjusts the waveform W to account for the
% instrument response RESP. Users should be aware of the pitfalls in
% attempting to correct for instrument response and are encouraged to high
% pass filter the data to the frequency band of interest and demean seismic
% waveforms prior to applying the instrument response.
%
% At this point RESPONSE_APPLY operates on a single (scalar) waveform at a
% time.

% Note about FFT. The FFT result has an even number of samples equal to the
% trace length. FFT(1) corresponds to freq=0. FFT(N/2+1) corresponds to the
% Nyquist frequency. With the exception of FFT(1), values in FFT are
% conjugate symmentric about N/2+1
%

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



error('This code is not yet functional. Sorry - MEW');

% BETA-TEST DATA
load response_samples
resp = resp_KCG;
tmpVal = respvals_KCG;
tmpVal = [tmpVal(1) tmpVal tmpVal(end)];
tmpFreq = [0.001 0.1:0.1: 10 1000];
c = correlation('demo');
butter(c,[3 15]);
w = waveform(c);
w = w(70);
save test_data
clear



load test_data

% TRANSORM WAVEFORM TO FREQUENCY DOMAIN
Fs = get(w,'FREQ');
data = get(w,'DATA');
dataLength = get(w,'DATA_LENGTH');
NFFT = 2^nextpow2(dataLength);
dataFreqDomain = fft(data,NFFT);             % 2048               
freqArray = Fs/2*linspace(0,1,NFFT/2+1)';    % 1025


% CREATE INSTRUMENT RESPONSE ON SAME FREQUENCIES
% responseArray = eval_response(resp,freqArray(2:end)*2*pi)
responseArray = interp1(tmpFreq,tmpVal,freqArray(2:end));  %% Temporary
responseArray = [ 0 ; responseArray ; conj(flipud(responseArray(1:end-1))) ];


% APPLY WATER LEVEL REGULARIZATION
%waterLevel = 1;
%f = find(abs(responseArray) < waterLevel);
%responseArray(f) = waterLevel .* responseArray(f) ./ abs(responseArray(f));



% MULTIPLY AND TRANSFORM BACK TO TIME DOMAIN
dataCorrected = ifft(dataFreqDomain ./ responseArray , 'symmetric' );


