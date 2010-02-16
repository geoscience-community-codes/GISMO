function w = align(w,alignTimes, alignFreq, alignMethod)
%ALIGN resamples a waveform at over every specified interval
%   w = align(waveform, AlignTime, AlignFrequency)
%
%   Input Arguments
%       WAVEFORM: waveform object       N-dimensional
%       ALIGNTIME: either a single matlab time or N times
%          where N is the number of waveforms
%       ALIGNFREQ: the frequency (Samples per Second) of the newly aligned
%          waveforms
%       ALIGNMETHOD: Any of the methods from function INTERP
%          If omitted, then the DEFAULT IS 'pchip'
%
%   Output
%       The output waveform has the new frequency alignFreq and a
%       starttime calculated by the specified method, using matlab's
%       INTERP1 function.
%
%   Examples of usefulness?  Particle motions, coordinate transformations.
%   If used for particle motions, consider MatLab's plotmatrix command.
%
%   example:
%       cmp = {'BHZ','BHN','BHE'}; %we'll want to grab all 3 components
%       for n=1:numel(cmp)
%           % for each component, grab winston data on Kurile Earthquake
%           w = waveform('KDAK',cmp(n),'1/13/2007 04:20:00',...
%               '1/13/2007 04:30:00', 'II',[],[],[]);
%       end;
%
%       w = align(w,'1/37/2007 4:22:00', get(w(1),'freq'));
%
%       %feed plotmatrix a matrix, whose columns are each component
%       plotmatrix(double(w));
%
%
% See also INTERP1, PLOTMATRIX

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


if ~exist('alignMethod','var')
    alignMethod = 'pchip';
end

oneSecond = datenum([0 0 0 0 0 1]);
if isa(alignTimes,'char'),
    alignTimes =  datenum(alignTimes);
end

hasSingleAlignTime = isscalar(alignTimes);

if hasSingleAlignTime %use same align time for all waveforms
    alignTimes = repmat(alignTimes,size(w));
elseif isvector(alignTimes) && isvector(w)
    if numel(alignTimes) ~= numel(w)
        error('Waveform:align:invalidAlignSize',...
            'The number of Align Times does not match the number of waveforms');
    else
        % this situation OK.
        % ignore possibility that we're comparing a 1xN vs Nx1.
    end
elseif~all(size(alignTimes) == size(w)) %make sure 1:1 ratio for alignTime & waveform
    if numel(alignTimes) == numel(w)
        error('Waveform:align:invalidAlignSize',...
            ['The alignTime matrix is of a different size than the waveform'...
            ' Matrix.  ']);
    end
end


newSamplesPerSec = 1 ./ alignFreq ;  %# samplesPerSecond
timeStep = newSamplesPerSec * oneSecond;
existingStarts = get(w,'start');
existingEnds = get(w,'end');
closestStartTime = offsetToNearestAlignedTime(existingStarts,alignTimes,timeStep);

for n=1:numel(w)    
    %disp(n)
    newSampleTimes = closestStartTime(n):timeStep:existingEnds(n);
  
    %get rid of samples that lay entirely outside the existing waveform's
    %range (ie, only interpolate values BETWEEN points)
    newSampleTimes = newSampleTimes(newSampleTimes >= existingStarts(n) & ...
        newSampleTimes <= existingEnds(n));
    
   % display(['numel(newSampleTimes): ',num2str(numel(newSampleTimes))]);
    
    w(n).data = interp1(...
        get(w(n),'timevector'),... original times (x)
        w(n).data,...              original data (y)
        newSampleTimes,...         new times (x1)
        alignMethod);           %  method
    w(n) = set(w(n),'start',newSampleTimes(1));    
    
end
w = set(w,'freq',alignFreq);

%% update histories
% if all waves were aligned to the same time, then handle all history here
if hasSingleAlignTime
    %fancy way to get properly formatted time
    timeStr = get(set(waveform,'start',alignTimes),'start_str');
    %adjust history
    myHistory = sprintf('aligned data to %s at %f', timeStr, alignFreq);
    w = addhistory(w,myHistory);
else
    for n=1:numel(w)
         %fancy way to get properly formatted time
        timeStr = get(set(waveform,'start',alignTimes(n)),'start_str');
        
        %adjust history
        myHistory = sprintf('aligned data to %s at %f', timeStr, alignFreq);
        w(n) = addhistory(w(n),myHistory);
    end
end


function closestTime = offsetToNearestAlignedTime(existingStarts, AlignTimes, matlabTimePerSample)
% calculate the offset of the closest "aligned" time, by projecting the
% desired frequency rate and time
deltaTime = existingStarts - AlignTimes;  % time in between
% (-):alignTimes AFTER existingStarts, (+) alignTimes BEFORE existingStarts
closestTime = existingStarts - rem(deltaTime,matlabTimePerSample);

