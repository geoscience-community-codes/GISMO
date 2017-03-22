function self = resample(self, varargin)
%RESAMPLE resamples a rsam object at over every specified intercrunchfactor
%   rsamobject2 = rsamobject.resample('method', method, 'factor', crunchfactor)
%  or
%   rsamobject2 = rsamobject.resample(method, 'minutes', minutes)
%
%   Input Arguments
%       rsamobject: rsam object       N-dimensional
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
%       FACTOR : the number of samples making up the sample window
%       MINUTES:       downsample to this sample period
%       (FACTOR will be calculated internally)
%
% Examples:
%   rsamobject.resample('method', 'mean')
%       Downsample the rsam object with an automatically determined
%           sampling period based on timeseries length.
%   rsamobject.resample('method', 'max', 'factor', 5) grab the max value of every 5
%       samples and return that in a waveform of adjusted frequency. The output
%       rsam object will have 1/5th of the samples, e.g. from 1
%       minute sampling to 5 minutes.
%   rsamobject.resample('method', 'max', 'minutes', 10) downsample the data at
%       10 minute sample period       


    persistent STATS_INSTALLED;

    if isempty(STATS_INSTALLED)
      STATS_INSTALLED = ~isempty(ver('stats'));
    end

    p = inputParser;
    p.addParameter('method',self.measure);
    p.addParameter('factor', 0); % crunchfactor
    p.addParameter('minutes', 0);

    p.parse(varargin{:});

    crunchfactor = p.Results.factor;
    method = p.Results.method;
    minutes = p.Results.minutes;

    if ~(round(crunchfactor) == crunchfactor) 
        disp ('crunchfactor needs to be an integer');
        return;
    end

    for i=1:numel(self)
        samplingIntervalMinutes = 1.0 / (60 * self(i).Fs());
        if crunchfactor==0 && minutes==0 % choose automatically
            choices = [1 2 5 10 30 60 120 240 360 ];
            days = max(self(i).dnum) - min(self(i).dnum);
            choice=max(find(days > choices));
            minutes=choices(choice);
        end

        if minutes > samplingIntervalMinutes
            crunchfactor = round(minutes / samplingIntervalMinutes);
        end

        if isempty(method)
            method = 'mean';
        end

        if crunchfactor > 1
            debug.print_debug(3, sprintf('Changing sampling interval to %d', minutes))

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
        end
    end  
end