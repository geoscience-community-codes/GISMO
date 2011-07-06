classdef eventrate
%
% EVENTRATE Event Rate class constructor, version 1.0.
% 
% EVENTRATE is a class that has been developed around plotting earthquake
% counts - i.e. the rate of events per unit time. It has evolved to compute
% other metrics such the mean event rate, median event rate, mean magnitude
% and cumulative magnitude per hour, which are important metrics for an AVO
% swarm tracking system.  
%
% ER = EVENTRATE() creates an empty eventrate object.
%
% ER = EVENTRATE(CATALOGOBJECT, BINSIZEINDAYS) creates an eventrate object
% from a CATALOG object. See CATALOG for more details.
%
% EXAMPLES:
%
% ER = EVENTRATE(catalogobject, 1.0) creates an eventrate object from a
% catalog object, with a binsize of 1 day.
%
% % ER = EVENTRATE(catalogobject, 1/24) creates an eventrate object from a
% catalog object, with a binsize of 1 hour.
%
%
% % ------- DESCRIPTION OF FIELDS IN AN EVENTRATE OBJECT ------------------
% counts; 		% (array) number of events in each bin
% mean_rate;      % (array) number of events per hour in each bin
% median_rate;	% (array) reciprocal of the median time interval between events. Represented as an hourly rate.
% cum_mag;		% (array) total sum of energy in each bin, represented as a magnitude.
% mean_mag;		% (array)   
% median_mag;     % (array)
% total_counts;   % (scalar) sum of counts
% total_mag;      % (scalar) total sum of energy of all catalogObjs, represented as a magnitude
% dnum;           % (array) 	
% numbins;        % (scalar)
% detection_threshold
% etype
% snum
% enum
% binsize
% stepsize
% region
% minmag
% dbroot
% archiveformat
% auth
%
% % ------- METHODS -------- %
%
% plot(er) or plot(er, 'field', 'counts')   - event rate versus time
% plot(er, 'field', {'mean_rate'})            - hourly mean event rate versus time
% plot(er, 'field', {'median_rate'})          - hourly median event rate versus time
% plot(er, 'field', {'mean_mag'})             - hourly mean magnitude versus time
% plot(er, 'field', {'cum_mag'})              - hourly cumulative magnitude versus time
% plot(er, 'field', {'counts';'mean_rate';'cum_mag'}) - would make plots for all those metrics mentioned in the cell array.
% importfromswarmdb - yep, there is a method to construct an eventrate
% object from a swarm metrics database, as written by the real-time swarm
% tracking module "dbdetectswarm".
%
% % ------- SEE ALSO -------- %
% CATALOG 

% AUTHOR: Glenn Thompson, Montserrat Volcano Observatory
% $Date: 2000-09-11 $
% $Revision: 0 $

	properties
        counts; 		% (array) number of events in each bin
		mean_rate;      % (array) number of events per hour in each bin
		median_rate;	% (array) reciprocal of the median time interval between events. Represented as an hourly rate.
		cum_mag;		% (array) total sum of energy in each bin, represented as a magnitude.
		mean_mag;		% (array)   
        median_mag;     % (array)
        total_counts;   % (scalar) sum of counts
		total_mag;      % (scalar) total sum of energy of all catalogObjs, represented as a magnitude
        dnum;           % (array) 	
        numbins;        % (scalar)
        detection_threshold;
        etype = '*';
        snum = 0;
        enum = now;
        binsize = 1;
        stepsize = 1;
        region = [-179.999 179.999 -89.999 89.999];
        minmag = -Inf;
        dbroot ='';
        archiveformat = '';
        auth = '';
	end
	methods
        
        function Obj = eventrate(varargin)

            switch nargin
                case 0, return;
            end
            if strcmp(class(varargin{1}), 'char')
                Obj = eventrate();
                Obj = importswarmdb(Obj, varargin{1}, varargin{2}, varargin{3}, varargin{4});
                return;
            end
            if strcmp(class(varargin{1}), 'catalog')
                Obj = eventrate();
                catalogObj = varargin{1};
                binsize = varargin{2};
                if nargin==2
                    Obj = importcatalog(Obj, catalogObj, binsize);
                else
                    disp('sprintf(This mode is no longer supported. \nInstead create a blank eventrate object with er = eventrate(). \nThen call er.importcatalog(catalogObj, binsize, varargin');
                end 
            end
        end     
        
        function Obj = importcatalog(Obj, catalogObj, binsize, varargin);
            disp('CRUNCH FROM CATALOG *****************')
        % Obj = eventrate(catalogObj, binsize, varargin);
        %
        % catalog2eventrate converts an catalogObj structure into an eventrate object, using a bin size of binsize days,
        % starting at snum and going until enum is reached. 
        %
        % INPUT:  
        % 	binsize = bin size for binning event data in days (e.g. 1/24 = 1 hour, 1/1440 = 1 minute)
        %	stepsize = step size in days, this is how much bins are incremented each time. Default is binsize.
        %	           Cannot be larger than binsize.
        %	etypes = (optional) a character array of the etypes to select. Each will be returned
        % 		in a separate eventrate object. For example, etypes = 'relht' would return
        %		a 5x1 array of eventrate objects. Default is '*' (groups all etypes together).
        % 	minmag will cut out events with a largest magnitude (ml, mb, ms) smaller than this.
        %
        % Example 1:
        % 	Obj = importcatalog(catalogObj, 1/24);
        %
        % This will return an Obj structure with bins of 1 hour
        %
        %
        % % Example 2:
        % 	Obj = importcatalog(catalogObj, 10/1440, 'etype', 'rlt', 'minmag', 0.5);
        %
        % This will return a 3x1 array of eventrate structures corresponding to etypes 'r', 'l' and 't', with bins of 10 minutes
        % eliminating all events with magnitudes less than 0.5.
        %
        % % Example 3:
        % 	Obj = importcatalog(catalogObj, 10/1440, 'stepsize', 5/1440, 'etype', 'rlt', 'minmag', 0.5);
        %
        % As above, but with 10 minute bins which slide by 5 minutes each time, so there is a 50% overlap. For example, there might
        % be 10 minutes bins starting at 10:00, 10:05, 10:10, 10:15, 10:20, etc. If stepsize is omitted, it defaults to the same as
        % binsize so there is no overlap between adjacent bins.
        
        % Author: Glenn Thompson, 2002-2010

        if nargin<2
            disp('Need at least 2 arguments');
            %help event2eventrate
            return;
        end

        [stepsize, etypes, minmag] = process_options(varargin, 'stepsize', binsize, 'etypes', {'*'}, 'minmag', -999.0);
        if (stepsize > binsize)
            disp(sprintf('Invalid value for stepsize (%f). Cannot be greater than binsize (%f).',stepsize, binsize));
            return;
        end
        
        for c=1:length(catalogObj)

            % Check for silliness
            if isempty(catalogObj(c).dnum)
                disp('catalogObj structure contains no data');
                return;
            else
                numetypes = length(etypes); 
                for i=1:numetypes
			       if strcmp(etypes(i),'*')
                        j = 1:length(catalogObj(c).dnum);
                   else
                        j=find(ismember(catalogObj(c).etype, etypes(i))==1);
                   end
                    Obj(c,i) = eventrate();
                    Obj(c,i) = process_etype(Obj(c,i), catalogObj(c), j, binsize, stepsize, etypes(i));
                    Obj(c,i).mean_rate = Obj(c,i).counts / (24 * binsize);
                    Obj(c,i).dbroot = catalogObj(c).dbroot;
                    Obj(c,i).archiveformat = catalogObj(c).archiveformat;
                    Obj(c,i).auth = unique(catalogObj(c).auth);
                end
            end
        end
        end % function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function Obj = process_etype(Obj, catalogObj, j, binsize, stepsize, thisetype);
        % Initialise blank
        Obj.dnum = catalogObj.snum + binsize/2 : stepsize : catalogObj.enum - binsize/2;
        Obj.numbins = length(Obj.dnum);
        Obj.counts = zeros(1, Obj.numbins);
        Obj.cum_mag = ones(1, Obj.numbins) * -999.0;
        Obj.mean_mag = ones(1, Obj.numbins) * -999.0;
        Obj.median_mag = ones(1, Obj.numbins) * -999.0;
        Obj.mean_rate = zeros(1, Obj.numbins);
        Obj.median_rate = zeros(1, Obj.numbins);
        Obj.detection_threshold = ones(1, Obj.numbins) * NaN;
        Obj.total_counts = length(j);
        Obj.total_mag = -999.0;
        Obj.etype = thisetype;
        Obj.snum = catalogObj.snum;
        Obj.enum = catalogObj.enum;
        Obj.binsize = binsize;
        Obj.stepsize = stepsize;

        % preserve some properties of the event structure
        Obj.region = catalogObj.region;
        Obj.minmag = catalogObj.minmag;
        if isfield(catalogObj, 'dbroot')
            Obj.dbroot = catalogObj.dbroot;
        end
        if isfield(catalogObj, 'archiveformat')
        	Obj.archiveformat = catalogObj.archiveformat;
        end

        % Do we have events of this etype?
        disp(sprintf('Found %d matching events', length(j)));

        if Obj.total_counts > 0
            [dnum_bin, counts_per_bin, sum_per_bin, smallest, median_per_bin, std_per_bin, median_time_interval] = bin_irregular(catalogObj.dnum(j), mag2eng(catalogObj.mag(j)), binsize, catalogObj.snum, catalogObj.enum, stepsize);;
            Obj.numbins = length(dnum_bin);
        	Obj.dnum = dnum_bin;
        	Obj.counts = counts_per_bin;
        	Obj.cum_mag = eng2mag(sum_per_bin);
        	Obj.cum_mag(find(sum_per_bin==0)) = NaN; % replace -Inf values (0 values in sum_per_bin) as they mess up plots
        	Obj.mean_mag = eng2mag(sum_per_bin./counts_per_bin); % mean energy as a magnitude
        	Obj.median_mag = eng2mag(median_per_bin); % median energy as a magnitude
        	Obj.mean_rate = counts_per_bin / (24 * binsize);
        	Obj.median_rate = 1 ./ (median_time_interval * 24);
        	Obj.detection_threshold = eng2mag(smallest);
        	Obj.total_mag = eng2mag(sum(mag2eng(catalogObj.mag)));

        end
        end % function
        
        function plot(Obj, varargin); 
        % By default, the 'field' parameter is set to {'counts'}, and so only a counts plot is produced
        % This can be overridden, e.g.
        % plot(er, 'field', {'energy'}) will plot 1 subplot per figure of energy vs. date/time
        % plot(er, 'field', {'mean_rate';'median_rate'}) will plot 2 subplots per figure
        %
        % The full range of possible fields is:
        %	counts, cum_mag, mean_mag, median_mag, mean_rate, median_rate, detection_threshold, energy
        %
        % If er is an array of eventrate structures (e.g. one per etype), each is plotted on a separate figure
        %
        % Author: Glenn Thompson
        [field] = process_options(varargin, 'field', {'counts'});
        if ~iscell(field)
            field = {field};
        end

        for c = 1 : numel(Obj)
            numsubplots = length(field);
            figure(gcf+1);

            for cc = 1: numsubplots
                if strcmp(field{cc},'energy')
                    data = mag2eng(Obj(c).cum_mag);
                else
                    eval(  sprintf('data = Obj(c).%s;',field{cc} ) );
                end
                subplot(numsubplots,1,cc), bar( Obj(c).dnum, data );
                datetick('x','keeplimits');
                ymax = nanmax(catmatrices(1, data));
                set(gca, 'YLim', [0 ymax]);
                ylabel(field{cc});
            end
            suptitle(Obj(c).etype);
        end
        end % function
    %end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    %methods(Access = public, Static)
        function Obj = importswarmdb(Obj, dbname, auth, snum, enum);
        % loads a swarm tracking metrics table into a Matlab eventparams structure
        % Obj = importswarmdb(eventrateObj, dbname,auth,snum,enum);  
        %
        % INPUT:
        %	dbname		the path of the database (must have a 'metrics' table)
        %	auth		name of the grid to load swarm tracking metrics for
        %	snum,enum	start and end datenumbers (Matlab time format, see 'help datenum')
        %
        % OUTPUT:
        %	Obj		a structure containing the fields snum, enum, mean_rate, median_rate, mean_ml and cum_ml
        %
        % Example:
        %	eventrate = db2eventrate('/avort/devrun/dbswarm/swarm_metadata', 'RD_lo', datenum(2010, 7, 1), datenum(2010, 7, 14) );
        %
        % Glenn Thompson, 20100714

        % initialize
        Obj.dbroot = dbname;
        Obj.snum = snum;
        Obj.enum = enum;
        Obj.auth = auth;

        % check that database exists
        dbtablename = sprintf('%s.metrics',dbname);
        if exist(dbtablename,'file')
            % load the data
            try
                db = dbopen(dbname, 'r');
            catch
                disp(sprintf('Error: Could not open %s for reading',dbname));
                    return;
            end
            db = dblookup_table(db, 'metrics');
            if (dbquery(db, 'dbRECORD_COUNT')==0)
                disp(sprintf('Error: Could not open %s for reading',dbtablename));
                return;
            end
            db = dbsubset(db, sprintf('auth ~= /.*%s.*/',auth));
            numrows = dbquery(db,'dbRECORD_COUNT');
            print_debug(sprintf('Got %d rows after auth subset',numrows),2);
            sepoch = datenum2epoch(snum);
            eepoch = datenum2epoch(enum);
            db = dbsubset(db, sprintf('timewindow_starttime >= %f && timewindow_endtime <= %f',sepoch,eepoch));
            numrows = dbquery(db,'dbRECORD_COUNT');
            print_debug(sprintf('Got %d rows after time subset',numrows),2);

            if numrows > 0
                % Note that metrics are only saved when mean_rate >= 1.
                % Therefore there will be lots of mean_rate==0 timewindows not in
                % database.
                [tempsepoch, tempeepoch, mean_rate, median_rate, mean_mag, cum_mag] = dbgetv(db,'timewindow_starttime', 'timewindow_endtime', 'mean_rate', 'median_rate', 'mean_ml', 'cum_ml');
                Obj.binsize = (tempeepoch(1) - tempsepoch(1))/86400;
                Obj.stepsize = min(tempsepoch(2:end) - tempsepoch(1:end-1))/86400;
                Obj.dnum = snum+Obj.stepsize:Obj.stepsize:enum;
                Obj.numbins = length(Obj.dnum);
                Obj.mean_rate = zeros(Obj.numbins, 1);
                Obj.counts = zeros(Obj.numbins, 1);
                Obj.median_rate = zeros(Obj.numbins, 1);
                Obj.mean_mag = zeros(Obj.numbins, 1);
                Obj.cum_mag = zeros(Obj.numbins, 1);
                for c=1:length(tempeepoch)
                    tempenum = epoch2datenum(tempeepoch(c));
                    i = find(Obj.dnum == tempenum);
                    Obj.mean_rate(i) = mean_rate(c);
                    Obj.counts(i) = mean_rate(c) * (Obj.binsize * 24);
                    Obj.median_rate(i) = median_rate(c); 
                    Obj.mean_mag(i) = mean_mag(c);
                    Obj.cum_mag(i) = cum_mag(c);
                end
            end
            dbclose(db);


        else
            % error - table does not exist
            disp(sprintf('Error: %s does not exist',dbtablename));
            return;
        end
        
        Obj.total_counts = sum(Obj.counts)*Obj.stepsize/Obj.binsize;
        
        end % function
    end
end    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

