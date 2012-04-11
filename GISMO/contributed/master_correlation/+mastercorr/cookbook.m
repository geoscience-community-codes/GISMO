% Demonstration of the major features of the master waveform correlation
% toolbox. This example uses a small set of included data. This data is six
% 10-minute segments of data (1 hour total). MASTERCORR_SCAN can operate on
% waveform objects from any source or any length. Loading data is a process 
% left to the user. Individual segments exceeding a day or so in length may
% run into computational issues.
%
% See also mastercorr.plot_stats, mastercorr.cookbook, mastercorr.extract

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$




W = mastercorr.load_cookbook_data
W = fillgaps(W,0);
W = demean(W);
filt = filterobject('B',[0.8 12],2);
W = filtfilt(filt,W);
plot(W,'xunit','date')


% CREATE MASTER WAVEFORM "SNIPPET"
Wsnippet = extract(W(4),'TIME','4/2/2009 20:32:36','4/2/2009 20:32:40');


% ADD A REFERENCE "TRIGGER" TIME ON TRACE (OPTIONAL)
Wsnippet = addfield(Wsnippet,'TRIGGER',datenum('4/2/2009 20:32:37.73'));


% SCAN CONTINUOUS DATA FOR SNIPPET
[W,Wxc] = mastercorr.scan(W,Wsnippet,0.8);


% PLOT SOME BASIC STATISTICS TO ASSESS THE QUALITY
mastercorr.plot_stats(W);


% EXTRACT WAVEFORM MATCH INFO
match = mastercorr.extract(W)


% EXTRACT DATA SEGMENTS INTO A CORRELATION OBJECT
% See help correlation for details and subsequent options
[match,C] = mastercorr.extract(W,-2,6);
plot(C);

