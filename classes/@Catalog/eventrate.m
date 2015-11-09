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
    p.parse(varargin{:});
    binsize = p.Results.binsize;
    stepsize = p.Results.stepsize;

    for i=1:numel(catalogObject)

        if ~(binsize>0)
            binsize = Catalog.binning.autobinsize(catalogObject(i));
        end
        if ~(stepsize>0)
            stepsize = binsize;
        end      
        if (stepsize > binsize)
           disp(sprintf('Invalid value for stepsize (%f days). Cannot be greater than binsize (%f days).',stepsize, binsize));
           return;
        end          
        if ~(binsize>0)
            binsize = Catalog.binning.autobinsize(catalogObject(i).enum-catalogObject(i).snum);
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
        [time, counts, energy, smallest_energy, ...
            biggest_energy, median_energy, stdev, median_time_interval] = ...
            Catalog.binning.bin_irregular(catalogObject(i).datenum, ...
            magnitude.mag2eng(catalogObject(i).mag), ...
            binsize, catalogObject(i).snum, catalogObject(i).enum, stepsize);

        % create the Event Rate object
        total_counts = length(catalogObject(i).time);
        numbins = numel(time);
        erobj(i) = EventRate(time, counts, energy, median_energy, ...
            smallest_energy, biggest_energy, median_time_interval, total_counts, ...
            catalogObject(i).snum, catalogObject(i).enum, etypes, binsize, stepsize, numbins);
    end
end