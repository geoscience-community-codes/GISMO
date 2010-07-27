function wNew = response_apply(w,filterObj,sourceType,source)

%RESPONSE_APPLY Deconvolve an instrument response from a waveform object.
% W = RESPONSE_APPLY(W,FILTEROBJ,SOURCETYPE,SOURCE) applies an instrument 
% response to waveform W, filtered on the filter range specified by
% filterobject FILTEROBJ. The response is read from SOURCE which is of type
% SOURCETYPE. SOURCETYPE can be:
%   polezero:  A polezero structure. See HELP RESPONSE_GET_FROM_POLEZERO
%   antelope:  An Antelope database. See HELP RESPONSE_GET_FROM_DB
%  structure:  A response structure. See HELP RESPONSE_GET_FROM_DB
%
%  Example uses
%     w = response_apply(w,filterObj,'polezero',polezero)
%     w = response_apply(w,filterObj,'antelope',dbName)
%     w = response_apply(w,filterObj,'structure',response)
%
%
% see also response_get_from_db, response_get_from_polezero

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
%         (borrowing liberally from codes written by M. Haney)
% $Date:  $
% $Revision: $


% CHECK INPUTS
if ~ischar(sourceType) || size(sourceType,1)~=1
    error('SOURCETYPE must be the same for all waveforms');
end
if strncmpi(sourceType,'antelope',3) && size(sourceType,1)~=1
    error('All responses must be sourced from a single database');
end


% PREPARE INDIVIDUAL WAVEFORMS

filterObj = repmat(filterObj,size(w));
source = repmat({source},size(w));
for n = 1:numel(w)
    wNew(n) = response_apply_one(w(n),filterObj(n),sourceType,source(n));
end

wNew = reshape(wNew,size(w));




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PROCESS INDIVIDUAL WAVEFORMS

function w = response_apply_one(w,filterObj,sourceType,source)


if numel(w)~=1
    error('Only one waveform should be passed to this subroutine.');
end


% % CHECK THE SOURCE OF THE RESPONSE
% if isa(source,'char')                 % antelope db
%     disp(['Attempting to retreive response information from database: ' source ' ...']);
% elseif  isa(source,'struct')          % polezero structure
%     disp('Using explicit poles/zeros ...');
% else
%     error('response source argument not recognized');
% end


% PREPARE VARIABLE SPACE
filterBand = get(filterObj,'CUTOFF');
period = get(w,'PERIOD');
nyquist = get(w,'NYQ');
rawData = double(w);
dataLength = numel(rawData);
rawData = reshape(rawData,1,dataLength);


% PREPARE TRACE DATA
% Create a zero padded Tukey taper
%    Taper size is determined by the high pass filter frequency
%    Tapered waveform is zeros padded on either end to triple the trace length
taperFullWidth = round(0.5/(filterBand(1)*period))*2; % guarantees an even number
taperAmp = hanning(taperFullWidth)';
taperAmp = [taperAmp(1:(taperFullWidth/2)) ones(1,(dataLength-taperFullWidth)) taperAmp(((taperFullWidth/2)+1):taperFullWidth)];
taperAmp = [ zeros(1,dataLength) taperAmp zeros(1,dataLength) ];
rawData = [ zeros(1,dataLength) rawData zeros(1,dataLength) ].*taperAmp;
dataLength = numel(rawData);


% CREATE FULL INVERSE RESPONSE VECTORS
% Seperate routines for even and odd trace length
% Full responses are reconstituted from positive only side
% ws and respInv are positive frequencies only
% wsFull and respInvFull have negative frequencies as well
if floor(dataLength/2) == ceil(dataLength/2)
    halfDataLength=dataLength/2;
    ws = 2*pi*[0:(halfDataLength)]*(1/(halfDataLength))*nyquist;
    [respInv,response] = prep_inverse_response(w,ws,sourceType,source);
    wsFull = [ -ws(halfDataLength+1:-1:2) ws(1:halfDataLength) ];
    respInvFull = ([ real(respInv(end:-1:2)) real(respInv(1:end-1)) ] + 1i*[ -imag(respInv(end:-1:2)) imag(respInv(1:end-1)) ]);
else
    halfDataLength = (dataLength+1)/2;
    ws = 2*pi * [0:(halfDataLength-1)] * (2/dataLength) * nyquist;
    [respInv,response] = prep_inverse_response(w,ws,sourceType,source);
    wsFull = [ -ws(end:-1:2) ws(1:end) ];
    respInvFull = ([ real(respInv(end:-1:2)) real(respInv(1:end)) ] + 1i*[ -imag(respInv(end:-1:2)) imag(respInv(1:end)) ]);
end

% APPLY THE RESPONSE
newData = real(ifft(ifftshift(fftshift(fft(rawData)).*(respInvFull))));


% BANDPASS FILTER THE DATA
[z q] = butter(get(filterObj,'POLES'),[(filterBand(1)/nyquist) (filterBand(2)/nyquist)]);
newData = filter(z,q,newData);
newData = filter(z,q,fliplr(newData));
newData = fliplr(newData);


% REMOVE TRACE PADDING
newData = newData( (dataLength/3)+1 : 2*(dataLength/3) );


% RETURN INSTURMENT CORRECTED WAVEFORM
w = set(w,'DATA',newData);
w = addhistory(w,'A frequency response was deconvolved using RESPONSE_APPLY. See RESPONSE field.');
w = addhistory(w,'Butterworth filter was doubly applied (FILTFILT). See FILTER field.');
w = addfield(w,'RESPONSE',response);
w = addfield(w,'FILTER',filterObj);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET UP THE INVERSE RESPONSE FUNCTIONS
% could facilitate calls to a different response loader

function [respInv,response] = prep_inverse_response(w,ws,sourceType,source)

switch lower(sourceType)
    
    case {'antelope'}
        sta = get(w,'STATION');
        chan = get(w,'CHANNEL');
        time = get(w,'START_MATLAB');
        response = response_get_from_db(sta,chan,time,(ws/(2*pi)),source);
        respInv = 1./response.values;
        respInv(1) = 0;
        respInv = reshape(respInv,1,numel(respInv));
        
    case {'polezero'}
        response = response_get_from_polezero(ws,source);
        respInv = 1./response.values;
        respInv(1) = 0;
        respInv = reshape(respInv,1,numel(respInv));
        
    case {'structure'}
        disp('Structure is not yet implemented')
    otherwise
        error('response source argument not recognized');
        
end











