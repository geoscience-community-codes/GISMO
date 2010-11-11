%THREECOMP Object for three component waveform data
% TC = THREECOMP(W) creates a vector of threecomp objects TC from waveform
% matrix W where W is of dimensions Nx3, and TC is Nx1. Each row of W must
% be a tuple of waveforms from different components of the same station.
% Acceptable component orientations are Z-N-E, Z-R-T, and Z-2-1.
% For example:
%        COLA_BHZ     COLA_BHN     COLA_BHE
%        AUNW_EHZ     AUNW_EHN     AUNW_EHE
%           "            "            "
%           "            "            "
%
% By meeting this and a few other conventions threecomp objects are
% amenable to standardized three component analyses. Additional
% requirements are that the traces in each threecomp object span the same
% time ranges with the same sample rates and units and contain no data
% gaps. THREECOMP checks for consistency of these fields. Where possible,
% times, sample rates, and gaps are adjusted to meet these requirements on
% the fly. By default, all traces are also detrended and demeaned.
%
% TC = THREECOMP(W,...,TRIGGER,...) fills the trigger property in each
% threecomp object. TRIGGER must be an Nx1 vector of Matlab numeric times
% between year 1900 and 2100. Users may choose to set the trigger to an
% origin time, an arrival time or any arbitrary time.  This can prove
% useful in later processing for aligning traces. The trigger may also be
% ignored entirely in which case it defaults to the start time of each
% threecomp object. Can be used with or without BACKAZIMUTH argument.
%
% TC = THREECOMP(W,...,BACKAZIMUTH,...) fills the backazimuth property in
% each threecomp object. BACKAZIMUTH must be an Nx1 vector of backazimuths
% indicating the direction from the station to the source. Backazimuths
% should be given in degrees between -360 and 360 where 0 is north. Can be
% used with or without TRIGGER argument.
%
% AUTOMATIC LOADING OF TRIGGER AND BACKAZIMUTH PROPERTIES TKTKTK
%
% HOW TO HANDLE INCONSISTENCIES IN INPUT WAVEFORMS
% 1x3 tuples in W that do not meet the minimum standards are not included in
% the threecomp vector TC. There are three ways to handle this:
% Option 1:
%    Clean up the input waveforms. THREECOMP attempts to provide verbose
%    descriptions of all trace inconsistencies.
% Option 2:
%    Use the SUCCESS function to get the mask of tuples which were
%    successfully converted to threecomp ojects.
%    TC = THREECOMP(W);
%    MASK = SUCCESS(TC);
%    where MASK is an Nx1 boolean vector of 0's and 1's which can be used
%    at a code level to track the success of the threecomp conversion.
% Option 3:
%    Use TC = THREECOMP(W,...,'NoVerify'); The NoVerify option forces each
%    tuple to be converted to a threecomp object without exception and
%    without checking for inconsistencies. This overrides all of the
%    safeguards in THREECOMP and may well cause unanticipated (and
%    non-intuitive) errors in subsequent codes. This not recommended for
%    typical use but may prove useful in debugging. If this approach is
%    used, it is strongly recommended to use the VERIFY function on the
%    resulting threecomp object.
%
% See also threecomp/describe, threecomp/verify, threecomp/success

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


classdef threecomp
    
    properties
        traces
        trigger
        backAzimuth
        orientation
        rectilinearity
        planarity
        energy
        azimuth
        inclination
    end
    
    
    methods
        function TC = threecomp(varargin)
            
            %% CHECK ARGUMENTS
            
            
            % CHECK WAVEFORM ARGUMENT
            if length(varargin)>=1
                W = varargin{1};
                if ~isa(W,'waveform') || size(W,2)~=3
                    error('Threecomp:threecomp:badWaveform','argument 1 must be an nx3 waveform object');
                end
            end
            
            
            % CHECK FOR NOVERIFY ARGUMENT
            DOVERIFY = 1;
            INTERNAL = 0;
            if length(varargin)>=2
                if ischar(varargin{end})
                    if strcmpi(varargin{end},'NOVERIFY')
                        DOVERIFY = 0;
                        varargin = varargin(1:end-1);
                    elseif strcmpi(varargin{end},'INTERNAL')
                        INTERNAL = 1;
                        DOVERIFY = 0;
                        varargin = varargin(1:end-1);
                    else
                        error('Threecomp:threecomp:badTextArgument','Text argument not recognized');
                    end
                end
            end
            
            
            % CHECK TRIGGER/BACKAZIMUTH/ORIENTATION ARGUMENTS
            triggerList = [];
            backAzimuthList = [];
            orientationList = [];
            if ~INTERNAL
                for n = 1:length(varargin)-1
                    vals = varargin{end};
                    if min(size(vals))==1      % turn vectors to Nx1
                        vals = reshape(vals,length(vals),1);
                    end
                    if isa(vals,'double') && size(vals,1)==size(W,1)
                        if size(vals,2)==6
                            orientationList = mod(vals,360);
                        elseif abs(vals)<=720
                            backAzimuthList = mod(vals,360);
                        elseif vals>datenum('1/1/1900') & vals<datenum('1/1/2100')
                            triggerList = vals;
                        else
                            error('Threecomp:threecomp:badArgumentValues','Argument not recognized as triggers or backazimuths.');
                        end
                    else
                        error('Threecomp:threecomp:badArgumentFormat','Argument not recognized or incorrect length.');
                    end
                    varargin = varargin(1:end-1);
                end
            end
            
            
            
            %% CREATE INITIAL THREECOMP OBJECT(S)
            if length(varargin)>=1
                dimensionOne = size(W,1);
                if dimensionOne > 1         % multiple waveform tuples
                    for n=1:dimensionOne
                        TC(n) = threecomp(W(n,:),'INTERNAL');
                    end
                    TC = reshape(TC,dimensionOne,1);
                elseif dimensionOne == 1    % single waveform tuple
                    TC.traces = reshape(W,1,3);
                end
            elseif nargin==0                % empty object
                TC.traces = [waveform waveform waveform];
                return
            end
            
            
            %% ADD PROPERTIES TO THREECOMP OBJECTS
            % TODO: does not handle waveform vectors with partial inclusion
            % of the following fields
            
            if ~INTERNAL
                
                % TRIGGERS
                if isempty(triggerList)
                    if all(isfield(W(:,1),'TRIG'))
                        triggerList = get(W(:,1),'TRIG');
                    elseif all(isfield(W(:,1),'TRIGGER'))
                        triggerList = get(W(:,1),'TRIGGER');
                    else
                        triggerList = get(W(:,1),'START');
                    end
                end
                for n = 1:length(TC)
                    TC(n).trigger = triggerList(n);
                end
                
                % BACKAZIMUTH
                if isempty(backAzimuthList)
                    if all(isfield(W(:,1),'BACKAZIMUTH'))
                        disp('Setting backAzimuth according to user field BACKAZIMUTH.');
                        backAzimuthList = get(W(:,1),'BACKAZIMUTH');
                    elseif all(isfield(W(:,1),'BAZ'))
                        disp('Setting backAzimuth according to SAC field BAZ.');
                        backAzimuthList = get(W(:,1),'BAZ');
                    end
                end
                for n = 1:length(TC)
                    if ~isempty(backAzimuthList)
                        TC(n).backAzimuth = backAzimuthList(n);
                    end
                end
                
                % CHANNELS ORIENTATIONS
                % check first for custom field definitions, then css3.0
                % orientations, then SAC header orientations
                if isempty(orientationList)
                    if all(all(isfield(W,'HorizontalOrientation'))) && all(all(isfield(W,'VerticalOrientation')))
                        disp('Component orientations are being set according to user fields HorizontalOrientation and VerticalOrientation.');
                        orientationList(:,1) = get(W(:,1),'HorizontalOrientation');
                        orientationList(:,2) = get(W(:,1),'VerticalOrientation');
                        orientationList(:,3) = get(W(:,2),'HorizontalOrientation');
                        orientationList(:,4) = get(W(:,2),'VerticalOrientation');
                        orientationList(:,5) = get(W(:,3),'HorizontalOrientation');
                        orientationList(:,6) = get(W(:,3),'VerticalOrientation');
                    elseif all(all(isfield(W,'HANG'))) && all(all(isfield(W,'VANG')))
                        disp('Component orientations are being set according to css3.0 fields HANG and VANG.');
                        orientationList(:,1) = get(W(:,1),'HANG');
                        orientationList(:,2) = get(W(:,1),'VANG');
                        orientationList(:,3) = get(W(:,2),'HANG');
                        orientationList(:,4) = get(W(:,2),'VANG');
                        orientationList(:,5) = get(W(:,3),'HANG');
                        orientationList(:,6) = get(W(:,3),'VANG');
                    elseif all(all(isfield(W,'CMPAZ'))) && all(all(isfield(W,'CMPINC')))
                        disp('Component orientations are being set according to SAC fields CMPAZ and CMPINC.');
                        disp('Vertical orientation set to 180-CMPINC. See DESCRIBE(THREECOMP) for conventions.');
                        orientationList(:,1) = get(W(:,1),'CMPAZ');
                        orientationList(:,2) = 180 - get(W(:,1),'CMPINC');
                        orientationList(:,3) = get(W(:,2),'CMPAZ');
                        orientationList(:,4) = 180 - get(W(:,2),'CMPINC');
                        orientationList(:,5) = get(W(:,3),'CMPAZ');
                        orientationList(:,6) = 180 - get(W(:,3),'CMPINC');
                        
                    end
                end
                for n = 1:length(TC)
                    if ~isempty(orientationList)
                        TC(n).orientation = orientationList(n,:);
                    else
                        type = get(TC(n),'TYPE');
                        disp('Component orientations inferred from channel names.');
                        if strcmpi(type,'ZNE')
                            TC(n).orientation = [0 0 0 90 90 90];
                        elseif strcmpi(type,'ZRT') && ~isempty(TC(n).backAzimuth)
                            TC(n).orientation = [0 0 0 mod(TC(n).backAzimuth,360) 0 mod(TC(n).backAzimuth+90,360)];   % TODO: STILL NEED TO DEFINE
                        end
                    end
                end
                if any(any(isnan(get(TC,'orientation'))))
                    disp('One or more component orientations are not set. Some functionality will be lost.');
                else
                end
            end
            
            
            
            %% VERIFY AND ADJUST
            if DOVERIFY
                TC = align(TC);
                conflicts = verify(TC);
                successMask = find(strcmp(conflicts,'0000000'));
                TC = TC(successMask);
                if isempty(threecomp)
                    return
                end
                addfield(TC(1).traces(1),'TMP_SUCCESSMASK',successMask);
                addfield(TC(1).traces(1),'TMP_CONFLICTS',conflicts);
                for n=1:length(TC)
                    TC(n).traces = detrend(TC(n).traces);
                    TC(n).traces = demean(TC(n).traces);
                end
            end
        end
    end
    
end