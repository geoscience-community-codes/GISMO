classdef eventrate
%
% EVENTRATE Event Rate class constructor.
% 
%    EVENTRATE is a class that has been developed around plotting earthquake
%    counts - i.e. the rate of events per unit time. It has evolved to compute
%    other metrics such the hourly mean event rate, median event rate, mean 
%    magnitude and cumulative magnitude, which are important metrics for an AVO
%    swarm tracking system.
%
%    EVENTRATE can import information from:
%    (1) a CATALOG object. 
%    (2) a Datascope database written in the "swarms1.0" schema, defined at AVO. 
%        This is the format used by the swarm tracking system.
%
%    ER = EVENTRATE() creates an empty eventrate object.
%
%    ER = EVENTRATE(CATALOG_OBJECT, BINSIZE) creates an eventrate object
%    from a CATALOG object using non-overlapping bins of BINSIZE days. 
%
%    ER = EVENTRATE(CATALOG_OBJECT, BINSIZE, 'stepsize', STEPSIZE) creates an eventrate object
%    using overlapping bins. If omitted STEPSIZE==BINSIZE.
%
%%   EXAMPLES:
%
%       First create a catalog object from the demo database:
%           dirname = fileparts(which('catalog')); % get the path to the catalog directory
%           dbroot = [dirname,'/demo/avodb200903']; 
%           cobj = catalog(dbroot, 'antelope', 'snum', datenum(2009,3,20), 'enum', datenum(2009,3,23), 'region','Redoubt');
%
%       (1) Create an eventrate object using a binsize of 1 day:
%           erobj = eventrate(cobj, 1);
%
%       (2) Create an eventrate object using a binsize of 1 hour:
%           erobj = eventrate(cobj, 1/24);
%
%       (3) Create an eventrate object using a binsize of 1 hour but a stepsize of 5 minutes:
%           erobj = eventrate(cobj, 1/24, 'stepsize', 5/1440);
%
%
%%   PROPERTIES
%
%    For a list of all properties type properties(eventrate)
%
%    dnum                % (array) time of the center of each bin as a DATENUM
%
%    METRICS:
%    counts 		     % (array) number of events in each bin
%    mean_rate           % (array) number of events per hour in each bin
%    median_rate	     % (array) reciprocal of the median time interval between events. Represented as an hourly rate.
%    cum_mag		     % (array) total sum of energy in each bin, represented as a magnitude.
%    mean_mag		     % (array)   
%    median_mag          % (array)
%    detection_threshold % (array) smallest magnitude in each bin
%
%    SUMMARY DATA:
%    numbins             % (scalar)
%    total_counts        % (scalar) sum of counts
%    total_mag           % (scalar) total sum of energy of all catalogObjs, represented as a magnitude
%
%    METADATA:
%    etype               % event type/classification. 
%    snum                % (scalar) start date/time in DATENUM format
%    enum                % (scalar) end date/time in DATENUM format
%    binsize             % (scalar) bin size in days
%    stepsize            % (scalar) step size in days
%    region              % (4-element vector) [minlon maxlon minlat maxlat]
%    minmag              % (scalar) magnitudes smaller than this were eliminated
%    dbroot              % path to the original data on disk
%    archiveformat       % indicates if the source is a flat file, or
%                          'daily' or 'monthly' volumes
%    auth                % auth of the events
%
%%   METHODS
%
%    For a list of all methods type methods(eventrate)
%
%    plot(er) or plot(er, 'metric', 'counts')    - event rate versus time
%    plot(er, 'metric', 'mean_rate')             - hourly mean event rate versus time
%    plot(er, 'metric', 'median_rate')           - hourly median event rate versus time
%    plot(er, 'metric', 'mean_mag')              - hourly mean magnitude versus time
%    plot(er, 'metric', 'cum_mag')               - hourly cumulative magnitude versus time
%    plot(er, 'metric', {'counts';'mean_rate';'cum_mag'}) - would make plots for all those metrics 
%							    mentioned in the cell array.
%    importfromswarmdb                           - construct an eventrate object from a swarm metrics 
%                                                   database, as written by the real-time swarm
%                                                   tracking module "dbdetectswarm".
%    set(erobj, 'property_name', value) - set property_name to value
%    get(erobj, 'property_name') - get value designated to property_name
%    addfield(erobj, 'fieldname', value) - add a field called fieldname
%
%%   See also CATALOG
%
%% AUTHOR: Glenn Thompson

% $Date$
% $Revision$

%% PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	properties (SetAccess=private)
        counts = []; 		% (array) number of events in each bin
		mean_rate = [];      % (array) number of events per hour in each bin
		median_rate = [];	% (array) reciprocal of the median time interval between events. Represented as an hourly rate.
		cum_mag = [];		% (array) total sum of energy in each bin, represented as a magnitude.
		mean_mag = [];		% (array)   
        median_mag = [];     % (array)
        total_counts = [];   % (scalar) sum of counts
		total_mag = [];      % (scalar) total sum of energy of all catalogObjs, represented as a magnitude
        dnum = [];           % (array) 	
        numbins = [];        % (scalar)
        detection_threshold = [];
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
        
        %------------------------------------------------------------------
        %% CONSTRUCTOR
        function Obj = eventrate(varargin)          
            if nargin==0
                disp('Creating null eventrate object');
                return;
            end
        
            switch class(varargin{1})
                case 'catalog', Obj = Obj.catalog2eventrate(varargin{:});
                case 'string', Obj = Obj.importswarmdb(dbname, auth, snum, enum);
                %otherwise, disp('Unknown first argument to constructor');
            end
        end 
        
        function Obj = catalog2eventrate(Obj, catalogObj, binsize, varargin)
           [stepsize, etypes] = matlab_extensions.process_options(varargin, 'stepsize', binsize, 'etypes', {'*'});       
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
                        %Obj(c,i) = eventrate();
                        Obj(c,i) = process_etype(Obj(c,i), catalogObj(c), j, binsize, stepsize, etypes(i));
                        Obj(c,i).mean_rate = Obj(c,i).counts / (24 * binsize);
                        Obj(c,i) = Obj(c,i).addfield('dbroot',catalogObj(c).dbroot);
                        Obj(c,i) = Obj(c,i).addfield('archiveformat',catalogObj(c).archiveformat);
                        Obj(c,i) = Obj(c,i).addfield('auth',unique(catalogObj(c).auth));
                    end % for
                end % if
            end % for
        end % function

        %------------------------------------------------------------------
        
 
        %% PLOT
        function plot(Obj, varargin) 
        % EVENTRATE/PLOT
        %   Plot metrics of an EVENTRATE object
        %   plot(eventrate_object [, 'metric', CellArrayofMetrics ]);
        %
        %   By default, the 'metric' parameter is set to {'counts'}, and so only a counts plot is produced
        %   This can be overridden, e.g.
        %       plot(eventrate_object, 'metric', {'energy'}) will plot 1 subplot per figure of energy vs. date/time
        %       plot(eventrate_object, 'metric', {'mean_rate';'median_rate'}) will plot 2 subplots per figure
        %
        %   The full range of possible metrics is:
        %       counts, cum_mag, mean_mag, median_mag, mean_rate, median_rate, detection_threshold, energy
        %
        %   If eventrate_object is an array of eventrate structures (e.g. one per etype), each is plotted on a separate figure

        [metric] = matlab_extensions.process_options(varargin, 'metric', {'counts'});
        if ~iscell(metric)
            metric = {metric};
        end

        for c = 1 : numel(Obj)
            numsubplots = length(metric);
            figure(gcf+1);

            for cc = 1: numsubplots
                if strcmp(metric{cc},'energy')
                    data = cumsum(magnitude.mag2eng(Obj(c).cum_mag));
                else
                    eval(  sprintf('data = Obj(c).%s;',metric{cc} ) );
                end
                subplot(numsubplots,1,cc), bar( Obj(c).dnum, data );
                datetick('x','keeplimits');
                ymax = nanmax(matlab_extensions.catmatrices(1, data));
                set(gca, 'YLim', [0 ymax]);
                ylabel(metric{cc});
            end
            suptitle(Obj(c).etype);
        end
        end % function
        
        %------------------------------------------------------------------
        %% IMPORTSWARMDB
        function Obj = importswarmdb(Obj, dbname, auth, snum, enum)
        % IMPORTSWARMDB
        % Load a swarm database metrics table into an EVENTRATE object
        % eventrate = importswarmdb(eventrateObj, dbname, auth, snum, enum);  
        %
        % INPUT:
        %	dbname		the path of the database (must have a 'metrics' table)
        %	auth		name of the grid to load swarm tracking metrics for
        %	snum,enum	start and end datenumbers (Matlab time format, see 'help datenum')
        %
        % OUTPUT:
        %	Obj		an eventrate object
        %
        % Example:
        %	erobj = importswarmdb('/avort/devrun/dbswarm/swarm_metadata', 'RD_lo', datenum(2010, 7, 1), datenum(2010, 7, 14) );
        
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
            catch me
                fprintf('Error: Could not open %s for reading',dbname);
                    return;
            end
            db = dblookup_table(db, 'metrics');
            if (dbquery(db, 'dbRECORD_COUNT')==0)
                fprintf('Error: Could not open %s for reading',dbtablename);
                return;
            end
            db = dbsubset(db, sprintf('auth ~= /.*%s.*/',auth));
            numrows = dbquery(db,'dbRECORD_COUNT');
            debug.print_debug(sprintf('Got %d rows after auth subset',numrows),2);
            sepoch = datenum2epoch(snum);
            eepoch = datenum2epoch(enum);
            db = dbsubset(db, sprintf('timewindow_starttime >= %f && timewindow_endtime <= %f',sepoch,eepoch));
            numrows = dbquery(db,'dbRECORD_COUNT');
            debug.print_debug(sprintf('Got %d rows after time subset',numrows),2);

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
            fprintf('Error: %s does not exist',dbtablename);
            return;
        end
        
        Obj.total_counts = sum(Obj.counts)*Obj.stepsize/Obj.binsize;
        
        end % function
    
        %------------------------------------------------------------------
        %% ADDFIELD
        function erobj = addfield(erobj,fieldname,value)
            %ADDFIELD add fields and values to EVENTRATE object(s) 
            %   erobj = addfield(erobj, fieldname, value)
            %   This function creates a new user defined field, and fills it with the
            %   included value.  If fieldname exists, it will overwrite the existing
            %   value.
            %
            %   Input Arguments
            %       EROBJ: an EVENTRATE object   N-DIMENSIONAL
            %       FIELDNAME: a string name
            %       VALUE: a value to be added for those fields.  Value can be anything
            %
            %   EVENTRATE objects can hold user-defined fields.  To access the contents, 
            %   use EVENTRATE/GET.
            %
            %   Example:
            %       erobj = eventrate(); % start with a blank eventrate
            %       totaleng = sum(mag2eng(erobj)); % create a total energy variable
            %       erobj = addfield(erobj, 'totaleng', totaleng);
            %
            % See also EVENTRATE/SET, EVENTRATE/GET, WAVEFORM/ADDFIELD

            % AUTHOR: Glenn Thompson, based entirely on WAVEFORM/ADDFIELD by
            % Celso Reyes
            % $Date$
            % $Revision$

            if isa(fieldname,'char')
                fieldname = {upper(fieldname)}; %convert to cell
            else
                error('EVENTRATE:addfield:invalidFieldname','fieldname must be a string')
            end

            actualfields = upper(fieldnames(eventrate(1))); %get the object's intrinsic fieldnames

            if ismember(fieldname,actualfields)
                erobj = set(erobj, fieldname{1}, value); %set the value of the actual field
                warning('EVENTRATE:addfield:fieldExists',...
                    'Attempted to add intrinsic field.\nNo field added, but Values changed anyway');
                return
            end

            % Fieldname isn't one that is intrinsic to the catalog object

            for n=1:numel(erobj)                
                miscF = erobj(n).misc_fields;   % grab the misc_fields (cell of fieldnames)
  
                if ~any(strcmp(fieldname,miscF)) % if the field doesn't already exist...
                    erobj(n).misc_fields = [miscF, fieldname]; %add the fieldname to the list
                end
                erobj(n) = set(erobj(n), fieldname{1},value);
            end
        end
    
        %------------------------------------------------------------------    
        %% SET
        function erobj = set(erobj, varargin)
        %SET Set properties for eventrate object(s)
        %   erobj = set(erobj,'property_name', val, ['property_name2', val2])
        %   SET is one of the two gateway functions of an object, such as EVENTRATE.
        %   Properties that are changed through SET are typechecked and otherwise
        %   scrutinized before being stored within the EVENTRATE object.  This
        %   ensures that the other waveform methods are all retrieving valid data,
        %   thereby increasing the reliability of the code.
        %
        %   Another strong advantage to using SET and GET to change  and retrieve
        %   properties, rather than just assigning them to catalog object directly,
        %   is that the underlying data structure can change and grow without
        %   harming the code that is written based on the catalog object.
        %
        %   Valid property names:
        %        'snum', 'enum'
		%
        %       If user-defined fields were added to the catalog object (ie, through
        %       addField), these fieldnames are also available through set.
        %
        %       Example:
        %           % create an eventrate object, and add a field called TOTAL_ENERGY
        %           erobj = eventrate(); 
        %           addfield(erobj,'TOTAL_ENERGY',1.67e9);
        %
        %           % change the value of the TOTAL_ENERGY field to 1.73e10
        %           erobj = set(erobj,'TOTAL_ENERGY',1.73e10);
        %
        %
        %   Batch changes can be made if input cobj is a matrix (use with care!)
        %
        %  See also EVENTRATE/GET, WAVEFORM/SET

        % AUTHOR: Glenn Thompson
        % LASTUPDATE: September 26, 2011

        Vidx = 1 : numel(varargin);

        while numel(Vidx) >= 2
            prop_name = upper(varargin{Vidx(1)});
            val = varargin{Vidx(2)};
  
            switch prop_name
            
                % SNUM - results in data being filtered
                case 'SNUM',
                if isa(val,'double')
                    if (val>=erobj.snum & val<erobj.enum)
                        [erobj.snum] = deal(val);
                        % erobj = filterdata(erobj, 'snum', erobj.snum);
                    else
                        error('EVENTRATE:set:propertyTypeMismatch','Expected a DOUBLE from %f to %f',erobj.snum,erobj.enum);
                    end
                end       
            
            
                % ENUM - results in data being filtered
                case 'ENUM',
                if isa(val,'double')
                    if (val>erobj.snum & val<=erobj.enum)
                        [erobj.enum] = deal(val);
                        % erobj = filterdata(erobj, 'enum', erobj.enum);
                    else
                        error('EVENTRATE:set:propertyTypeMismatch','Expected a DOUBLE from %f to %f',erobj.snum,erobj.enum);
                    end
                end    
            
                % DNUM
                case 'DNUM'
                if isa(val,'double')
                    [erobj.dnum] = deal(val);
                    if (val(1) < erobj.snum || val(end) > erobj.enum)
                        % Expand data vector too
                        disp('Could expand vectors here as in mergecounts/er_expand')
                    end
                     % Here would be good to have a method that also changes the data vectors if dnum range is being contracted
                    [erobj.snum] = deal(val(1));
                    [erobj.enum] = deal(val(end));
                end  
  
                % COUNTS
                case 'COUNTS'
                if isa(val,'double')
                    if (size(val)==size(erobj.dnum))
                        [erobj.counts] = deal(val);
                    else
                        error('EVENTRATE:set:COUNTS','counts must be the same size as dnum');
                    end
                else
                        error('EVENTRATE:set:propertyTypeMismatch','Expected a DOUBLE');
		
                end 
                
                % ETYPE
                case 'ETYPE'
                if isa(val,'char')
                    erobj.etype = val;
                end 
                
                otherwise
                    for n=1:numel(erobj)
                        switch prop_name
                            case erobj(n).misc_fields
                                %mask = ismember(erobj(n).misc_fields, prop_name);
                                mask = strcmp(prop_name,erobj(n).misc_fields);
                                erobj(n).misc_values(mask) = {val};
                            otherwise
                                error('EVENTRATE:set:unknownProperty',...
                                    'can''t understand property name : %s', prop_name);
                        end %switch
                    end %n
            end %switch
  
            Vidx(1:2) = []; %done with those parameters, move to the next ones...
        end % while loop
        end % function

    
        %------------------------------------------------------------------
        %% GET
        function val = get(erobj,prop_name)
            %GET Get EVENTRATE properties
            %   val = get(eventrate_object,'property_name')
            %
            %   For a list of valid property names type:
            %   PROPERTIES(EVENTRATE)
            %
            %   If catalog_object is N-dimensional, then VAL will be a cell of the same
            %   dimensions.  If GET would return single-values for the property, then
            %   VAL will be a matrix of type DOUBLE, arranged in the same dimensions.
            %
            %       If additional fields were added to catalog using ADDFIELD, then
            %       values from these can be retrieved using the fieldname
            %
            %       Example: Create an EVENTRATE object, add a field, then get the field
            %           erobj = eventrate;
            %           erobj = addfield(erobj,'TOTAL_ENERGY', 1e9);
            %           te = get(erobj,'TOTAL_ENERGY'); 
            %
            %
            %   See also EVENTRATE/SET, EVENTRATE/ADDFIELD, WAVEFORM/GET

            % AUTHOR: Glenn Thompson, Geophysical Institute, Univ. of Alaska Fairbanks
            % $Date$
            % $Revision$

            prop_name = upper(prop_name);
            switch prop_name
                
                case 'COUNTS', val=erobj.counts;
                case 'MEAN_RATE', val=erobj.mean_rate;
                case 'MEDIAN_RATE', val=erobj.median_rate;
                case 'CUM_MAG', val=erobj.cum_mag;
                case 'MEAN_MAG', val=erobj.mean_mag;
                case 'MEDIAN_MAG', val=erobj.median_mag;
                case 'TOTAL_COUNTS', val=erobj.total_counts;
                case 'TOTAL_MAG', val=erobj.total_mag;                    
                case 'DNUM', val=erobj.dnum;
                case 'NUMBINS', val=erobj.numbins;
                case 'BINSIZE', val=erobj.binsize;
                case 'STEPSIZE', val=erobj.stepsize;
                case 'SNUM', val=erobj.snum;
                case 'ENUM', val=erobj.enum;
                case 'DBROOT', val=erobj.dbroot;                  
                case 'ARCHIVEFORMAT', val=erobj.archiveformat;
                case 'AUTH', val=erobj.auth;    
                case 'REGION', val=erobj.region;                  

                otherwise
                    %perhaps we're trying to get at one of the miscelleneous fields?
                    val = cell(size(erobj));
                    for n = 1 : numel(erobj)
                        %loc is the position...
                        %w(n).misc_fields should ALWAYS already be in uppercase
                        mask = strcmp(prop_name,erobj(n).misc_fields);
                        %fieldwasfound = any(mask);
                        %[fieldwasfound, loc] = ismember(prop_name, erobj(n).misc_fields);
                        if any(mask)
                
                            val{n} = erobj(n).misc_values{mask};
                            %val{n} = erobj(n).misc_values{m};
                        else
                            warning('EVENTRATE:get:unrecognizedProperty',...
                                'Unrecognized property name : %s',  prop_name);
                        end
                    end
        
                    %check to see if value can be returned as a numeric value instead
                    %of cell.  Only if all values are numeric AND scalar
                    numberize = true;
                    for n=1:numel(val)
                        if ~(isnumeric(val{n}) && isscalar(val{n}))
                            numberize = false;
                            %usedcell = true;
                            break
                        end
                    end
                    if numberize,
                        Z = val;
                        val = nan(size(Z));
                        for n=1:numel(Z)
                            val(n) = Z{n};
                        end
                    end
        
            end % switch
            if (numel(val) == numel(erobj)) 
                val = reshape(val,size(erobj)); %return values in proper shape
            end

        end % function
        
        %------------------------------------------------------------------
    
    end % methods 
    
    %% PRIVATE METHODS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access=private)
        
        %------------------------------------------------------------------
        %% PROCESS_ETYPE
        function Obj = process_etype(Obj, catalogObj, j, binsize, stepsize, thisetype)
        % PROCESS_ETYPE
        % If multiple event types are requested, split them up into
        % separate EVENTRATE objects.
        % This is a private method only used by the constructor, i.e. not
        % for the user.
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

        % preserve some properties of the catalog object
        Obj = Obj.addfield('region', catalogObj.region);
        Obj = Obj.addfield('minmag', catalogObj.minmag);
        if isfield(catalogObj, 'dbroot')
            Obj = Obj.addfield('dbroot', catalogObj.dbroot);
        end
        if isfield(catalogObj, 'archiveformat')
        	Obj = Obj.addfield('dbroot', catalogObj.archiveformat);
        end

        % Do we have events of this etype?
        fprintf('Found %d matching events', length(j));

        if Obj.total_counts > 0
            [dnum_bin, counts_per_bin, sum_per_bin, smallest, median_per_bin, std_per_bin, median_time_interval] = matlab_extensions.bin_irregular(catalogObj.dnum(j), magnitude.mag2eng(catalogObj.mag(j)), binsize, catalogObj.snum, catalogObj.enum, stepsize);
            Obj.numbins = length(dnum_bin);
        	Obj.dnum = dnum_bin;
        	Obj.counts = counts_per_bin;
        	Obj.cum_mag = magnitude.eng2mag(sum_per_bin);
        	Obj.cum_mag(sum_per_bin==0) = NaN; % replace -Inf values (0 values in sum_per_bin) as they mess up plots
        	Obj.mean_mag = magnitude.eng2mag(sum_per_bin./counts_per_bin); % mean energy as a magnitude
        	Obj.median_mag = magnitude.eng2mag(median_per_bin); % median energy as a magnitude
        	Obj.mean_rate = counts_per_bin / (24 * binsize);
        	Obj.median_rate = 1 ./ (median_time_interval * 24);
        	Obj.detection_threshold = magnitude.eng2mag(smallest);
        	Obj.total_mag = magnitude.eng2mag(sum(magnitude.mag2eng(catalogObj.mag)));

        end
        end % function
    end % private methods
        


end
