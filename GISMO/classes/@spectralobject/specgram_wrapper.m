function result=specgram_wrapper(s, w, spectrogramFraction, mycolormap)
% SPECGRAM_WRAPPER produce an multi-channel spectrogram plot in the style of
% AVO web (IceWeb) spectrograms, but by wrapping gismotools specgram function
%
% Usage:
% 	result=specgram_wrapper(s, w, spectrogramFraction)
%
% Inputs:
%	w - a vector of waveform objects
%	s - a spectralobject
%	spectrogramFraction - fraction of a panel height the spectrogram should take up (default: 0.8). 
%			The waveform trace takes up the remaining fraction.
%
% Outputs:
%	(other than a figure on the screen)
%	result = true if successful, false if there was an error

% waveform should already have had zero-length waveform objects replaced by zero vectors 

% AUTHOR: Glenn Thompson, University of Alaska Fairbanks
% $Date$
% $Revision$


result = 0;

numw = length(w);
if numw==0
	return;
end
if ~exist('s','var')
	s = spectralobject(1024, 924, 10, [60 120]);
end
if ~exist('spectrogramFraction','var')
	spectrogramFraction = 1;
end
if ~exist('mycolormap', 'var')
    mycolormap = jet; % should be using SPECTRAL_MAP here?
end
%s = spectralobject(1024, 924, 10, [40 140]);


debug.print_debug(sprintf('%d waveform objects',numel(w)),0);

% draw spectrogram using Celso's 
try
    setmap(s, mycolormap)
	sg = specgram_local(s, w, 'xunit', 'date', 'colorbar', 'none', 'yscale', 'normal'); % default for colormap is SPECTRAL_MAP

catch
	debug.print_debug('specgram failed on waveform vector. Trying again, using nonempty rather than fillempty',0);
	w = waveform_nonempty(w);
	if numel(w)>0
		debug.print_debug(sprintf('%d waveform objects after removing empty waveform objects',numel(w)),0);
		try
 			sg = specgram_local(s, w, 'xunit', 'date', 'colorbar', 'none', 'yscale', 'normal'); % default for colormap is SPECTRAL_MAP           
		catch
			disp('specgram_wrapper crashed again');
		end	
	else
		debug.print_debug('specgram failed on waveform vector. Tried nonempty rather than fillempty, but looks like all waveform objects were empty, so skipping',0);
		return;
	end	
end

% To get a colorbar, stop the function here and set colorbar option to vert

% Get axis handles
ha = get(gcf, 'Children');

% Change X-Labels
hxl = get(ha, 'XLabel');
if numw > 1
	for c=1:numw
		set(hxl{c}, 'String', '');
	end
else
%	set(hxl, 'String', '');
end

% Change Y-Labels to 'sta\nchan'
for c=1:numw
	hyl = get(ha(c), 'YLabel');
	hyl_string = sprintf('%s.%s',get(w(numw-c+1), 'station'), get(w(numw-c+1), 'channel'));
	set(hyl, 'String', hyl_string,'FontSize',10);
end

% Remove titles
for c=1:numw
	ht = get(ha(c), 'Title');
	set(ht, 'String', '');
end
%if exist('titlestr','var')
%	set(ht,'String',titlestr,'Color',[0 0 0],'FontSize',[14], 'FontWeight',['bold']');
%end

% Set appropriate date ticks
[wsnum, wenum]=gettimerange(w);
wt.start = min(wsnum);
wt.stop = max(wenum);
[Xtickmarks,XTickLabel]=findMinuteMarks(wt);
set(ha, 'XTick', Xtickmarks, 'XTickLabel', {},  'FontSize', 10);
set(ha(1), 'XTick', Xtickmarks, 'XTickLabel', XTickLabel, 'FontSize', 10);

% Set X-range to full time range
set(ha,'XLim', [wt.start wt.stop]);

% Reset axes position & squeeze in the trace panels
for c=1:numw
	%[spectrogramPosition, tracePosition] = calculatePanelPositions(length(w), c, spectrogramFraction, 0.8, 0.8);
	[spectrogramPosition, tracePosition] = calculatePanelPositions(length(w), c, spectrogramFraction, 0.88, 0.95);
	set(ha(c), 'position', spectrogramPosition);
	if spectrogramFraction < 1
		thissta = get(w(c), 'station');
		thischan = get(w(c), 'channel');
		plotTrace(tracePosition, get(w(numw-c+1),'data'), get(w(numw-c+1),'freq'), Xtickmarks, wt, mycolormap, s, thissta, thischan);
		set(gca,'XLim', [wt.start wt.stop]); % added 20111214 to align trace with spectrogram when data missing (prevent trace being stretched out)

		if (regexp(thischan, 'BH.'))
			set(gca, 'Color', [1 .5 .5]);
		end
	end
end
result = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plotTrace(tracePosition, data, freqSamp, Xtickmarks, timewindow, mycolormap, s, thissta, thischan);
snum =timewindow.start;

% set axes position
axes('position',tracePosition);

% trace time vector - bins are ~0.01 s apart (not 5 s as for spectrogram time)
% not really worthwhile plotting more than 1000 points on the screen
dnum = ((1:length(data))./freqSamp)/86400 + snum;

% plot seismogram
try
	data = detrend(data);
end
data(find(data==0))=NaN;
traceHandle = plot(dnum, data);

% blow up trace detail so it almost fills frame
maxAmpl = max(abs(data));
if (maxAmpl == 0) % make sure that max_ampl is not zero
	maxAmpl = 1;
end

% set properties
%rgb = amplitude2tracecolor(maxAmpl, mycolormap, s);
%set (traceHandle,'LineWidth',[0.01],'Color',rgb)
set (traceHandle,'LineWidth',[0.01],'Color',[0 0 0])

%datetick('x', 15, 'keeplimits');
set(gca, 'XTick', Xtickmarks, 'XTickLabel', '', 'XLim', [timewindow.start timewindow.stop], 'Ytick',[],'YTickLabel',['']);
%axis tight;

if ~isnan(maxAmpl) % make sure it is not NaN else will crash
	traceRange = [dnum(1) dnum(end) -maxAmpl*1.1 maxAmpl*1.1];
	decibels = 20 * log10(maxAmpl) + eps;
	fprintf('%s: %s.%s: Max amplitude %.1e nm/s (%d dB)\n',mfilename, thissta, thischan, maxAmpl,round(decibels)); 
	axis(traceRange);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rgb = amplitude2tracecolor(maxAmpl, mycolormap, s);
a = 20 * log10(maxAmpl) + eps;
dBlims = get(s, 'dBlims');
index = round( ( (a - dBlims(1)) / (dBlims(2) - dBlims(1)) ) * (length(mycolormap)-1) ) + 1;
index=max([index 1]);
index=min([index length(mycolormap)]);
rgb = mycolormap(index, :);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Xtickmarks,Xticklabels]=findMinuteMarks(timewindow);

% calculate where minute marks should be, and labels
snum = matlab_extensions.ceilminute(timewindow.start);
enum = matlab_extensions.floorminute(timewindow.stop);


% Number of minute marks should be no greater than 20
numMins = (enum - snum) * 1440;
stepMinOptions = [1 2 3 5 10 15 20 30 60 120 180 240 360 480 720 1440];
c = 1;
while (numMins / stepMinOptions(c) > 20)
	c = c + 1;
end
stepMins = stepMinOptions(c);

Xtickmarks = snum:stepMins/1440:enum;
Xticklabels = datestr(Xtickmarks,15); 



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [panelPosition, tracePosition] = calculatePanelPositions(numframes, frameNum, fractionalPanelHeight, panelWidth, panelHeight);

frameHeight 		= panelHeight/numframes;
fractionalAxesHeight 	= fractionalPanelHeight * frameHeight;
traceHeight 		= (1 - fractionalPanelHeight) * frameHeight; 
%panelLeft		= (1 - panelWidth)/2;
panelLeft		= 0.08;
panelBase		= 0.025 + (1 - panelHeight)/2;
panelPosition 	= [panelLeft, panelBase + (frameHeight * (frameNum - 1)), panelWidth, fractionalAxesHeight];
tracePosition 		= [panelLeft, panelBase + (frameHeight * (frameNum - 1)) + fractionalAxesHeight, panelWidth, traceHeight];


