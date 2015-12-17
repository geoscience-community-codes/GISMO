function self = despike(self, spiketype, maxRatio)
    % rsam.despike Despike a rsam object by comparing ratios of
    % concurrent samples. Checks for spikes lasting 1 or 2 samples.
    %   rsamdespiked = rsamobject.despike(spiketype, maxRatio)

    %   Example 1: Remove spikes which are at least 10 times
    %   adjacent samples. Store these in s.spikes.
    %        s = s.despike('spikes', 10)
    %
    %   Example 2: Remove spikes which are at least 3 times
    %   adjacent samples. Store these in s.events.
    %        s = s.despike('events', 3)            
    %
    %   Inputs: 
    %       maxRatio - Maximum ratio that defines "normal" data
    %                       compared to surrounding samples
    %   Outputs:
    %       s = rsam object with spikes removed

    % find spikes lasting 1 sample only
    y= self.data;
    spikeNumber = 0;
    for i=2:length(self.data)-1
        if self.data(i)>maxRatio*self.data(i-1)
            if self.data(i)>maxRatio*self.data(i+1)
                %sample i is an outlier
                y(i) = mean([self.data(i-1) self.data(i+1)]);
                spikeNumber = spikeNumber + 1;
                %spikes(spikeNumber) = spike(self.dnum(i), self.data(i) - y(i), y(i), '');
                spikes(spikeNumber) = rsam('dnum', self.dnum(i), 'data', self.data(i) - y(i),  'sta', self.sta, 'chan', self.chan, 'seismogram_type', self.seismogram_type, 'units', self.units, 'measure', self.measure);
                disp(sprintf('%s: sample %d, time %s, before %f, this %f, after %f. Replacing with %f',upper(spiketype),i, datestr(self.dnum(i)), self.data(i-1), self.data(i), self.data(i+1), y(i)));
            end
        end
    end

    % find spikes lasting 2 samples
    for i=2:length(self.data)-2
        if self.data(i)>maxRatio*self.data(i-1) & self.data(i+1)>maxRatio*self.data(i-1)
            if self.data(i)>maxRatio*self.data(i+2) & self.data(i+1)>maxRatio*self.data(i+2) 
                %samples i & i+1 are outliers
                y(i:i+1) = mean([self.data(i-1) self.data(i+2)]);
                spikeNumber = spikeNumber + 1;
                % spikes(spikeNumber) = spike( ...
                %     self.dnum(i:i+1), ...
                %     self.data(i:i+1) - y(i:i+1), ...
                %     y(i:i+1), '' );
                spikes(spikeNumber) = rsam('dnum', self.dnum(i:i+1), 'data', self.data(i:i+1) - y(i:i+1),  'sta', self.sta, 'chan', self.chan, 'seismogram_type', self.seismogram_type, 'units', self.units, 'measure', self.measure);
                disp(sprintf('%s: sample %d, time %s, before %f, these %f %f, after %f. Replacing with %f',upper(spiketype), i, datestr(self.dnum(i)), self.data(i-1), self.data(i), self.data(i+1), self.data(i+2), y(i)));
            end
        end
    end

    % find spikes lasting 3 samples - could be a short as 62
    % seconds
    if exist('spikes', 'var')
        if ~strcmp(spiketype, 'spikes') % only makes sense for events - an actual telemetry spike will be 1 or 2 samples long only (a few seconds)
            for i=2:length(self.data)-3
                if self.data(i)>maxRatio*self.data(i-1) & self.data(i+1)>maxRatio*self.data(i-1) & self.data(i+2)>maxRatio*self.data(i-1) 
                    if self.data(i)>maxRatio*self.data(i+3) & self.data(i+1)>maxRatio*self.data(i+3) & self.data(i+2)>maxRatio*self.data(i+3)
                        %samples i & i+1 are outliers
                        y(i:i+2) = mean([self.data(i-1) self.data(i+3)]);
                        spikeNumber = spikeNumber + 1;
                        % spikes(spikeNumber) = spike( ...
                        %     self.dnum(i:i+1), ...
                        %     self.data(i:i+1) - y(i:i+1), ...
                        %     y(i:i+1), '' );
                        spikes(spikeNumber) = rsam('dnum', self.dnum(i:i+2), 'data', self.data(i:i+2) - y(i:i+2), 'sta', self.sta, 'chan', self.chan, 'seismogram_type', self.seismogram_type, 'units', self.units, 'measure', self.measure);
                        disp(sprintf('%s: sample %d, time %s, before %f, these %f %f %f, after %f. Replacing with %f',upper(spiketype), i, datestr(self.dnum(i)), self.data(i-1), self.data(i), self.data(i+1), self.data(i+2), self.data(i+3), y(i)));
                    end
                end
            end            
        end
    end

    self.data = y; 
    if exist('spikes', 'var')
        if strcmp(spiketype, 'spikes')
            self.spikes = spikes;
        else
            self.transientEvents = spikes;
        end
    end
end