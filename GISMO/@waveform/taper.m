function w = taper(w,varargin)

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

% VERSION: 1.1 of waveform objects
% AUTHOR: Michael West
% LASTUPDATE: 2/15/2007


% CHECK WAVEFORM
if ~strcmpi(class(w),'waveform')
    error('Waveform:taper:missingWaveform','First input must be a waveform object');
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
if strcmpi(style,'COSINE')
    if length(varargin)==1
        R = varargin{1};
    elseif length(varargin)==0
        R = 0.2;
    else
        error('Waveform:taper:invalidInputCount','Wrong number of inputs for cosine taper');
    end
    w = docosine(w,R);
    
% PLACEHOLDER FOR OTHER TYPES OF TAPERS
elseif strcmpi(style,'Gaussian')
    error('Waveform:taper:invalidTaperType','Gaussian taper is not yet implimented');
else
    error('Waveform:taper:invalidTaperType','This style of taper is not recognized.');
end;






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% APPLY COSINE TAPER TO WAVEFORMS
function w = docosine(w,R)


% SET THE SIZE OF R
if length(R)==1 && length(w)>1
    R = R * ones(size(w));
end;


% Since tukeywin and waveform/times are limited to one set of data at a
% time, it is not clear to me how to avoid a loop through all waveforms. -
% MEW
[N,M] = size(w);
for n = 1:N
    for m = 1:M
        newdata  = tukeywin( get(w(n,m),'DATA_LENGTH') , R(n,m) );
        cosine_taper = set( w(n,m) , 'DATA' , newdata );
        w(n,m) = w(n,m) .* cosine_taper;
    end
end




