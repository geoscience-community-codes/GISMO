function response = response_get_from_polezero(frequencies, polezero)
%RESPONSE_GET_FROM_POLEZERO Create response structure from poles/zeros
%  RESPONSE = RESPONSE_GET_FROM_POLEZERO(FREQUENCIES,POLEZERO)
%
%  POLEZERO may be either:
%   (1) a struct with fields: poles, zeros, normalization
%   (2) a sacpz object (with fields z, p, k and metadata)
%
%  FREQUENCIES is a vector of frequencies in Hz.

% ---- validate / reshape frequencies ----
if nargin < 2
    error('response_get_from_polezero:missingInputs', ...
        'Usage: response_get_from_polezero(frequencies, polezero)');
end
if isempty(frequencies)
    error('response_get_from_polezero:emptyFrequencies', 'FREQUENCIES must be non-empty.');
end
frequencies = frequencies(:);

% ---- normalise polezero input (struct or sacpz) ----
if isa(polezero, 'sacpz')
    % Pull values from sacpz object
    zeros_ = polezero.z(:);
    poles_ = polezero.p(:);
    gain_  = polezero.k;

    % Metadata (optional but useful)
    scnl = scnlobject(polezero.station, polezero.channel, polezero.network, polezero.location);
    t0   = polezero.starttime;
    units = polezero.outputunit;
    sr    = polezero.samplerate;
    src   = 'FUNCTION: RESPONSE_GET_FROM_POLEZERO (via sacpz)';

    if isempty(gain_) || ~isfinite(gain_)
        error('response_get_from_polezero:missingGain', ...
            'sacpz.k (CONSTANT) is missing/invalid; cannot compute response.');
    end

elseif isstruct(polezero)
    % Backwards-compatible struct path
    if ~isfield(polezero,'zeros') || ~isfield(polezero,'poles')
        error('response_get_from_polezero:badStruct', ...
            'polezero struct must contain fields .zeros and .poles');
    end
    if ~isfield(polezero,'normalization')
        error('response_get_from_polezero:badStruct', ...
            'polezero struct must contain field .normalization (gain)');
    end

    zeros_ = polezero.zeros(:);
    poles_ = polezero.poles(:);
    gain_  = polezero.normalization;

    % Keep legacy defaults unless metadata exists
    scnl = scnlobject('--','--','','');
    t0   = datenum('1970/1/1');
    units = '--';
    sr    = '--';
    src   = 'FUNCTION: RESPONSE_GET_FROM_POLEZERO';

else
    error('response_get_from_polezero:badInputType', ...
        'POLEZERO must be a struct or a sacpz object.');
end

% ---- build response struct ----
response.scnl = scnl;
response.time = t0;
response.frequencies = frequencies;
response.values = [];
response.calib = NaN;
response.units = units;
response.sampleRate = sr;
response.source = src;
response.status = [];

% ---- compute complex response ----
ws = 2*pi*response.frequencies;  % rad/s
response.values = freqs(gain_ * poly(zeros_), poly(poles_), ws);

end