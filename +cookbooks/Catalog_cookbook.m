%% Reading events into a Catalog object
% GISMO can read events from many different earthquake catalog file formats
% (e.g. Seisan, Antelope) and data sources (e.g. IRIS DMC) using the
% Catalog.retrieve() method.

%% Reading events from IRIS DMC
% To load events into a Catalog object we use the readEvents function. 
% The first argument is the data source/format - when this is given as 
% 'iris', readEvents uses the irisFetch.m program to retrieve event data 
% via the IRIS webservices. To narrow down our data search we can give 
% readEvents any name-value parameter pairs supported by irisFetch.
%
% In this example we will use readEvents to retrieve all events at IRIS DMC 
% with a magnitude of at least 8.0 between year 2000 and 2014 (inclusive):

greatquakes = Catalog.retrieve('iris', 'minimumMagnitude', 8.0, ...
    'starttime', '2000-01-01', 'endtime', '2015-01-01')

%%
% We have retrieved 26 events. To access any particular property we can use
% dot notation, as if the object were a structure, e.g.:

greatquakes.etype

%%
% etype contains the event type for 
% each of the 26 events. In this case each is just  'earthquake', but when 
% dealing with more diverse dataset, many other etype's are possible. 
% magtype is whatever magnitude type was assigned by the agency that 
% provided the magnitude data.

%%
% greatquakes is a Catalog object, an instance of the Catalog class. To see
% a list of functions ("methods" in object-oriented speak) we can apply to
% a Catalog object, use the methods command:

methods(greatquakes)

%%
% Save this dataset so you can use it again later:

save('great_earthquakes.mat', 'greatquakes')

%%
% Now we'll do another example - we will get events within 200 km of the 
% great M9.0 Tohoku earthquake that occurred on 2011/03/11. 
% The mainshock parameters are: 
% 
%     Date/Time:  "2011/03/11 05:46:24"
%     Longitude:  142.372
%     Latitude:   38.297
%     Depth:      30 km
 
%%
% We will limit our search to 1 day before and after the earthquake:
 
mainshocktime = datenum('2011/03/11 05:46:24')
tohoku_events = Catalog.retrieve('iris', ...
            'radialcoordinates', [38.297 142.372 km2deg(200)], ...
            'starttime', mainshocktime - 1, ...
            'endtime', mainshocktime + 1);

%%
% This returns 1136 earthquakes. Let's get a summary:

tohoku_events.summary()

%%
% Save this dataset so you can use it again later:

save('tohoku_events.mat', 'tohoku_events')


%% Readings events from an Antelope database
% To load event data from an Antelope/Datascope CSS3.0 database you will 
% need to have Antelope (<http://www.brtt.com/software.html>) installed, 
% including the Antelope toolbox for MATLAB.
% 
%%
% *SCAFFOLD: NOTE THAT CURRENTLY NOT USING THE RTDB200903 AT ALL* 
% 
% For the purpose of this exercise we will be using data from Redoubt 
% volcano from 2009/03/20 to 2009/03/23. We will use snippets from two 
% catalogs that are provided with GISMO in Antelope format:
 
%%
%
% * The real-time catalog (rtdb200903).
% * The analyst-reviewed offical AVO catalog (avodb200903).

%%
% Both catalog segments are included in the "demo" directory. 
% We will now load the official AVO catalog into an Events object:
  
dbpath = cookbooks.demodb('avo');
avocatalog = Catalog.retrieve('antelope', 'dbpath', dbpath);
 
%%
% This should load 1441 events. What if we only want events within 20km of 
% Redoubt volcano? There are two ways to do this. The first is the use the
% radialcoordinates parameter:

redoubtLon = -152.7431; 
redoubtLat = 60.4853;
maxR = km2deg(20.0);
redoubt_events = Catalog.retrieve('antelope', 'dbpath', dbpath, ...
	'radialcoordinates', [redoubtLat redoubtLon maxR])

%%
% Save this dataset so you can use it again later:

save('redoubt_events.mat', 'redoubt_events')

%%
% The second way is to use the 'subset_expression' which the Antelope
% expression evaluator interprets:
expr = sprintf('distance(lat, lon, %f, %f) < %f',redoubtLat, redoubtLon,maxR)
catalogObject = Catalog.retrieve('antelope', 'dbpath', dbpath, ...
	'subset_expression', expr)

%% Reading events from a Seisan database
% Here we load events from a Seisan catalog. A Seisan "Sfile" contains all
% the metadata for 1 event. These Sfiles are stored in a flat-file database
% structure the path to which is: $SEISAN_TOP/REA/databaseName. Sfiles are 
% organized in year/month subdirectories under this path.
%
% *SCAFFOLD: INCLUDE DEMO DATASET FROM MVOE*

%%
% The following will navigate this where in this case 
% $SEISAN_TOP = '/raid/data/seisan' and the databaseName is MVOE_ which 
% stands for the Montserrat Volcano Observatory Event database. 
% (In Seisan, databaseName is limited to exactly 5 characters).
%
% This example will load Sfiles from 4 hours on 1st Nov, 1996. This is a slow 
% function to run as MATLAB is slow at parsing text files, and there are
% many events per day in this particular database.
 
montserrat_events = Catalog.retrieve('seisan', ...
    'dbpath', fullfile('/raid','data','MONTSERRAT','seisan','REA','MVOE_'), ...
	'startTime', '1996/11/01 11:00:00', ....
	'endTime', '1996/11/01 15:00:00')

%%
% Save this dataset so you can use it again later:

save('montserrat_events.mat', 'montserrat_events')

%%
% Only a few of these earthquakes have been located and even fewer have
% magnitudes. This is common for volcanic earthquakes. Most of these are of
% type 'h' - a hybrid earthquake.

%% Converting a Zmap data structure to a Catalog object
% ZMap is a graphical application written by Max Wyss & Stefan Wiemer for
% statistical analysis of catalogs. GISMO can convert a ZMap data structure
% into a Catalog object with:
%
%    catalogObject = Catalog.retrieve('zmap', zmapdata)

%% Plotting hypocenter maps
% Catalog objects have three builtin ways for plotting hypocenters

%%
% Reload the Tohoku dataset
load tohoku_events.mat

%%
% *Map view & cross-sections*
tohoku_events.plot()

%%
% *3D-Hypocenters*
tohoku_events.plot3()

%%
% *web map*
%%
% 
%   tohoku_events.webmap()


%% Plotting time series of events
% *Magnitude-time plot*

tohoku_events.plot_time()

%%
% *Earthquake event counts (number of events per unit time)*
% A plot of seismic catalog per day is often called an "event counts" plot.
% In GISMO, we call this an "event rate plot" and the first step is to 
% generate an EventRate object. Here our binsize is 1/24 days, i.e. 1 hour.

eventrateObject = tohoku_events.eventrate('binsize', 1/24)

%%
% Now plot the EventRate object:
eventrateObject.plot()

%%
% We can do the same thing for another dataset, e.g. redoubt_events
redoubt_events.plot_time()
erobj_red = redoubt_events.eventrate('binsize', 1/24)
erobj_red.plot()

%%
% To see more of the things we can do with EventRate objects see the
% EventRate cookbook <EventRate.html>



%% Analysis
% *Peak event rate (PR) and maximum magnitude*
% A common type of analysis is to identify the peak rate in an earthquake
% sequence such as this preshock-mainshock-aftershock sequence or an 
% earthquake swarm. This can be done with:

tohoku_events.plotprmm()


%%
% In the command window this returns:
%     MM=9.1 occurs at 50.0% of time series
%     PR=32 occurs at 53.5% of time series
%
% These are labelled on the plot above with PR and MM.

%%
% Now with the Redoubt dataset
redoubt_events.plotprmm()

%%
% *b-value and magnitude of completeness*
% Code from "ZMap" (written by Stefan Wiemer and others) has been added to 
% Catalog to compute and plot b-values and the magnitude of completeness. 

%%
% Definitions:
%
% * b-value: the slope of a plot of the logarithm of the cumulative number of events against magnitude. A measure of the number of small earthquakes to larger earthquakes.
% * magnitude of completeness (Mc): all events with magnitude>=Mc are in the catalog. Below Mc, not all events are detected, and below the magnitude detection threshold, no events are captured.

%%
% Just calling the bvalue method, i.e.
%
%   catalogObject.bvalue() 
%
% displays a menu of techniques available to compute b-value (b) and 
% magnitude of completeness (Mc):
%
%     --------------------------------------------------------
%     Usage is: eventsObject.bvalue(mcType)
%     --------------------------------------------------------
%     mcType can be:
%     1: Maximum curvature
%     2: Fixed Mc = minimum magnitude (Mmin)
%     3: Mc90 (90% probability)
%     4: Mc95 (95% probability)
%     5: Best combination (Mc95 - Mc90 - maximum curvature)
% 
% We will use the first menu option:

tohoku_events.bvalue(1)

%%
% In this particular example, the b-value is 0.6 and the magnitude of 
% completeness is 4.2.

%%
% Now for the Redoubt events:

redoubt_events.bvalue(1)

%% Saving Catalog objects to disk
% *Writing to a MAT file*
% We've already seen how to do this, the general syntax is:
%    save('myfilename.mat', 'myCatalogObject')

%%
% This can simply be loaded again with:
%    load('myfilename.mat')

%% 
% *Writing to an Antelope CSS3.0 database*
% This method requires the Antelope toolbox for MATLAB and writes the 
% Catalog as a CSS3.0 flat-file database:

%%
% First make sure there is no database with this name already - else we
% will be appending to it:
delete greatquakes_db*

%%
% Now write to the database
greatquakes.write('antelope', 'greatquakes_db', 'css3.0')

%% 
% This database can be reloaded with:

greatquakes2 = Catalog.retrieve('antelope', 'dbpath','greatquakes_db')

%%
% Compare:

greatquakes

%%
% This concludes the Catalog cookbook/tutorial.

