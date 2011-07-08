%% VOLCSEIS cookbook
% This is a short demonstration of some of the more useful tools in the VOLCSEIS
% toolboxes. Through a long evolutionary process starting at AVO in 1998, and
% then through MVO, AEIC and back to AVO in 2008, this loose collection of
% M-files has been compiled in reaction to different needs and environments.
% They are in dire need of re-organisation.
%
% Today the main functions are:
% (1) Tools for analysing event catalogs.
% (2) Tools for tuning the swarm alarm system.
% (3) Tools for computing and plotting reduced displacement.
% (4) Tools for computing and plotting multi-station spectrograms.
% (5) Tools for plotting digital helicorders.
% There are also numerous library routines for manipulating times,
% waveform objects, and for retrieving data from Antelope event
% and station databases.
%
% In this cookbook we will examining 1 & 2 above in more detail. I will assume
% that you are currently logged on to the AVO Seismology Linux network at the
% Geophysical Institute at UAF. 
%
% Note that this cookbook is written as an M-file and is converted to HTML
% using the publish command. Type:
%
%> help publish
%
% for more information.

% Author: Glenn Thompson, Geophysical Institute, Univ. of Alaska Fairbanks

%% Configuration
% If you have not already started Matlab, do so now:
%> mat32 -nojvm
% To add the VOLCSEIS M-files to your Matlab path variable, call startup_volcseis:

startup_volcseis;

% Also before we start, we will set the debug (verbosity) level to 0, and
% warning to off. By choosing a higher debug level, each M-file will generate
% additional output

debug(0)
warning off

%% (1) Plotting event catalogs. 
% For the purpose of this exercise we will be using data from the Okmok 2008
% eruption. These data are stored in daily volumes, in Antelope CSS3.0 format,
% at /home/glenn/unrest/Okmok2008. Check that you can see this directory.
%
%> ls /home/glenn/unrest/Okmok2008

% You will see there are event databases matching Quakes_YYYY_MM_DD from
% 2008_05_02 to 2008_08_31, containing tables arrival, assoc, detection,
% emodel, event, lastid, netmag, origerr, origin, predarr and stamag.
% We will now load all the events / preferred origins with GETEVENTDATA.
% For convenience, we will create our input arguments in advance:

snum = datenum(2008,5,2);
enum = datenum(2008,8,31,23,59,59);
magthreshold = -0.5;
volcano = 'Okmok';
dbroot = '/home/glenn/unrest/Okmok2008/Quakes';
archiveformat = 'daily'; 
e = db2event(snum, enum, magthreshold, volcano, dbroot, archiveformat)

% Here the volcano field is used with the avo_volcs.pf file to apply a
% geographical latitude/longitude box filter to the data. (Note to self: This 
% should instead use the grids database). This will only work if you can see
% /avort/oprun.
%
% The result should be an event structure containing 2113 events, with fields
% lon, lat, depth, time, nass, evid, mag and etype.
%
%>> e
%e =
%              lat: [2113x1 double]
%            depth: [2113x1 double]
%             time: [2113x1 double]
%             nass: [2113x1 double]
%             evid: [2113x1 double]
%              mag: [2113x1 double]
%            etype: [2113x1 char]
%             snum: 733530
%             enum: 7.3365e+05
%     magthreshold: -0.5000
%           region: [-168.4000 -167.8000 53.2000 53.6000]
%           dbroot: '/home/glenn/unrest/Okmok2008/Quakes'
%    archiveformat: 'daily'
%

% Now we will make a plot of magnitude versus time. 

eventplot(e)
set(gcf,'Position',[50 50 700 400]);

% We might also only want to plot each 'etype' on a separate subplot:

eventplot(e, 'splitby', 'etype')
set(gcf,'Position',[50 50 700 400]);

% In this particular case, the output figure is the same as before because
% the event database we are using does not contain any etype information
% (such as 'a'/'t' for volcano-tectonic or 'b'/'l' for low frequency earthquakes).

% Next we can convert our event structure, e, into an event rate structure:

er = event2eventrate(e, 1)

% The result is:
% Found 2113 matching events
% er =
%            dnum: [1x122 double]
%          counts: [1x122 double]
%         cum_mag: [1x122 double]
%    total_counts: 2113
%       total_mag: 4.6948
%           etype: '*'
%            snum: 733530
%            enum: 7.3365e+05
%         binsize: 1
%         numbins: 122
%
% Here the '*' indicates that we are using a wildcard for etype. We have 122 bins of
% size 1 day. A total of 2113 events, and their combined energy is equivalent to 
% a magnitude 4.6948 earthquake.
%
% We can now plot this eventrate structure:

eventrateplot(er);
set(gcf,'Position',[50 50 700 400]);
 
% The result is a figure window with a counts per day plot above, and a cumulative
% magnitude per day plot below.
% Sometimes cumulative magnitude, being a logarithmic scale, doesn't really
% emphasise differences in cumulative energy clearly, so we can plot energy instead.

eventrateplot(er, 'type', 'energy');
set(gcf,'Position',[50 50 700 400]);

% Energy here is in arbitrary units.

%% Arrays of event and eventrate structures
% In general, if we have arrays of event structures, eventplot will plot each on
% a separate figure. Likewise if we have arrays of eventrate structures, eventrateplot
% will plot each on a separate figure. To show this better, we now will use data
% from two different data sources.
%
% The first dataset will be for Redoubt volcano, from 2009/03/15 to 2009/04/15

snum = datenum(2009,3,15);
enum = datenum(2009,4,15);
magthreshold = -0.5;
volcano = 'Redoubt';
dbroot = '/home/glenn/unrest/Redoubt2009/dbquakes/Quakes';
archiveformat = 'daily'; 
e(1) = db2event(snum, enum, magthreshold, volcano, dbroot, archiveformat)

%e1 =
%              lon: [6698x1 double]
%              lat: [6698x1 double]
%            depth: [6698x1 double]
%             dnum: [6698x1 double]
%             nass: [6698x1 double]
%             evid: [6698x1 double]
%              mag: [6698x1 double]
%            etype: [6698x1 char]
%             snum: 733847
%             enum: 733878
%     magthreshold: -0.5000
%           region: [-153 -152.2000 60.3000 60.7000]
%           dbroot: '/home/glenn/unrest/Redoubt2009/dbquakes/Quakes'
%    archiveformat: 'daily'
%
% For the second dataset, we change a few parameters:

dbroot = '/sun/Seis/Kiska4/picks/Total/Total';
archiveformat = ''; 
e(2) = db2event(snum, enum, magthreshold, volcano, dbroot, archiveformat)

% Now if we plot this array of event structures by etype, we get 2 figure windows.

eventplot(e, 'splitby', 'etype')
set(gcf,'Position',[50 50 700 400]);

% The first shows 6672 unclassified events from the real-time catalog.
% The second has two subplots, the upper showing 22 unclassified events from the
% analyst-reviewed catalog, the lower showing 1485 volcano-tectonic events from
% the analyst-reviewed catalog.
%
% Now we convert to a corresponding array of eventrate structures 

er = event2eventrate(e, 1)
set(gcf,'Position',[50 50 700 400]);

% Since we have not specified what etypes we are interested in, the etype field
% is ignored, and we get the same input (event) and output (eventrate) array sizes,
% in this case, 2x1.
%
% We can plot this with:

eventrateplot(er);
set(gcf,'Position',[50 50 700 400]);

% Alternatively, if we specify etypes as 'u' and 't' we get a different result:

er = event2eventrate(e, 1, 'ut')

% This time we get a 2x2 array of eventrate structures. First the unclassified
% events for each dataset, then the volcano-tectonic events for each. These can
% be plotted as before:

eventrateplot(er);
set(gcf,'Position',[50 50 700 400]);

%% Tuning the swarm alarm system
% For the purpose of the swarm alarm system, we can run simulations based on 
% eventrate structures, but we will also use an additional argument 'stepsize'
% to overlap adjacent bins. The swarm alarm system has usually been run with
% a 1 hour binsize (or timewindow), but a stepsize of just 5 minutes.
%
% Let us clear our workspace, and load in Redoubt data from the period 2009/03/01 to
% 2009/04/06.

clear all;
rehash;
close all;
snum = datenum(2009,3,1);
enum = datenum(2009,4,6);
magthreshold = -0.5;
volcano = 'Redoubt';
dbroot = '/home/glenn/unrest/Redoubt2009/dbquakes/Quakes';
archiveformat = 'daily'; 
e = db2event(snum, enum, magthreshold, volcano, dbroot, archiveformat);
%e =                                                                      
%              lon: [6630x1 double]                                       
%              lat: [6630x1 double]
%            depth: [6630x1 double]
%             dnum: [6630x1 double]
%             nass: [6630x1 double]
%             evid: [6630x1 double]
%              mag: [6630x1 double]
%            etype: [6630x1 char]
%             snum: 733833
%             enum: 733869
%     magthreshold: -0.5000
%           region: [-153 -152.2000 60.3000 60.7000]
%           dbroot: '/home/glenn/unrest/Redoubt2009/dbquakes/Quakes'
%    archiveformat: 'daily'

% Now lets create an eventrate structure, with a 1 hour window that slides by 5 minutes:

er = event2eventrate(e, 1/24, 'stepsize', 5/1440)
%Found 6630 matching events
%Elapsed time is 2.829267 seconds.
%er =
%                   dnum: [1x10357 double]
%                numbins: 10357
%                 counts: [1x10357 double]
%                cum_mag: [1x10357 double]
%               mean_mag: [1x10357 double]
%             median_mag: [1x10357 double]
%              mean_rate: [1x10357 double]
%            median_rate: [1x10357 double]
%    detection_threshold: [1x10357 double]
%           total_counts: 6630
%              total_mag: 10.1686
%                  etype: {'*'}
%                   snum: 733833
%                   enum: 733869
%                binsize: 0.0417
%               stepsize: 0.0035
%                 region: [-153 -152.2000 60.3000 60.7000]
%           magthreshold: -0.5000
%                 dbroot: '/home/glenn/unrest/Redoubt2009/dbquakes/Quakes'
%          archiveformat: 'daily'

% We can use eventrateplot to plot any of the data arrays contained in our
% eventrate structure, and these are:
%	counts
%	cum_mag
%	mean_mag
%	median_mag
%	mean_rate
%	median_rate
%	detection_threshold
%
% we can also plot energy, which is just the cum_mag converted back to energy.
%
% By default, only counts are plotted. This is because the field cell array defaults to:
% 
% >> field = {'counts'};
% 
% To plot mean_rate, median_rate and cum_mag instead, we just do:

field = {'mean_rate'; 'median_rate'; 'cum_mag'}
eventrateplot(er, 'field', field);

%% Loading event rate data from the real-time swarm alarm system
% The real-time swarm alarm system (the program dbdetectswarm) computes similar
% data to an eventrate structure, and stores it in a database table called 'metrics'
% which contains mean_rate, median_rate, mean_ml and cum_ml fields.


% To load these data into an eventrate structure, we use DB2EVENTRATE.

er2 = db2eventrate('/avort/devrun/dbswarm/swarm_metadata','RD_lo',now-50,now)

% This command should load these parameters based on all events in the real-time catalog
% located at Redoubt volcano in the previous 50 days. This can also be plotted in the
% standard way:

eventrateplot(er2);

% or:

eventrateplot(er2, 'field', {'mean_rate'; 'median_rate'; 'mean_mag'; 'cum_mag'} );

%% Simulating the swarm alarm system
% So far we have seen various ways to generate an eventrate structure - either from
% an event structure, or load from a database, and plot these data. Now we want to
% move on to simulating the swarm alarm system, which is helpful for tuning parameters.
%
%
% Let us begin with a favourite old dataset again - the 2009 Redoubt eruption:

clear all;
rehash;
close all;
snum = datenum(2009,2,1);
enum = datenum(2009,4,6);
magthreshold = -0.5;
volcano = 'Redoubt';
dbroot = '/home/glenn/unrest/Redoubt2009/dbquakes/Quakes';
archiveformat = 'daily'; 

% Plot the event structure, and store the axes handle as hax1.
e = db2event(snum, enum, magthreshold, volcano, dbroot, archiveformat);
eventplot(e);
hax1 = gca;

% Plot the eventrate structure, and store the axes handle as hax2.
er = event2eventrate(e, 1/24, 'stepsize', 5/1440);
eventrateplot(er, 'field', {'mean_rate'});
hax2 = gca;

% The simulation is not as configurable as the real-time swarm alarm system. There
% are only 4 input arguments to the program THRESHOLD2SWARMALARM:

help threshold2swarmalarm

% these are eventrate structure, mean_rate threshold, median_rate threshold and 
% significant change ratio threshold. If we use the following we are asking that
% a new swarm alarm be declared whenever mean_rate >=16 and median_rate >=32.
% And that the first escalation alarm be declared when mean_rate >=32 and 
% median_rate >= 64. And that the swarm end be declared when mean_rate < 8 and
% median_rate < 16.

a = threshold2swarmalarm(er, 16, 32, 2)

% We can turn this alarm structure, a, into a swarm structure, s:

s = alarm2swarm(a);

% Finally we can overlay a plot of these swarms over another plot axes, by
% passing a handle to those axes:

plotswarms(s, hax1);
plotswarms(s, hax2);

%% Reproducing figures like those shown in the swarm alarm system paper
%
% We can mark the current axes with the times of explosions (as red crosses):

add_redoubt_explosions;

% We can add the creation time as a suptitle:

addcreationtime;

% There are also functions for adding other labels, and for adding tremor alarms. 
%
% We did not mention that we can load an alarm database with DB2ALARM and then run
% ALARM2SWARM to generate a swarm structure as before.
%
% Finally, there ALARM2DB can be used to issue a new alarm message into an alarm
% database (where it will be dispatched by the alarm manager). Note, ALARM2DB is
% not used to convert an alarm structure into a database, but only to declare a
% single alarm from within a Matlab-based alarm system.





