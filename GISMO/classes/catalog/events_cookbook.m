%% Reading and displaying seismic events in MATLAB

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
% source or data format, the Events class does the same for catalog data.

%% Section 1: Loading events from IRIS DMC and saving to other formats

% To load events into an Events object we use the readEvents 
% function. The first argument is the data source/format - in this case 
% readEvents will use the irisfetch program to retrieve all events at IRIS
% DMC with a magnitude of at least 7.9:

eventsObject = readEvents('iris', 'minimumMagnitude', 7.9, ...
    'starttime', '2000-01-01', 'endtime', '2015-01-01');

% Let's see what this Events object, eventsObject, contains:

eventsObject

% As you can see, the size of the time, lon, lat, depth, mag, magtype and
% etype matrices are 1 x 26. This means we have retrieved 26 events. The 
% time matrix is in MATLAB's datenum format (decimal days since year 0).

% eventsObject is of type "Events". etype is a cell array containing the 
% event type for each of the 26 events. In this case each is just 
% 'earthquake', but when dealing with more diverse dataset, many other 
% etype's are possible. magtype is whatever magnitude type was assigned by
% the agency that provided the magnitude data.

% The arrivals property is blank. This is a cell array that can optionally
% contain phase arrival data. See the Arrival class for more on this. We
% will not deal with arrivals in this tutorial.

% Now we'll do another example - we will get events within 20 km of Redoubt
% volcano in the IRIS DMC database between January 1st and June 1st, 2009..
% We'll limit our search to events in the upper 40km because we are
% interested in volcanic earthquakes only:

eventsObject = readEvents('iris', ...
    'radialcoordinates', [60.4853 -152.7431 km2deg(20)], ...
    'starttime', '2009/01/01', ...
    'endtime', '2009/06/01', ...
    'maximumDepth', 40.0);

% Only 2 earthquakes. Disappointing. There were in fact many much smaller
% earthquakes than this but those only appear in the catalog of the Alaska
% Volcano Observatory. Part of the AVO catalog is included as the demodb in
% part 2. For now, we will save the events we have read from IRIS;

eventsObject.save('myevents.mat')

% We will also try to save them to an Antelope database. This should fail
% gracefully if you do not have BRTT's Antelope toolbox installed.

%eventsObject.write('antelope','mylocaldb','css3.0');

%% Section 2: Loading an Antelope database 

% For the purpose of this exercise we will be using data from Redoubt volcano
% from 2009/03/20 to 2009/03/23. We will use snippets from two catalogs
% that are provided with GISMO in Antelope format:
%
% # The real-time catalog (rtdb200903).
% # The analyst-reviewed offical AVO catalog (avodb200903).
%
% Both catalog segments are included in the "demo" directory.
%
% We will now load the official AVO catalog into an Events object:

if admin.antelope_exists
    dbpath = demodb('avo'); 
    eventsObject = readEvents('antelope', 'dbpath', dbpath);
end

% This should load 1441 events. What if we only want events within 20km of
% Redoubt volcano? The optional parameter 'subset_expression' can be used, with an
% appropriate Datascope expression, e.g.

redoubtLon = -152.7431; redoubtLat = 60.4853;
if admin.antelope_exists
    eventsObject = readEvents('antelope', 'dbpath', dbpath, 'subset_expression', 'deg2km(distance(lat, lon, redoubtLat, redoubtLon))<20.0');
end

% Now there should be 1397 events. A lot better than 2! Let's save this
% dataset to a MAT file
eventsObject.save('avo_redoubt.mat')



%% Section 3: PLOTTING HYPOCENTERS
% Magnitude-time plot
% -------------------
% You should see that there are 1441 events in these 3 days. What are their
% depths and magnitudes as a function of time?
eventsObject.plot_time()

% 3D-Hypocenters
% --------------
% For a 3D hypocenter map, use plot3:
eventsObject.plot3()

%% Section 4: PLOTTING B-VALUES & ESTIMATING MAGNITUDE OF COMPLETENESS
% Code from "ZMap" (written by Stefan Wiemer and others) has been added
% to Events to compute and plot bvalues. Use the bvalue method:
eventsObject.bvalue()

% This will give a menu of techniques available to compute b-value (b) and
% magnitude of complteness (Mc)
eventsObject.bvalue(1)
% will use technique 1

%% Section 5: PLOTTING EVENT COUNTS & ENERGY RELEASE RATES
% For a quick plot of earthquakes per hour, we create an eventrate object
% and then plot it. Here our binsize is 1/24 days, i.e. 1 hour.
eventrateObject = eventsObject.eventrate('binsize', 1/24);
eventrateObject.plot()

% Now let's change to a smaller bin size of just 20 minutes
eventrateObject = eventsObject.eventrate('binsize', 20/1440);
plot(eventrateObject);

%% Event rates for overlapping time windows
% Sometimes it is desirable to compute event rate metrics for sliding -
% i.e. overlapping - time windows. This is easily done with the 'stepsize'
% parameter. If omitted, stepsize defaults to the binsize - which is the
% length of the time window. So in the previous example, both binsize and
% stepsize were 1.0 hours. But we can just as easily compute an eventrate
% object for the same Events object with a binsize of 1 hour, and stepsize
% of just 5 minutes. 
% eventrateObject = eventsObject.eventrate('binsize', 1/24,  'stepsize', 5/1440);
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

% These are the same metrics, binsize and stepsize used by the AVO swarm tracking system.
% See: < <http://www.aeic.alaska.edu/input/west/papers/2009_srl_thompson_redoubtSwarms.pdf> >
% for details.

%% Section 5: Loading data from a Seisan (Nordic) database
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
eventsObject = readEvents('seisandb', 'dbpath', fullfile('/raid','data','seisan','REA','MVOE_'), 'snum', datenum(2000,1,1), 'enum', datenum(2000,1,2) );

% This Events object can now be explored using eev, which is modelled on
% the program of the same name in Seisan. We will not run this here because
% it is an interactive function which would cause this cookbook to fail.
% But here is what you would do:
% >> eventsObject.eev()
% You will see:
% 2000-01-01 00:51:06 l   NaN:  ?
% From there type h <ENTER> to see the list of options. s will show you the
% S-file. p will plot the corresponding waveforms using waveform>mulplt.

% %% Helena Plot
% eventrateObject.helenaplot()
% 
% %% Python plot
% eventrateObject.pythonplot()







