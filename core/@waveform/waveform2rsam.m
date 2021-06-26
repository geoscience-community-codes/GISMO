function s = waveform2rsam(w, measure, samplingIntervalSeconds)
%WAVEFORM2RSAM create an RSAM-like object from a waveform object
% RSAM data are typically 1 sample per minute, where each sample is the 
% average amplitude of that minute of data. They are used extensively used
% in volcano monitoring.
%
% Usage:
%   s = rsam(waveform, method, samplingIntervalSeconds)
%
%   Input Arguments
%       WAVEFORM: waveform object       N-dimensional
%
%       MEASURE: which method of sampling to perform within each sample
%                window
%           'max' : maximum value
%           'min' : minimum value
%           'mean': average value (Default)
%           'median' : mean value
%           'rms' : rms value (added 2011/06/01)
%           'rsem' : square each sample in the interval and sum
%
%       samplingIntervalSeconds : the number of seconds between samples (Default:
%       60s)
%
%
%   Examples:
%       s = waveform2rsam(w) Each sample in the RSAM object is computed from a 60-s
%       window of data. Successive windows do not overlap. Each window is
%       detrended, NaN's replaced with mean value. Then the mean absolute
%       value - i.e. the mean amplitude - is taken.
%
%       s = waveform2rsam(w, 'rms') As above, but the root-mean-square absolute value
%       is taken.
%
%       s = waveform2rsam(w, 'max', 1.0) As above, but the max absolute value is
%       taken, and the time window is 1s rather than 60s.
%
% Glenn Thompson 2014/10/28
if ~exist('measure', 'var')
    measure = 'mean';
end
if ~exist('samplingIntervalSeconds', 'var')
    samplingIntervalSeconds = 60;
end

% clean waveform objects - to remove linear and non-linear trends
w = clean(w);

for i = 1:numel(w)
    if ~isempty(w(i))
        WsamplingIntervalSeconds = 1.0 / get(w(i), 'freq');
        % either set to whatever samplingIntervalSeconds seconds of data are, or the
        % length of data if less
        crunchfactor = min([round(samplingIntervalSeconds / WsamplingIntervalSeconds) numel(get(w(i),'data'))]);
        if strcmp(measure, 'rsem') % RSEM data
            y2 = power(get(w(i),'data'),2); % square each sample & divide by samples per second
            % the energy is now the sum in any time interval
            wenergy = set(w(i), 'data', y2 );
            wresamp = resample(wenergy, 'mean', crunchfactor); % this takes the average squared-sample level at say 60-second intervals.
            wresamp = wresamp * samplingIntervalSeconds; % multiplying the average squared-sample by the sampling interval is same as
            s(i) = rsam(get(wresamp,'timevector')', get(wresamp,'data')', ...
                'ChannelTag', get(wresamp, 'ChannelTag'), ...
                'measure', 'rsem', ...
                'units', get(wresamp, 'units'));
        else
            wabs = set(w(i), 'data', abs(get(w(i),'data')) );
            wresamp = resample(wabs, measure, crunchfactor);
            s(i) = rsam(get(wresamp,'timevector')', get(wresamp,'data')', ...
                'ChannelTag', get(wresamp, 'ChannelTag'), ...
                'measure', measure, ...
                'units', get(wresamp, 'units'));
        end
    else
        s(i) = rsam([], [], ...
            'ChannelTag', get(w(i), 'ChannelTag'), ...
            'measure', measure, ...
            'units', get(w(i), 'units'));
    end
end
