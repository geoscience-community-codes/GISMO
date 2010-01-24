function w = reducedisp_calc(w,dist,varargin)

% WAVEFORM = REDUCEDISP(WAVEFORM,DISTANCE) This function calculates the
% reduced displacement of a waveform. If not specified, the body wave
% algorithm is used. In most cases the input waveform should be
% pre-filtered to the desired frequency band. This function requires that
% the waveform be a velocity record with units of nm/s. The distance to the
% presumed source, DISTANCE, must be in kilometers. If w is a vector, D
% will be returned as a vector of the same size. Units are cm^2. 
%
% WAVEFORM = REDUCEDISP(WAVEFORM,DISTANCE,ALGORITHM) where ALGORITHM can 
% be specified as either 'BODY' or 'SURF' to impliment the body wave or 
% surface wave formulation.

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks



if numel(varargin) > 1
   error('Too many input parameters');
end;

if numel(varargin) == 1
    if strcmpi(varargin{1},'SURF') || strcmpi(varargin{1},'BODY')
        algorithm = upper(varargin{1});
    else
        error('TYPE must be BODY or SURF');
    end
else
    algorithm = 'BODY';
    
end
    
    
% ENSURE UNITS ARE VELOCITY
units = upper(get(w(1),'UNITS'));
if isempty(strfind(units,'NM')) || isempty(strfind(units,'SEC')) || ~isempty(strfind(units,'2'))
	error('Waveform must have units of nm/sec');
    %warning('Units not verified. Assumging nm/sec');
end
if ~strcmpi( get(w,'CALIBRATION_APPLIED') , 'YES' );
	error('Calibration has not been applied to waveform');
end


% SET THE SIZE OF DIST
if length(dist)==1 && length(w)>1
    dist = dist * ones(size(w));
end;



% GET REDUCED DISPLACEMENT
% NOTE: original body wave formula (early 2007) was 
% D = rms(integrate(demean(w))) .* dist * 0.0001;
% This algorithm included the conversion
% "0.0001 converts nm*km to cm^2"
% *BUT* during this time period waveform had an error that did not factor
% frequency into integration. This resulted in another factor of 100, thus
% compensating for this mistake. Freak, but true.

if strcmp(algorithm,'BODY')
    D = rms(integrate(1e-7.*demean(w))) .* (1e5*dist);
    for i = 1:length(w)
        w(i) = addfield(w(i),'reducedisp',D(i));
    end
elseif strcmp(algorithm,'SURF')
    % TODO: Remove hard coded wavelength 
    % lambda based on 5 km/s velocity and freq. = 3 Hz
    lambda = 1.67; % in km
    D = rms(integrate(1e-7*demean(w))) .* sqrt( (1e5*dist)*(1e5*lambda) );
    for i = 1:length(w)
        w(i) = addfield(w(i),'reducedisp',D(i));
    end
else
    error('algorithm not recognized');
end




