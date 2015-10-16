%% Loading and displaying seismic event catalogs in MATLAB

% A seismic event catalog is any list that contains at a minimum the time
% of 1 or more seismic events. 

% For located earthquakes it will contain the longitude, latitude, depth, 
% and likely the location errors and the magnitude also.

% It may also contain information such as the phase arrival times, and
% and magnitudes measured on each station. 

% However, there are a large number of formats in which this information
% may be stored, depending on the software that was used to produce the
% catalog, or for data providing by an online data center (e.g IRIS DMC) it
% will depend on how they have chosen to represent catalog data. 

% As scientists, we don't really care what format the data comes in, we
% just want to be able to use it. But we cannot use it without
% understanding it and writing our own code to parse that format into
% MATLAB variables. This can be a time consuming and buggy process, and it
% also requires that we make a good choice about how to design the data
% structures that we load these data into in MATLAB. 

% GISMO's Catalog class is a solution to these problems. Just as waveform
% objects are the universal container for handling waveform data from any
% source or data format, the Catalog class does the same for catalog data.

%% Loading an event catalog from IRIS DMC:

% To load catalog data into a Catalog object we use the readEvents 
% function. The first argument is the data source/format - in this case 
% readEvents will use the irisfetch program to retrieve all events at IRIS
% DMC with a magnitude of at least 7.9:

catalogObject = readEvents('irisfetch', 'minimumMagnitude', 7.9);

% Let's see what this catalog object, catalogObject, contains:

catalogObject

% As you can see, the size of the lat, lon, depth, time and mag matrices
% are 1 x 41. This means we have retrieved 41 events. snum and enum are the
% times of the first and last event respectively, in MATLAB's datenum
% format (decimal days since year 0). The time matrix is also in datenum
% format. 

% catalogObject is of type "Catalog_full". This means that it also contains an
% event_list property, which holds a set of 41 Event objects. Each Event
% object can contain information about phase arrivals as well as
% alternative origins and magnitudes. We will ignore Event objects in this
% tutorial. 

% etype is a cell array containing the event type for each of the 41
% events. In this case each is just 'earthquake', but when dealing with a
% more diverse dataset, many other etype's are possible. 



  Catalog_full with properties:

     event_list: [1x41 Event]
            lat: [1x41 double]
            lon: [1x41 double]
          depth: [1x41 double]
           time: [1x41 double]
            mag: [1x41 double]
          etype: 'earthquakeearthquakeearthquakeearthquakeearthquakeearthquak...'
           dnum: []
           snum: 7.1602e+05
           enum: 7.3622e+05
    description: ''
    misc_fields: {'METHOD'}
    misc_values: {'convert_irisFetch_to_Catalog'}
    
    
    
catalogObject = readEvents('irisfetch','radialcoordinates', [60.4853 -152.7431 km2deg(20)]);

% reads all events within 20 km of Redoubt volcano, held by IRIS





% For the purpose of this exercise we will be using data from Redoubt volcano
% from 2009/03/20 to 2009/03/23. We will use two catalogs:
%
% # The real-time catalog, produced using Antelope (rtdb200903).
% # The analyst-reviewed offical AVO catalog (avodb200903), produced using 
% Earthworm, XPick and Hypoellipse, later converted to an Antelope
% database.
%
% Both catalog segments are distributed in the "demo" directory.
%
% We will now load the real-time catalog into a catalog object. First,
% because we don't know where GISMO is on your system, we have to construct the
% path to the demo directory based on where CATALOG.M resides:
if antelope_exists
    dbpath = demodb('avo');

% Now read the events into a Catalog object. Only two parameters are
% needed, the database path (dbpath) and the data format ('antelope'): 
    catalogObject = readEvents('datascope', 'dbpath', dbpath);

% This should load 1441 events. What if we only want events within 15km of
% Redoubt volcano? The optional parameter 'subset_expression' can be used, with an
% appropriate Datascope expression, e.g.

    catalogObject = readEvents('datascope', 'dbpath', dbpath, 'subset_expression', 'deg2km(distance(lat, lon, 60.4853, -152.7431))<15.0');

% where 60.4853 is the latitude of Redoubt and -152.7431 is the longitude.
% Now there should only be 1397 events.

%% PLOTTING HYPOCENTERS
%% Magnitude-time plot
% You should see that there are 1441 events in these 3 days. What are their
% depths and magnitudes as a function of time?
catalogObject.plot_time()

%% 3D-Hypocenters
% For a 3D hypocenter map, use plot3:
catalogObject.plot3()

%% PLOTTING B-VALUES & ESTIMATING MAGNITUDE OF COMPLETENESS
% Code from "ZMap" (written by Stefan Wiemer and others) has been added
% to Catalog to compute and plot bvalues. Use the bvalue method:
catalogObject.bvalue()

% This will give a menu of techniques available to compute b-value (b) and
% magnitude of complteness (Mc)
catalogObject.bvalue(1)
% will use technique 1

%% PLOTTING EVENT COUNTS & ENERGY RELEASE RATES
% For a quick plot of earthquakes per hour, we create an eventrate object
% and then plot it. Here our binsize is 1/24 days, i.e. 1 hour.
eventrateObject = catalogObject.eventrate('binsize', 1/24);
eventrateObject.plot()

% Now let's change to a smaller bin size of just 20 minutes
eventrateObject = catalogObject.eventrate('binsize', 20/1440);
plot(eventrateObject);

%% Event rates for overlapping time windows
% Sometimes it is desirable to compute event rate metrics for sliding -
% i.e. overlapping - time windows. This is easily done with the 'stepsize'
% parameter. If omitted, stepsize defaults to the binsize - which is the
% length of the time window. So in the previous example, both binsize and
% stepsize were 1.0 hours. But we can just as easily compute an eventrate
% object for the same catalog object with a binsize of 1 hour, and stepsize
% of just 5 minutes. 
% eventrateObject = catalogObject.eventrate('binsize', 1/24,  'stepsize', 5/1440);
% eventrateObject.plot()

%% Plots of other event rate metrics
% eventrateObject.plot() is actually equivalent to typing:
%   eventrateObject.plot(), 'metric', 'counts');
% 
% The full list of metrics that can be plotted are:
% * counts
% * mean_rate
% * median_rate
% * cum_mag
% * mean_mag
% * median_mag
% * energy
% 
% All of these are properties of an eventrate object except for energy,
% which is computed from _cum_mag_ on-the-fly.
%
% Several can be plotted at once in subplots of the same figure using a cell array:
%
%     eventrateObject.plot('metric', {'mean_rate'; 'median_rate'; 'mean_mag'; 'cum_mag'});
%
% Or they can of course be plotted in separate figure windows:
%     eventrateObject2.plot('metric', 'mean_rate')
%     eventrateObject2.plot('metric', 'median_rate')
%     eventrateObject2.plot('metric', 'mean_mag')
%     eventrateObject2.plot('metric', 'cum_mag')
eventrateObject.plot('metric', {'mean_rate'; 'median_rate'; 'mean_mag'; 'cum_mag'});

%% The AVO Swarm Tracking System
% These are the same metrics, binsize and stepsize used by the AVO swarm tracking system.
% See: < <http://www.aeic.alaska.edu/input/west/papers/2009_srl_thompson_redoubtSwarms.pdf> >
% for details.

%% Helena Plot
eventrateObject.helenaplot()

%% Python plot
eventrateObject.pythonplot()

%% Loading data from a Seisan REA database
% Here we load events from a Seisan catalog. A Seisan
% "Sfile" contains all the metadata for 1 event.
% These Sfiles are stored in a flat-file database structure the path to
% which is: $SEISAN_TOP/REA/databaseName. Sfiles are organized in
% year/month subdirectories under this path. The following will navigate
% this where in this case $SEISAN_TOP = '/raid/data/seisan' and the
% databaseName is MVOE_ which stands for the Montserrat Volcano Observatory
% Event database. (In Seisan, databaseName is limited to exactly 5
% characters).
% This example will load all Sfiles for January 1st, 2000. This is a slow
% function to run as MATLAB is slow at parsing text files.
catalogObject = readEvents('seisandb', 'dbpath', fullfile('/raid','data','seisan','REA','MVOE_'), 'snum', datenum(2000,1,1), 'enum', datenum(2000,1,2) );

% This catalog object can now be explored using eev, which is modelled on
% the program of the same name in Seisan. We will not run this here because
% it is an interactive function which would cause this cookbook to fail.
% But here is what you would do:
% >> catalogObject.eev()
% You will see:
% 2000-01-01 00:51:06 l   NaN:  ?
% From there type h <ENTER> to see the list of options. s will show you the
% S-file. p will plot the corresponding waveforms using waveform>mulplt.










