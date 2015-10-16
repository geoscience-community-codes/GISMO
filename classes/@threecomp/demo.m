function [w,backAzimuth,trigger,staLat,staLon,origLat,origLon] = demo(TC)

%DEMO
% DEMO(THREECOMP) Loads demo waveforms and plots a station map of data used
% in the demo.


% LOAD DEMO WAVEFORMS
load('private/demo_waveforms.mat');


% SET TRIGGER TIMES
% These times represent crude surface wave picks on the
% transverse component
trigger =datenum({'2000/06/26 15:44:06'
'2000/06/26 15:43:39'
'2000/06/26 15:43:49'
'2000/06/26 15:44:07'
'2000/06/26 15:44:43'
'2000/06/26 15:44:05'
'2000/06/26 15:44:36'
'2000/06/26 15:43:54'
'2000/06/26 15:44:03'
'2000/06/26 15:43:44'
'2000/06/26 15:43:44'
'2000/06/26 15:44:02'
'2000/06/26 15:44:07'
'2000/06/26 15:43:59'});


% STATION LOCATIONS AND NAMES
staLat = get(w(:,1),'STATIONLATITUDE');
staLon = get(w(:,1),'STATIONLONGITUDE');
origLat = get(w(:,1),'ORIGINLATITUDE');
origLon = get(w(:,1),'ORIGINLONGITUDE');
staName = get(w(:,1),'STATION');


% PLOT MAP OF DEMO DATA
cookbook_map(threecomp,w,backAzimuth);


clear TC

