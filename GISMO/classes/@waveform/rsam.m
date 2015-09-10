function s = rsam(w, method, samplingPeriod)
%RSAM create an RSAM-like object from a waveform object
%   s = rsam(waveform, method, samplingPeriod)
%
%   Input Arguments
%       WAVEFORM: waveform object       N-dimensional
%
%       METHOD: which method of sampling to perform within each sample
%                window
%           'max' : maximum value
%           'min' : minimum value
%           'mean': average value (Default)
%           'median' : mean value
%           'rms' : rms value (added 2011/06/01)
%
%       SAMPLINGPERIOD : the number of seconds between samples (Default:
%       60s)
%
%
%   Examples:
%       s = rsam(w) Each sample in the RSAM object is computed from a 60-s
%       window of data. Successive windows do not overlap. Each window is
%       detrended, NaN's replaced with mean value. Then the mean absolute
%       value - i.e. the mean amplitude - is taken.
%
%       s = rsam(w, 'rms') As above, but the root-mean-square absolute value
%       is taken.
%
%       s = rsam(w, 'max', 1.0) As above, but the max absolute value is
%       taken, and the time window is 1s rather than 60s.
%
% Glenn Thompson 2014/10/28
if ~exist('method', 'var')
    method = 'mean';
end
if ~exist('samplingPeriod', 'var')
    samplingPeriod = 60;
end

% detrend data and fill gaps
w = clean(w);

for i = numel(w)
    Wsamplingperiod = 1.0 / get(w(i), 'freq');
    % either set to whatever samplingPeriod seconds of data are, or the
    % length of data if less
    crunchfactor = min([round(samplingPeriod / Wsamplingperiod) numel(get(w(i),'data'))]);
    w(i) = set(w(i), 'data', abs(get(w(i),'data')) );
    w(i) = resample(w(i), method, crunchfactor);
    s(i) = rsam(datenum(w(i)), get(w(i),'data')', 'sta', get(w(i), 'station'), get(w(i), 'channel'));
end
