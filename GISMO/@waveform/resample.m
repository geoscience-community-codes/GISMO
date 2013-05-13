function w = resample(w,method, val)
%RESAMPLE resamples a waveform at over every specified interval
%   w = resample(waveform, method, crunchfactor)
%
%   Input Arguments
%       WAVEFORM: waveform object       N-dimensional
%
%       METHOD: which method of sampling to perform within each sample
%                window
%           'max' : maximum value
%           'min' : minimum value
%           'mean': average value
%           'median' : mean value
%           'rms' : rms value (added 2011/06/01)
%           'absmax': absolute maximum value (greatest deviation from zero)
%           'absmin': absolute minimum value (smallest deviation from zero)
%           'absmean' : mean deviation from zero (added 2011/06/01)
%           'absmedian' : median deviation from zero (added 2011/06/01)
%           'builtin': Use MATLAB's built in resample routine
%
%       CRUNCHFACTOR : the number of samples making up the sample window
%
% For example, resample(w,'max',5) would grab the max value of every 5
% samples and return that in a waveform of adjusted frequency.  as a
% result, the waveform will have 1/5 of the samples
%
%
% To use matlab's built-in RESAMPLE method...
%       % assume W is an existing waveform
%       D = double(W);
%       ResampleD = resample(D,P,Q);  % see matlab's RESAMPLE for specifics
%
%       %put back into waveform, but don't forget to update the frequency
%       W = set(W,'data',ResampleD, 'Freq', NewFrequency); 
%
%       % and for good measure... update the waveform's history
%       W = addHistory('Resampled data outside of waveform object');
%
%
% See also RESAMPLE, MIN, MAX, MEAN, MEDIAN.

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/15/2009
% 
% 7/6/2011: Glenn Thompson: Made all methods NaN tolerant (replace max with nanmax etc) - checks for statistics toolbox
% 6/1/2011: Glenn Thompson: Added methods for ABSMEAN, ABSMEDIAN and RMS
persistent STATS_INSTALLED;

if isempty(STATS_INSTALLED)
  STATS_INSTALLED = ~isempty(ver('stats'));
end

if ~(round(val) == val) 
    disp ('val needs to be an integer');
    return;
end;

for i=1:numel(w)
    rowcount = ceil(length(w(i).data) / val);
    maxcount = rowcount * val;
    if length(w(i).data) < maxcount
        w(i).data(end+1:maxcount) = mean(w(i).data((rowcount-1)*maxcount : end)); %pad it with the avg value 
    end;
    
    d = reshape(w(i).data,val,rowcount); % produces ( val x rowcount) matrix
    switch upper(method)
        
    	case 'MAX'
		if STATS_INSTALLED
            		w(i) = set(w(i),'data', nanmax(d, [], 1));
		else
            		w(i) = set(w(i),'data', max(d, [], 1));
		end
            
       	case 'MIN'
		if STATS_INSTALLED
            		w(i) = set(w(i),'data', nanmin(d, [], 1));
		else
            		w(i) = set(w(i),'data', min(d, [], 1));
		end
            
        case 'MEAN'
		if STATS_INSTALLED
            		w(i) = set(w(i),'data', nanmean(d, 1));
		else
            		w(i) = set(w(i),'data', mean(d, 1));
		end
            
        case 'MEDIAN'
		if STATS_INSTALLED
            		w(i) = set(w(i),'data', nanmedian(d, 1));
		else
            		w(i) = set(w(i),'data', median(d, 1));
		end

        case 'RMS'
		if STATS_INSTALLED
            		w(i) = set(w(i),'data', nanstd(d, [], 1));
		else
            		w(i) = set(w(i),'data', std(d, [], 1));
		end
                       
        case 'ABSMAX'
		if STATS_INSTALLED
            		w(i) = set(w(i),'data', nanmax(abs(d),[],1));
		else
            		w(i) = set(w(i),'data', max(abs(d),[],1));
		end

            
        case 'ABSMIN'
		if STATS_INSTALLED
            		w(i) = set(w(i),'data', nanmin(abs(d),[],1));
		else	
            		w(i) = set(w(i),'data', min(abs(d),[],1));
		end
          
        case 'ABSMEAN'
		if STATS_INSTALLED
            		w(i) = set(w(i),'data', nanmean(abs(d), 1));
		else
            		w(i) = set(w(i),'data', mean(abs(d), 1));
		end
            
        case 'ABSMEDIAN'
		if STATS_INSTALLED
            		w(i) = set(w(i),'data', nanmedian(abs(d), 1));
            	else
			w(i) = set(w(i),'data', median(abs(d), 1));
		end

        case 'BUILTIN'
            
      	% assume W is an existing waveform
      ResampleD = resample(w(i).data,1,val);  % see matlab's RESAMPLE for specifics

      %put back into waveform, but don't forget to update the frequency
      w(i).data = ResampleD(:);
      w(i) = set(w(i), 'Freq', get(w(i),'freq') ./ val); 
        otherwise
            error('Wafeform:resample:UnknownSampleMethod',...
              'Don''t know what you mean by resample via %s', method);
            
    end;
    
    %adjust the frequency
    w(i) = set(w(i),'Freq', get(w(i),'Freq') ./ val);
    
end;
w = addhistory(w,['Resampled as ', method, ': ', num2str(val)]);
