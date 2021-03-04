function erobj=eventrate(catalogObject, varargin)
    %CATALOG.EVENTRATE    
    % Create an EventRate object from an Catalog object
    % object, with a binsize determined automatically.
    %   erobj = catalogObject.eventrate()
    %
    % Specify a binsize (in days):
    %   erobj = catalogObject.eventrate('binsize', 1/24)
    %
    % Specify a stepsize (in days). Must be <= stepsize.
    %   erobj = catalogObject.eventrate(..., 'stepsize',1/24) 

    p = inputParser;
    p.addParamValue('binsize', 0, @isnumeric);
    p.addParamValue('stepsize', 0, @isnumeric);
    p.addParamValue('snum', 0, @isnumeric);
    p.addParamValue('enum', 0, @isnumeric);
    p.parse(varargin{:});
    binsize = p.Results.binsize;
    stepsize = p.Results.stepsize;
    snum = p.Results.snum;
    enum = p.Results.enum;
    if snum>0 && enum>0 % subsetting the catalog object for date range?
        for c=1:numel(catalogObject)
            indices = find(catalogObject(c).otime >= snum & catalogObject(c).otime <= enum);
            catalogObject(c) = catalogObject(c).subset(indices);
        end
    end
    
        

    for i=1:numel(catalogObject)
        if catalogObject(i).numberOfEvents > 0

            try
                snum = catalogObject(i).request.startTime;
                enum = catalogObject(i).request.endTime;
            catch
               timerange = catalogObject(i).gettimerange();
               snum=timerange(1);
               enum=timerange(2);                
            end
           
            if ~(binsize>0)
                binsize = Catalog.binning.autobinsize(enum-snum);
            end
            if ~(stepsize>0)
                stepsize = binsize;
            end          
            if (stepsize > binsize)
               disp(sprintf('Invalid value for stepsize (%f days). Cannot be greater than binsize (%f days).',stepsize, binsize));
               return;
            end 

            % Find out how many event types we have
            etypes = unique(catalogObject(i).etype); 

            % bin the data 
            % SCAFFOLD - THIS NO LONGER SEEMS TO BE BINNING DATA
            % GET EMPTY OUTPUT WHEN TESTING WITH SEISAN_CATALOG
            [time, counts, energy, smallest_energy, ...
                biggest_energy, median_energy, stdev, median_time_interval] = ...
                Catalog.binning.bin_irregular(catalogObject(i).otime, ...
                magnitude.mag2eng(catalogObject(i).mag), ...
                binsize, snum, enum, stepsize);

            % create the Event Rate object
            total_counts = length(catalogObject(i).otime);
            numbins = numel(time);
            erobj(i) = EventRate(time, counts, energy, median_energy, ...
                smallest_energy, biggest_energy, median_time_interval, total_counts, ...
                snum, enum, etypes, binsize, stepsize, numbins);
        end
    end
end

%% AUTOBINSIZE        
function binsize = autobinsize(catalogObject)
%autobinsize Compute the best bin size based on start and end times
    binsize = binning.autobinsize(catalogObject.enum - catalogObject.snum);
end