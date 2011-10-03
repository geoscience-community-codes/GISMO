%% CATALOG and EVENTRATE cookbook
%

%% Introduction
% This is a short demonstration of some of the methods of the CATALOG and EVENTRATE classes.
%
% It is assumed that you already have GISMO on your MATLAB path.
%
% This cookbook is written as an M-file and is converted to HTML using the PUBLISH command.
%
% Author: Glenn Thompson, Geophysical Institute, Univ. of Alaska Fairbanks

%% Loading event catalogs
% The catalog class is for loading, plotting and analysing event catalogs.
% For a detailed description, read HELP CATALOG.M.
%
% For the purpose of this exercise we will be using data from Redoubt volcano
% from 2009/03/20 to 2009/03/23. We will use two catalogs:
%
% # The real-time catalog, produced using Antelope.
% # The analyst-reviewed offical AVO catalog, produced using Earthworm,
% XPick and Hypoellipse (and then later converted to an Antelope database).
%
% Both catalog segments are distributed in the "demo" directory.
%
% We will now load the real-time catalog into a catalog object. First,
% because we don't know where GISMO is on your system, we have to construct the
% path to the demo directory based on where CATALOG.M resides:

dirname = fileparts(which('catalog')); 
dbpath = [dirname,'/demo/avodb200903']; 
cobj = catalog(dbpath, 'antelope', 'snum', datenum(2009,3,20), 'enum', datenum(2009,3,23), 'region', 'Redoubt')

%% Magnitude-time plot
% You should see that there are 1397 events in these 3 days. What are their
% magnitudes? For a simple magnitude versus time plot, just call plot on
% the catalog object:
plot(cobj)

%% Volplot
% For a map view, lat-depth, lon-depth and time-depth section, use volplot:
volplot(cobj)

%% Magnitude statistics
% For a look at various statistics of magnitude on a daily basis:
plotdailymagstats(cobj)

%% Adding arrivals to a catalog object
% By default the arrival property of a catalog object is left blank.
% To populate it do:
cobj = cobj.addArrivals()

%% Plots of earthquake counts
% For a quick plot of earthquakes per hour, we create an eventrate object
% and then plot it. Here our binsize is 1/24 days, i.e. 1 hour.
erobj = eventrate(cobj, 1/24)
plot(erobj);

%% Event rates for overlapping time windows
% Sometimes it is desirable to compute event rate metrics for sliding -
% i.e. overlapping - time windows. This is easily done with the 'stepsize'
% parameter. If omitted, stepsize defaults to the binsize - which is the
% length of the time window. So in the previous example, both binsize and
% stepsize were 1.0 hours. But we can just as easily compute an eventrate
% object for the same catalog object with a binsize of 1 hour, and stepsize
% of just 5 minutes. 
erobj2 = eventrate(cobj, 1/24, 'stepsize',  5/1440)
plot(erobj2)

%% Plots of other event rate metrics
% >> plot(erobj) is actually equivalent to typing:
%
% >> plot(erobj, 'metric', 'counts');
%
% The full list of metrics that can be plotted are:
%%
% 
% * counts
% * mean_rate
% * median_rate
% * cum_mag
% * mean_mag
% * median_mag
% * energy
% 
% All of these are properties of an eventrate object except for energy,
% which is computed from cum_mag on-the-fly.
%
% Several can be plotted at once in subplots of the same figure using a cell array:
%
% >>plot(erobj2, 'metric', {'mean_rate'; 'median_rate'; 'mean_mag'; 'cum_mag'});
%
% Or they can of course be plotted in separate figure windows:
plot(erobj2, 'metric', 'mean_rate')
plot(erobj2, 'metric', 'median_rate')
plot(erobj2, 'metric', 'mean_mag')
plot(erobj2, 'metric', 'cum_mag')
%%
% These are the same metrics, binsize and stepsize used by the AVO swarm tracking system.
% See: <http://www.aeic.alaska.edu/input/west/papers/2009_srl_thompson_redoubtSwarms.pdf>
% for details.


%% Other methods
% This has really only skimmed the surface of CATALOG and EVENTRATE class
% functionality.
% Both can also make use of the etype (event subclassification, e.g. lp,
% vt, hybrid, rockfall) in making plots.
%
% CATALOG has preliminary methods to compare the hypocenters and magnitude
% differences between two catalog objects.
% CATALOG can also superimpose station locations, if an environment
% variable called DBMASTER is set to point to the location of a master
% stations database.
%
% For further information, feel free to email: gthompson@alaska.edu






