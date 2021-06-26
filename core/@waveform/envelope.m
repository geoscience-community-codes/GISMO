function [wupper, wlower] = envelope(w,smoothingseconds)
% ENVELOPE Create envelopes of waveform objects.
%   [wupper, wlower] = envelope(w, smoothingseconds) Runs the built-in MATLAB 
%      envelope function on a waveform object. The default smoothing
%      interval is 1-second. The upper and lower bounds of the waveform 
%      object are returned as the waveform objects 'wupper' and 'wlower'. 
%
%   If input w is a vector/array of waveform objects, then the wupper and
%   wlower returned will be of the same dimension.

% Glenn Thompson 2018/05/11
% Modified 2020/06/24 to use number of seconds (no more varargin)

    if strcmp(class(w),'waveform')
        s = size(w);
        n = numel(w);
        wupper = repmat(waveform(), s(1), s(2));
        wlower = repmat(waveform(), s(1), s(2));
        for c=1:n
            if exist('smoothingseconds','var')
                smoothingsamples = get(w(c),'freq') * smoothingseconds;
            else
                smoothingsamples = get(w(c),'freq');
            end
            %[yupper, ylower] = envelope(get(w(c),'data'),varargin{:});
            [yupper, ylower] = envelope(get(w(c),'data'),smoothingsamples,'rms');
            wupper(c) = set(w(c),'data',yupper);
            wlower(c) = set(w(c),'data',ylower);
        end
    else
        error('input is not a valid waveform object')
    end

end
        