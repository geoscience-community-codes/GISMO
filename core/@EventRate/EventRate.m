classdef EventRate
%EventRate Event Rate class constructor.
% 
%    EventRate is a class that has been developed around plotting earthquake
%    counts - i.e. the rate of events per unit time. It has evolved to compute
%    other metrics such the hourly mean event rate, median event rate, mean 
%    magnitude and cumulative magnitude, which are important metrics for an AVO
%    swarm tracking system.
%
%    EventRate can import information from:
%    (1) a Catalog object. 
%    (2) a Datascope database written in the "swarms1.0" schema, defined at AVO. 
%        This is the format used by the swarm tracking system (Thompson &
%        West, 2010).
%
%    ER = EventRate(Catalog_OBJECT, 'binsize', BINSIZE) creates an eventrate object
%    from a Catalog object using non-overlapping bins of BINSIZE days. 
%
%    ER = EventRate(Catalog_OBJECT, 'binsize', BINSIZE, 'stepsize', STEPSIZE) creates an eventrate object
%    using overlapping bins. If omitted STEPSIZE==BINSIZE.
%
%%   EXAMPLES:
%
%       First create a catalog object from the demo database:
%           dbpath = demodb('avo')
%           catalogObject = readEvents('datascope', 'dbpath', dbpath, ...
%                  'dbeval', ...
%                  'deg2km(distance(lat, lon, 60.4853, -152.7431))<15.0' ...
%                  );
%
%       (1) Create an eventrate object using a binsize of 1 day:
%           erobj = catalogObject.eventrate('binsize', 1);
%
%       (2) Create an eventrate object using a binsize of 1 hour:
%           erobj = catalogObject.eventrate('binsize', 1/24);
%
%       (3) Create an eventrate object using a binsize of 1 hour but a stepsize of 5 minutes:
%           erobj = catalogObject.eventrate('binsize', 1/24, 'stepsize', 5/1440);
%
%%   PROPERTIES
%
%    For a list of all properties type properties(EventRate)
%
%    time                % (array) time of the center of each bin as a DATENUM
%
%    METRICS:
%        counts 		     % (array) number of events in each bin
%        mean_rate           % (array) number of events per hour in each bin
%        median_rate	     % (array) reciprocal of the median time interval between events. Represented as an hourly rate.
%        cum_mag		     % (array) total sum of energy in each bin, represented as a magnitude.
%        mean_mag		     % (array) mean magnitude of events in each bin 
%        median_mag          % (array) median magnitude of events in each bin
%        min_mag             % (array) smallest magnitude in each bin
%        max_mag             % (array) largest magnitude in each bin
%
%    SUMMARY DATA:
%        numbins             % (scalar) number of bins used for grouping
%                                events
%        total_counts        % (scalar) sum of counts
%        total_mag           % (scalar) total sum of energy of all catalogObjects, represented as a magnitude
%
%    METADATA:
%        etype               % event type/classification. 
%        snum                % (scalar) start date/time in DATENUM format
%        enum                % (scalar) end date/time in DATENUM format
%        binsize             % (scalar) bin size in days
%        stepsize            % (scalar) step size in days
%        region              % (4-element vector) [minlon maxlon minlat maxlat]
%        minmag              % (scalar) magnitudes smaller than this were eliminated
%        dbroot              % path to the original data on disk
%        archiveformat       % indicates if the source is a flat file, or
%                              'daily' or 'monthly' volumes
%        auth                % auth of the events
%
%%   METHODS
%
%    For a list of all methods type methods EventRate 
%
%
%%   See also Catalog, Catalog_lite
%
%% AUTHOR: Glenn Thompson

% $Date: 2014-05-06 14:52:40 -0800 (Tue, 06 May 2014) $
% $Revision: 404 $


% I don't think these parts work anymore
%       (4) Create a vector of eventrate objects subclassified using event types 'r', 'e', 'l', 'h', 't':
%               erobj = eventrate(catalogObject, 1, 'etypes', 'relht');
%           To plot counts on separate figures:
%               erobj.plot()
%           To plot counts and energy panels, each event type as a separate figure:
%               erobj.plot('metric', {'counts';'energy'});
%           To plot counts and energy panels on separate figures, each event type as panels:
%               erobj.plot('metric', {'counts';'energy'}, 'plotmode', 'panels'); 
%           To plot counts and energy panels on separate figures, each event type stacked:
%               erobj.plot('metric', {'counts';'energy'}, 'plotmode', 'stacked');
%
%       (5) A full example:
%               catalogObject = catalog(fullfile(MVO_DATA, 'mbwh_catalog'), 'seisan', 'snum', datenum(1996,10,1), 'enum', datenum(2004,3,1), 'region', 'Montserrat')
%               erobj = eventrate(catalogObject, 365/12, 'stepsize', 1, 'etypes', 'thlr');
%               erobj.plot('metric', {'counts';'energy'}, 'plotmode', 'stacked');
%

%% PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties(GetAccess = 'public', SetAccess = 'public')
        time = [];          % (array) in datenum format
        counts = []; 		% (array) number of events in each bin
		mean_rate = [];      % (array) number of events per hour in each bin
		median_rate = [];	% (array) reciprocal of the median time interval between events. Represented as an hourly rate.
		cum_mag = [];		% (array) total sum of energy in each bin, represented as a magnitude.
		mean_mag = [];		% (array)   
        median_mag = [];     % (array)
        energy = [];
        total_counts = [];   % (scalar) sum of counts
		total_mag = [];      % (scalar) total sum of energy of all catalogObjects, represented as a magnitude	
        numbins = [];        % (scalar)
        min_mag = [];
        max_mag = [];
        etype = '*';
        snum = 0;
        enum = now;
        binsize = 1;
        stepsize = 1;
        misc_fields = {};
        misc_values = {};
    end
    
 %% PUBLIC METHODS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
	methods
        %% CONSTRUCTOR
        function self = EventRate(time, counts, energy, median_energy, ...
                smallest_energy, biggest_energy, median_time_interval, total_counts, ...
                snum, enum, etypes, binsize, stepsize, numbins)
            self.time = time;
            self.counts = counts;          
            self.median_rate = 1 ./ (median_time_interval * 24); 
            self.median_rate(counts<10) = 0;
            self.median_rate = max([self.counts / (24 * binsize); self.median_rate]);      
            self.median_mag = magnitude.eng2mag(median_energy);
            self.energy = energy;
            self.total_counts = total_counts;  	
            self.numbins = numbins;
            self.min_mag = magnitude.eng2mag(smallest_energy);
            self.max_mag = magnitude.eng2mag(biggest_energy);
            self.etype = etypes;
            self.snum = snum;
            self.enum = enum;
            self.binsize = binsize;
            self.stepsize = stepsize;
            if (enum-snum) < binsize
                error('binsize cannot be bigger than data time range');
            end
        end
        
        %% ----------------------------------------------
        %% GETTERS
        function cum_mag = get.cum_mag(erobj)
            cum_mag = magnitude.eng2mag(erobj.energy);
        end
        function mean_mag = get.mean_mag(erobj)
            mean_mag = magnitude.eng2mag(erobj.energy./erobj.counts);
        end
        function mean_rate = get.mean_rate(erobj)
            mean_rate = erobj.counts / (24 * erobj.binsize);
        end
        function total_mag = get.total_mag(erobj)
            total_mag = magnitude.eng2mag(sum(erobj.energy));
        end
         
    end % methods 
   
    methods(Static)
        cookbook()
    end

end




