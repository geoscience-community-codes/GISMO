%COOKBOOK demonstrate the features of the mastercorr package.
% W = COOKBOOK provides a demonstration of the major features of the master
% waveform correlation toolbox. This example uses a small set of included
% data. This data contains six 10-minute segments of data (1 hour total).
%
% See also mastercorr.plot_stats, mastercorr.cookbook, mastercorr.extract

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



%% LOAD COOKBOOK DATA
% In general use this is an exercise left to the user. Since you are using
% GISMO however, I assume you have data loading figured out!
W = mastercorr.load_cookbook_data


%% PREPARE DATA FOR CROSS CORRELATION
% Typically users will want to fill gaps and filter the data to a band of
% interest. Cross correlation almost always performs better when a gentle
% high pass filter is applied to remove the "roll" from the data.
W = fillgaps(W,0);
W = demean(W);
filt = filterobject('B',[0.8 12],2);
W = filtfilt(filt,W);
plot(W,'xunit','date')


%% CREATE MASTER WAVEFORM "SNIPPET"
% The snippet is a short template waveform that is used to scan the
% continuous data for matches. Note that the snippet can be a vector of
% different snippets.
Wsnippet = extract(W(4),'TIME','4/2/2009 20:32:36','4/2/2009 20:32:40');


%% ADD A REFERENCE "TRIGGER" TIME ON TRACE (OPTIONAL)
% Adding a trigger time is optional, but is a good thing to do. See
% MASTERCORR.SCAN for full explanation.
Wsnippet = addfield(Wsnippet,'TRIGGER',datenum('4/2/2009 20:32:37.73'));


%% SCAN CONTINUOUS DATA FOR SNIPPET
[W,Wxc] = mastercorr.scan(W,Wsnippet,0.8);


%% PLOT SOME BASIC STATISTICS TO ASSESS THE CORRELATION RESULTS
mastercorr.plot_stats(W);


%% EXTRACT INFORMATION ABOUT THE SUCCESSFUL WAVEFORM MATCHES
match = mastercorr.extract(W)


%% EXTRACT MATCH INFORMATION AND A CORRELATION OBJECT OF MATCHED WAVEFORMS
% See "help correlation" for details and subsequent options using the
% correlation object
[match,C] = mastercorr.extract(W,-2,6);
plot(C);

