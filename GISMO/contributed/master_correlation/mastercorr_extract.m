function varargout = mastercorr_extract(W,varargin)

%MASTERCORR_EXTRACT extract matches to the master waveform
% [MATCH] = MASTERCORR_EXTRACT(W) reads waveform W and produces a
% structure MATCH which contains relevent information for each successful
% match with the master waveform snippet.This function is intended
% to follow MASTERCORR_SCAN. In order to function properly, the properties
% MASTERCORR_TRIG, MASTERCORR_CORR and masterCORR_SNIPPET must exist in W.
% See MASTERCORR_SCAN for description of these fields. MATCH is a
% structure containing fields:
%   trig (double)           : trigger times in Matlab data format
%   corrValue (double)      : peak correlation value (<=1.0) 
%   corrValueAdj (double)   : max. correlation of an adjacent peak
%   network (cell)          : network code
%   station (cell)          : station code    
%   channel (cell)          : channel code
%   location (cell)         : network code
%
% [MATCH,C] = MASTERCORR_EXTRACT(W) produces a correlation object containing
% segmented waveforms extracted from waveform W. 
%
% [MATCH,C] = MASTERCORR_EXTRACT(W,PRETRIG,POSTRIG) Same as above, however, the
% data window width and alignment is determined explicitly by the fields
% PRETRIG and POSTTRIG. These values are given in seconds relative to the
% trigger times in MASTERCORR_TRIG. If not specified, these values are
% inferred from the time fields in TRIGGER, START and END contained in
% MASTERCORR_SNIPPET.
%
% [MATCH,C] = MASTERCORR_EXTRACT(W,..,THRESHOLD) allows a minimum correlation
% threshold to be included. This is useful if only the highest quality
% waveforms need to be extracted fro ma more permissive scan of the data.
%
% *** NOTE ABOUT MULTIPLE WAVEFORMS ***
% This function is designed to accept NxM waveform matrices as input. The
% output is a single correlation object containing the segmented waveforms
% from each element of W. This is useful, for example, when W is a 24x1
% matrix of hourly waveforms. However, unexpected (or clever!) results may
% be produced when W is complicated by elements with different channels or
% master waveform snippets. For some uses it may prove wise to pass only
% selected elements of W to this function. For example:
% C = MASTERCORR_EXTRACT(W(1:5)) Note that it is also possible to produce
% massive correlation objects. Correlation objects exceeding 10,000
% waveforms have been successfully manipulated. As a rule however, be aware
% that downstream processing time goes up considerably as correlation
% objects climb grow to thousands of events.
%
% See also mastercorr_scan, mastercorr_plot_stats, correlation,
% waveform/addfield

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks



% CHECK INPUTS
if nargin>4
    error('Incorrect number of inputs');
end
if ~isa(W,'waveform')
    error('First argument must be a waveform object');
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXTRACT WAVEFORMS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% READ MASTERCORR FIELDS
T.trig = [];
T.corrValue = [];
T.corrValueAdj = [];
T.network = [];
T.station = [];
T.channel = [];
T.location = [];
if numel(W)>1
    for n=1:numel(W)
        T.trig = [T.trig ; get(W(n),'MASTERCORR_TRIG')];
        T.corrValue = [T.corrValue ; get(W(n),'MASTERCORR_CORR')];
        T.corrValueAdj = [T.corrValueAdj ; get(W(n),'MASTERCORR_ADJACENT_CORR')];
        trigLength = numel(get(W(n),'MASTERCORR_TRIG'));
        tmp = {get(W(n),'NETWORK')};   T.network = [T.network ; repmat(tmp,trigLength,1)];
        tmp = {get(W(n),'STATION')};   T.station = [T.station ; repmat(tmp,trigLength,1)];
        tmp = {get(W(n),'CHANNEL')};   T.channel = [T.channel ; repmat(tmp,trigLength,1)];
        tmp = {get(W(n),'LOCATION')};  T.location = [T.location ; repmat(tmp,trigLength,1)];
    end
else
    T.trig = get(W,'MASTERCORR_TRIG');
    T.corrValue = get(W,'MASTERCORR_CORR');
    T.corrValueAdj = get(W,'MASTERCORR_ADJACENT_CORR');
    tmp = {get(W,'NETWORK')};   T.network = tmp;
    tmp = {get(W,'STATION')};   T.station = tmp;
    tmp = {get(W,'CHANNEL')};   T.channel = tmp;
    tmp = {get(W,'LOCATION')};  T.location = tmp;
end

varargout{1} = T;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXTRACT WAVEFORMS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% SET THRESHOLD
if nargin==2 || nargin==4
    threshold = varargin{end};
else
    threshold = -1;
end
if threshold<-1 || threshold>1
    error('Correlation threshold must be between -1 and 1');
end


% SET TIME WINDOWS
if nargin==3 || nargin==4
    preTrig = varargin{1};
    postTrig = varargin{2};
    useTrigArgs = 1;
else
    preTrig = 0;
    postTrig = 0;
    useTrigArgs = 0;
end


if nargout==2
    
    disp('Extracting waveforms from:');
    allWaveforms = [];
    for n = 1:numel(W)
        
        % SET TIME WINDOWS
        Wsnippet = get(W(n),'MASTERCORR_SNIPPET');
        if ~useTrigArgs
            preTrig =  86400 * (get(Wsnippet,'START') - get(Wsnippet,'TRIGGER'));
            postTrig =  86400 * (get(Wsnippet,'END') - get(Wsnippet,'TRIGGER'));
        end
        disp([ '   ' get(W(n),'NETWORK') '_' get(W(n),'STATION') '_' get(W(n),'CHANNEL') '_' get(W(n),'LOCATION') '   ' get(W(n),'START_STR') ' through ' get(W(n),'END_STR') '   (pre/post trigger: ' num2str(preTrig) ', ' num2str(postTrig) 's)'])
        
        % GET SEGMENTED WAVEFORMS
        trig = get(W(n),'MASTERCORR_TRIG');
        if ~isempty(trig)
            corrValue = get(W(n),'MASTERCORR_CORR');
            f = find(corrValue>=threshold);
            trigList = trig(f);
            wList = extract(W(n),'TIME',trigList+preTrig/86400,trigList+postTrig/86400)';
            wList = delfield(wList,'MASTERCORR_CORR');
            wList = delfield(wList,'MASTERCORR_ADJACENT_CORR');
            wList = delfield(wList,'MASTERCORR_TRIG');
            wList = delfield(wList,'MASTERCORR_SNIPPET');
            if n==1
                allTriggers = trigList;
                allWaveforms = wList;
            else
                allTriggers = [allTriggers ; trigList];
                allWaveforms = [allWaveforms ; wList];
            end
        end
    end
    if numel(allWaveforms)==0
        varargout{2} = correlation;
    else
        varargout{2} = correlation(allWaveforms,allTriggers);
    end
end

