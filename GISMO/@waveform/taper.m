function w = taper(w,R, style)

% WAVEFORM = TAPER(WAVEFORM,R) applies a cosine taper to the ends of a
% trace where r is the ratio of tapered to constant sections and is between
% 0 and 1. For example, if R = 0.1 then the taper at each end of the trace
% is 5% of the total trace length. R can be either a scalar or the same
% size as WAVEFORM. If R is a scalar, it is applied uniformly to each
% waveform. Note that if R is set to 1 the resulting taper is a hanning
% window.
%
% WAVEFORM = TAPER(WAVEFORM) same as above with a default taper of R = 0.2.
%
% TODO: Currently, only cosine tapers are supported. The code is set up to
% accept other window shapes as a final argument, e.g.
% taper(waveform,R,'cosine'). However other window shapes have not yet been
% implimented. - MEW

% AUTHOR: Michael West
% $Date$
% $Revision$
% Modified: Celso Reyes


% CHECK WAVEFORM
if ~strcmpi(class(w),'waveform')
    error('Waveform:taper:missingWaveform',...
        'First input must be a waveform object');
end

if ~exist('R','var') || isempty(R)
    R = 0.2; %assign default taper
elseif ~isnumeric(R)
    error('Waveform:taper:InvalidRValue',...
        'R, if specified, must be numeric');
end

if ~exist('style','var') || isempty(style)
    style = 'COSINE';
end


if isscalar(R)
    R = repmat(R,size(w));
end

if (isvector(R) && isvector(w)) && numel(R) == numel(w)
    if all(size(w)) ~= size(R)
        % same number of elements, but R is Nx1 and w is 1xN or vice-versa
        warning('Waveform:taper:columnsVsRows',...
            ['One input (either R or the wavform) is arranged in '...
            'columns while the other is arranged in Rows.  While they '...
            'should be the same shape, taper is continuing with R''']);
        R = R';
    end
end

if ~all(size(w) == size(R))
    error('Waveform:taper:InvalidRSize',...
        'R must either be a scalar value, or must be the same size as the input waveforms');
end

switch upper(style)
    case 'COSINE'
        for n=1:numel(w)
            w(n) = docosine(w(n),R(n));
        end
    case 'GAUSSIAN'
        %not implemented, placeholder only.
        error('Waveform:taper:invalidTaperType',...
            'Gaussian taper is not yet implimented');
    otherwise
        error('Waveform:taper:invalidTaperType',...
            'This style of taper is not recognized.');
end;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% apply cosine taper to waveforms
function w = docosine(w,r)
%applied to individual waveforms only
w = w .* tukeywin( numel(w.data) , r );
end



