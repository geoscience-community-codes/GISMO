function c = taper(c,varargin)

%TAPER tapers the ends of waveforms in the correlation object.
%
%C = TAPER(C,R) applies a cosine taper to the ends of a trace where r is
% the ratio of tapered to constant sections and is between 0 and 1. For
% example, if R = 0.1 then the taper at each end of the trace is 5% of the
% total trace length. Note that if R is set to 1 the resulting taper is a
% hanning window. This is a wrapper script to the taper function in the
% waveform toolbox. If R is a vector of the same size as WAVEFORM. See HELP
% WAVEFORM/TAPER for specifics.
%
%C = TAPER(C) same as above with a default taper of R = 0.2.
%
% Note that TAPER will also accept R as a vector of length equal to the
% number of traces. For the purposes of the correlation toolbox, it is not
% clear to me when/if this might ever be useful - MEW.
%

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


% READ & CHECK ARGUMENTS
if ~strcmpi(class(c),'correlation')
    error('First input must be a correlation object');
end


% GET TAPER STYLE
style = 'cosine';
if length(varargin)>0 
    if isa(varargin{end},'char')
        style = varargin{end};
        varargin = varargin(1:end-1);
    end
end


% COSINE TAPER
if strcmpi(upper(style),'COSINE')
    if length(varargin)==1
        R = varargin{1};
    elseif length(varargin)==0
        R = 0.2;
    else
        error('Wrong number of inputs for cosine taper');
    end
end

    
% APPLY TAPER
c.W = taper(c.W,R,style);
    


