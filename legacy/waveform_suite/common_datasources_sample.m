%% Definitions for commonly used waveform objects, to be loaded at startup
% This data file is called by |startup.m|.  Therefore, all the variables
% declared in here are created in my desktop environment.
%
% Created by Celso Reyes
% for use with the Waveform Suite
% April, 2009

%% Define commonly used <../datasource.html datasources>

% antelope continuous waveform database
ds_antelope = datasource('antelope',...
  '/iwrun/op/db/archive/archive_%04d/archive_%04d_%02d_%02d',...
  'year','year','month','day');
  
% collection of unprocessed waveforms, stored locally as .mat files
ds_rawfiles = datasource('file',...
  '/home/celso/okmokraw/%04d/%02d/OkmokRaw_%04d_%02d_%02d_%s.mat',...
  'year','month','year','month','day','station');

% a winston server (not currently available)
ds_winston = datasource('winston','mylocalwaveserver.giseis.alaska.edu',12345);

%%  predefine the Okmok stations (<../scnlobject.html scnlobjects>) used for my raw files

% All these definitions may be overkill, but I use them A LOT!!

% Short-Period stations...

%after some time in 2004, we changed from the notations of shz to ehz, so
%keep both 'cause I often query the database for 2003 data.
OKsta.sp.ehz = scnlobject (...
  {'OKAK','OKCF','OKER','OKRE','OKSP','OKTU','OKWE','OKWR'}... stations
  ,'EHZ',... all use the same channel
  'AV'... and are on the same network
  );

%now create older versions (pre mid-2004) by replacing EHZ with SHZ
OKsta.sp.shz = set(OKsta.sp.ehz,'channel','SHZ');

% Broadband stations...
OKsta.bb.hz = scnlobject({'OKCE','OKSO','OKFG','OKCD'},'BHZ','AV');
OKsta.bb.hn = set(OKsta.bb.hz,'channel','BHN');
OKsta.bb.he = set(OKsta.bb.hz,'channel','BHE');
OKsta.bb.all = [OKsta.bb.hz, OKsta.bb.hn, OKsta.bb.he];

% Commonly used combinations...
OKsta.all.current = [OKsta.sp.ehz, OKsta.bb.all];
OKsta.all.oldstyle = [OKsta.sp.shz, OKsta.bb.all];
