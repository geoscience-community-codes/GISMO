%% Instrument response cookbook
% The goal of this toolbox is to provide a rapid way to apply instrument
% response corrections to seismic data. The response toolbox has routines
% for reading instrument responses from outside formats, visualizing
% responses, and correcting seismic data for their effects. The toolbox is
% not designed for creating or storing multistage instrument responses.
% There are numerous systems for storing response information. This toolkit
% focuses on providing users with tools to interact with existing response
% information.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

% TODO:
% Create NEW waveform for a good YAHTSE event for a couple of channels. DEMO+_PLUTONS
% Enable Antelope checking in response_get_from_db


%% Create a response structure from an Antelope database
% The response structure is the internal method for storing a response as a
% function of frequency (in Hz). This is independent of the native format
% of the response (poles/zeros, frequency/amplitude/phase tuples, FIR
% filters, etc.) Creation of the response structure is handled in the
% RESPONSE_GET_XXXXX functions.
time = datenum('2010/02/27');
dbName = response_demo_database;
frequencies = logspace(-2,2,100);
station = {'UTCA' 'UTTM' 'UTLO' 'UTSA'};
channel = {'SHZ' 'SHZ' 'BHZ' 'BHZ'};
for n = 1:4
    response(n) = response_get_from_db( station{n} , channel{n} , time , frequencies , dbName);
end


%% Show the fields of the response structure
% The response structure contains a number of fields
%
%       scnl: scnlobject associated with the response
%       time: time at which the response is valid
%frequencies: Nx1 vector of frequencies (Hz)
%     values: Nx1 vector of complex responses at each frequency.
%               Values should be normalized such that the maximum amplitude 
%               of the response (max(abs(values))) is near 1.
%      calib: Scaler alibration value used to scale the normalized responses
%               to their real value. NOTE that many waveform objects already
%               have this value applied.
%      units: Character string describing the units
% sampleRate: Sample rate in Hz
%   respFile: Character string of name (and path) of response file.
%     status: Open-ended character string describing any issues with file

response(1)


%% Create a response structure from a set of poles and zeros
% This usage requires as input a so-called polezero structure containing
% three fields named poles, zeros and normalization. The first two should
% be Nx1 while the normalization field is a scalar. Once this strcture
% exists it can be passed to response_get_frompolezero using the same
% frequencies term as above.

polezero = response_polezero_demo;
response_polezero = response_get_from_polezero(frequencies,polezero)


%% Plot responses
% This is a simple function that plots the instrument responses. Input
% RESPONSE structure follows the same construct as above. RESPONSE_PLOT can
% accept a single response structure or a matrix of responses. Some attempt
% is made to label in smart ways using the other fields in the resposne
% structure.

response_plot(response)
set(gcf,'Position',[50 50 700 400]);


%% Correct seismic waveforms for instrument response from Antelope database
dbName = response_demo_database;
w = response_demo_waveforms;
filterObj = filterobject('b',[0.5 10],3);
wCorrected = response_apply(w,filterObj,'antelope',dbName)

figure('Position',[50 50 700 400],'Color','w');
hold on;
plot(w(1),'b');
plot(wCorrected(1),'r');


% NOT FINISHED ....

%w = response_apply(w,filterObj,'polezero',polezero);
%w(3) = response_apply(w(1),filterObj,'structure',response)
% plot before and after ....






























