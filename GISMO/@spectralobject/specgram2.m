function specgram2(s, ws, varargin)
%SPECGRAM2 - plots spectrogram of waveforms with waveform along top
%
%      USAGE: specgram2(spectralobject, waveform, [parametername,parameterval],...,'axis',ax);
% 
%      NOTE, usage has changed 11/27/2008.
%      to clear the figure, use specgram2(spectralobject,waveform)
%      to specify an axis, use specgram2(spectralobject,waveform,'axis',gca)
%         --- instead of gca, you could pass any axis handle  
%      What works best is to set your current axis BEFORE using specgram2.
% 
%      if you want to plot over the same axis, first define your axis, then
%      use a command like axish = get(gca,'position') to keep track of where
%      you are... then you can set your current axis back to axis(axish) 
%      before calling specgram2.
%   
%      A specific position can be specified with the parameter pair
%      'position',[left,bottom,width,height]
% 
%      Default values are NYQ = 50, nfft = 256, over = nfft/2 and 
%      freqmax = NYQ.  If you prefer not to input the specific dB limits,
%      it will scale for you.  
% 
%      Can either specify 'axis', or 'position'
%      with 'axis', pass it an axis handle. 
%      with 'position', pass it [left,bottom,width,height]
%
%      The colormap I use is "spectral.map", but can be changed with SETMAP.  
% 
%
%   See also SPECTRALOBJECT/SPECGRAM

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



%enforce input arguments.
if ~isa(ws,'waveform')
    error('Spectralobject:specgram2:invalidArgument',...
        'Second input argument should be a waveform, not a %s',class(ws));
end

if numel(ws) > 1
    error('Spectralobject:specgram2:tooManyWaveforms',...
        'specgram2 can only be used with individual waveforms, but was handed a waveform with %d elements. Either use SPECGRAM, or loop thorugh waveforms.',numel(ws));
end

hasExtraArg = mod(numel(varargin),2);
if hasExtraArg
  error('Spectralobject:DepricatedArgument',...
    ['spectralobject/specgram2 now requires parameter ',...
    'pairs.  Most likely, you tried to call spectrogram with an ',...
    'axis without specifying the property ''axis''',...
     ' See help spectralobject/specgram for new usage instructions.']);
else
  proplist=  parseargs(varargin);
end

[isfound,myaxis,proplist] = getproperty('axis',proplist,0);
[isfound,mypos,proplist] = getproperty('position',proplist,[]);

[isfound,colorbarpref,proplist] = getproperty('colorbar',proplist,'horiz');


%find out area we've got to work in
left=1; bottom=2; width=3; height=4;
clabel= 'Relative Amplitude  (dB)'; 

if myaxis == 0, 
            clf;
            pos = get(gca,'position');
        else  
            pos = get(myaxis,'position');
        end
    if ~isempty(mypos) %position
        pos = myaxis;
    end
    
wavepos = [ pos(left), pos(bottom)+pos(height)*0.85,  pos(width) , pos(height) * 0.15] ;
specpos = [ pos(left), pos(bottom), pos(width), pos(height) * 0.85 ];
subplot('position',wavepos);
plot(ws,'xunit',s.scaling,'autoscale',true);
set(gca,'fontsize',8);
axis tight;
subplot('position',specpos);
specgram(s,ws,varargin{:});
title('');
if ~strcmpi(colorbarpref,'none')
  colorbar_axis(s,colorbarpref,clabel)	 
end

%%
function [properties] = parseargs(arglist)
% parse the incoming arguments, returning a cell with each parameter name
% as well as a cell for each parameter value pair.  parseargs will also
% doublecheck to ensure that all pnames are actually strings... otherwise,
% we're looking at a mis-parse.
%check to make sure these are name-value pairs
argcount = numel(arglist);
evenArgumentCount = mod(argcount,2) == 0;
if ~evenArgumentCount
  error('ParseArgs:propertyMismatch',...
    'Odd number of arguments means that these arguments cannot be parameter name-value pairs');
end

%assign these to output variables
properties.name = arglist(1:2:argcount);
properties.val = arglist(2:2:argcount);

%
for i=1:numel(properties.name)
  if ~isa(properties.name{i},'char')
    error('ParseArgs:invalidPropertyName',...
      'All property names must be strings.');
  end
end

function [isfound, foundvalue, properties] = getproperty(desiredproperty,properties,defaultvalue)
%returns a property value (if found) from a property list, removing that
%property pair from the list.  only removes the first encountered property
%name.

pmask = strcmpi(desiredproperty,properties.name);
isfound = any(pmask);
if isfound
  foundlist = find(pmask);
  foundidx = foundlist(1);
  foundvalue = properties.val{foundidx};
  properties.name(foundidx) = [];
  properties.val(foundidx) = [];
else
  if exist('defaultvalue','var')
    foundvalue = defaultvalue;
  else
    foundvalue = [];
  end
  % do nothing to properties...
end

function c = property2varargin(properties)
c = {};
c(1:2:numel(properties.name)*2) = properties.name;
c(2:2:numel(properties.name)*2) = properties.val;