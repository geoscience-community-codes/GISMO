%% How to compute RSAM data

%% 1. Introduction
%
% Computing rsam data from waveform objects is easy to do with the
% waveform2rsam method. But waveform objects are generally no more than 1
% hour long. So what if you want to compute RSAM data for days, weeks or
% months of waveform data? How do we set this up?
%
% This is where we use "IceWeb", an application originally written in 1998
% to process continuous waveform data into a variety of products for
% volcano observatory web pages, to aid rapid recognition of anomalous
% activity. Since we only want RSAM data in this case, we will drive this
% using iceweb.rsam_wrapper. To get help on this, use:
%%
% 
%  help iceweb.iceweb_wrapper
% 

%%
% RSAM data will be saved to binary "BOB" files in a directory
% "iceweb/rsam_data". So the final step in the tutorial will show how to
% load and plot these data.
%
% The following is a fully worked example using the Sakurajima
% dataset for illustration.


%% 2. Setup for the Redoubt 2009 example

%%
% Define datasource - where to get waveform data from
dbpath = fullfile(TESTDATA, 'css3.0', 'demodb')
datasourceObject = datasource('antelope', dbpath)

%% 
% Define the list of channels to get waveform data for
ChannelTagList = ChannelTag.array('AV',{'REF';'RSO'},'','EHZ')

%%
% Set the start and end times
startTime = datenum(2009,3,20,2,0,0)
endTime = datenum(2009,3,23,12,0,0)


%% 3. Call the iceweb_wrapper
iceweb.iceweb_wrapper('Redoubt', datasourceObject, ChannelTagList, ...
            startTime, endTime);
             
%%        
% Note: this may take a long time to run, e.g. 1 week of data for 1
% channel might take about 10 minutes on a desktop computer, reading data
% from a network-mounted drive.
