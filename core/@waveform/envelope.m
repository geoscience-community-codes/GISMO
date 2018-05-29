function [wupper, wlower] = envelope(w,varargin)
% ENVELOPE Create envelopes of waveform objects.
%   [wupper, wlower] = envelope(w, varargin) Runs the built-in MATLAB 
%      envelope function on a waveform object. For other arguments, please 
%      type 'help envelope'. The upper and lower bounds of the waveform 
%      object are returned as the waveform objects 'wupper' and 'wlower'. 
%
%   If input w is a vector/array of waveform objects, then the wupper and
%   wlower returned will be of the same dimension.

% Glenn Thompson 2018/05/11

    if strcmp(class(w),'waveform')
        s = size(w);
        n = numel(w);
        wupper = repmat(waveform(), s(1), s(2));
        wlower = repmat(waveform(), s(1), s(2));
        for c=1:n
            [yupper, ylower] = envelope(get(w(c),'data'),varargin{:});
            wupper(c) = set(w(c),'data',yupper);
            wlower(c) = set(w(c),'data',ylower);
        end
    else
        error('input is not a valid waveform object')
    end

end
        