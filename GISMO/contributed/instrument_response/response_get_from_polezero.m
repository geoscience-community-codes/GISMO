function response = response_get_from_polezero(frequencies,polezero)

%RESPONSE_GET_FROM_POLEZERO Create response structure from poles/zeros
%  RESPONSE = RESPONSE_GET_FROM_POLEZERO(FREQUENCIES,POLEZERO) Reads in
%  pole zero information and returns the complex response at the
%  frequencies specified by FREQUENCIES. FREQUENCIES is a vector of
%  freqeuncies specified in Hz.


%     
%     
% polezero.poles = [
%       -4.21+4.66i
%       -4.21-4.66i
%     -133.29+133.29i
%     -133.29-133.29i
%     -133.29+133.29i
%     -133.29-133.29i ];
% 
% polezero.poles = [
%     0
%     0];
% 
% polezero.normalization = 1.6916e+009;



% INITIALIZE THE OUTPUT ARGUMENT
response.scnl = scnlobject('--','--','','');
response.time = datenum('1970/1/1');
response.frequencies = reshape(frequencies,numel(frequencies),1);
response.values = [];
response.calib = NaN;
response.units = '--';
response.sampleRate = '--';
response.source = 'FUNCTION: RESPONSE_GET_FROM_POLEZERO';
response.status = [];


% Pole/zeros can be normalized with the following if not already normalized:
% normalization = 1/abs(polyval(poly(polezero.zeros),2*pi*1i)/polyval(poly(polezero.poles),2*pi*1i));


% CALCULATE COMPLEX RESPONSE AT SPECIFIED FREQUENCIES
ws = (2*pi) .* response.frequencies;
response.values = freqs(polezero.normalization*poly(polezero.zeros),poly(polezero.poles),ws);


