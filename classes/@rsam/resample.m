function self = resample(self,  numminutes, method)
%RESAMPLE resamples a rsam object at a sample interval of NUMMINUTES using
%METHOD
%   rsamobject2 = rsamobject.resample(NUMMINUTES, METHOD)
%   Input Arguments
%       rsamobject: rsam object       N-dimensional
%
%       NUMMINUTES:       downsample to this sample period
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
% Examples:
%   rsamobject.resample(10, 'max') downsample the data at
%       10 minute sample period, where each 10-minute sample is the max within that
%       10 minute time window

    persistent STATS_INSTALLED;

    if isempty(STATS_INSTALLED)
      STATS_INSTALLED = ~isempty(ver('stats'));
    end

    if ~(round(numminutes) == numminutes) 
        warning('numminutes must be an integer');
        return;
    end

    if ~exist('method','var')
        method = 'mean';
    end
    
    for i=1:numel(self)
        samplingIntervalMinutes = 1.0 / (60 * self(i).fsamp());
        crunchfactor = round(numminutes / samplingIntervalMinutes);



        if crunchfactor > 1
            debug.print_debug(3, sprintf('Changing sampling interval to %d', numminutes))

            rowcount = ceil(length(self(i).data) / crunchfactor);
            maxcount = rowcount * crunchfactor;
            if length(self(i).data) < maxcount
                self(i).dnum(end+1:maxcount) = mean(self(i).dnum((rowcount-1)*maxcount : end)); %pad it with the avg value
                self(i).data(end+1:maxcount) = mean(self(i).data((rowcount-1)*maxcount : end)); %pad it with the avg value 
            end
            d = reshape(self(i).data,crunchfactor,rowcount); % produces ( crunchfactor x rowcount) matrix
            t = reshape(self(i).dnum,crunchfactor,rowcount);
            self(i).dnum = mean(t, 1);
            switch upper(method)

                case 'MAX'
                    if STATS_INSTALLED
                                self(i).data = nanmax(d, [], 1);
                    else
                                self(i).data = max(d, [], 1);
                    end

                case 'MIN'
                    if STATS_INSTALLED
                                self(i).data = nanmin(d, [], 1);
                    else
                                self(i).data = min(d, [], 1);
                    end

                case 'MEAN'
                    if STATS_INSTALLED
                                self(i).data = nanmean(d, 1);
                    else
                                self(i).data = mean(d, 1);
                    end

                case 'MEDIAN'
                    if STATS_INSTALLED
                                self(i).data = nanmedian(d, 1);
                    else
                                self(i).data = median(d, 1);
                    end

                case 'RMS'
                    if STATS_INSTALLED
                                self(i).data = nanstd(d, [], 1);
                    else
                                self(i).data = std(d, [], 1);
                    end

                case 'ABSMAX'
                    if STATS_INSTALLED
                                self(i).data = nanmax(abs(d),[],1);
                    else
                                self(i).data = max(abs(d),[],1);
                    end


                case 'ABSMIN'
                    if STATS_INSTALLED
                                self(i).data = nanmin(abs(d),[],1);
                    else	
                                self(i).data = min(abs(d),[],1);
                    end

                case 'ABSMEAN'
                    if STATS_INSTALLED
                                self(i).data = nanmean(abs(d), 1);
                    else
                                self(i).data = mean(abs(d), 1);
                    end

                case 'ABSMEDIAN'
                    if STATS_INSTALLED
                                self(i).data = nanmedian(abs(d), 1);
                    else
                                self(i).data = median(abs(d), 1);
                    end 

                otherwise
                    error('rsam:resample:UnknownResampleMethod',...
                      'Don''t know what you mean by resample via %s', method);

            end
            self(i).measure = method;
            bad = isnan(self(i).dnum);
            self(i).dnum(bad) = [];
            self(i).data(bad) = [];
        end
    end  
end
