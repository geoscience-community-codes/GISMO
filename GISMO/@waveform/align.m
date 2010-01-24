function w = align(w,alignTime, alignFreq)
%ALIGN resamples a waveform at over every specified interval
%   w = align(waveform, AlignTime, AlignFrequency)
%
%   Input Arguments
%       WAVEFORM: waveform object       N-dimensional
%       ALIGNTIME: either a single matlab time or N times 
%          where N is the number of waveforms
%
%   Output
%       The output waveform has the new frequency alignFreq and a
%       starttime calculated by PCHIP method, using matlab's INTERP1
%       function.
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

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/14/2009

oneSecond = datenum('0/0/0 00:00:01.00');
if isa(alignTime,'char'),
    alignTime =  datenum(alignTime);
end

if isscalar(alignTime) %use same align time for all waveforms
    alignTime = repmat(alignTime,size(w));
elseif numel(alignTime) ~= numel(w) %make sure 1:1 ratio for alignTime & waveform
    error('Waveform:align:invalidAlignCount','either have a single alignTime, or one for each waveform');
end

for n=1:numel(w)
    myAlign = datenum(alignTime(n));
    
    y = get(w(n),'data');
    x = get(w(n),'timevector');
    
    dayBase = fix(x(1)); %get the day.
    
    % I subtract the dayBase from the time data so that we're not so far
    % away from zero.  Later, I add it back in before putting it back into
    % the waveform
    
    x = x - dayBase;
    myAlign = myAlign - dayBase;
    
    alignPeriod = 1 ./ alignFreq ;
    
    timeStep = alignPeriod * oneSecond;
    
    %determine sample times at new frequency
    xi = x(1)-(timeStep): timeStep :x(end)+timeStep;
    %display(['numel(xi): ',num2str(numel(xi))]);
    
    [DeltaTime closestIdx] = min(abs(myAlign - xi));
    DeltaTime = xi(closestIdx) - myAlign;
       
    %following line changed from + to - according to Mike W. 4/4/2007
    xi = xi - DeltaTime; %time shift the times to make good alignment
    
    xi = xi(xi >= min(x) & xi <= max(x)); %only return those that are bounded
    
    %display(['numel(xi): ',num2str(numel(xi))]);
    
    yi = interp1(x,y,xi,'pchip');    %could be linear
    
    %display(['numel(yi): ',num2str(numel(yi))]);
    
    w(n) = set(w(n),'data',yi,'freq',alignFreq,'start',xi(1)+dayBase);
    
    %fancy way to get properly formatted time
    timeStr = get(set(waveform,'start',myAlign+dayBase),'start_str');
    
    %adjust history
    myHistory = sprintf('aligned data to %s at %f', timeStr, alignFreq);
    w(n) = addhistory(w(n),myHistory);
end
