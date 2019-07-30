function [Tcell, Fcell, Ycell, meanf, peakf] = spectrogram( w, varargin )
%SPECTROGRAM Plot an IceWeb-style spectrogram
%   spectrogram(w, s) Creates an IceWeb style spectrogram by wrapping the
%   function iceweb.spectrogram_iceweb(). If s is omitted it defaults to:
%       spectralobject(1024, 924, 10, [60 120])
%   where [60 120] are the dB limits that correspond to the color map used.
%   If this is a blank vector, [], the spectrogram is autoscaled in absolute
%   amplitude, not plotted in dB with absolute dB limits.
%
%   spectrogram(w, s, 'plot_metrics', 1) Will add frequency metrics computed
%   by the waveform/amplitude_spectrum function.
%
% For greater control, call
%   iceweb.spectrogram_iceweb() directly, or use spectralobject/specgram or
%   spectralobject/specgram2 (not clear how these differ). Note that
%   spectrogram_iceweb() is significantly faster.

% Glenn Thompson 2016/05/19 to provide a simple, fast way to geenrate nice
% spectrograms without having to delve into specgram and specgram2
figure
nfft = 1024;
overlap = 924;
fmax = 10;
dbLims = [60 120];
p = inputParser;
p.addRequired('w');
p.addParameter('spectralobject', spectralobject(nfft, overlap, fmax, dbLims));
p.addParameter('plot_metrics', false, @isnumeric);
p.addParameter('relative_time', false, @islogical); % if relative_time is false, absolute time is used for labelling x-axis
p.parse(w, varargin{:});
w=p.Results.w;
s=p.Results.spectralobject;

% if ~class(s, 'spectralobject')
%     disp('Oops, you did not give a valid spectralobject. Using default')
    if numel(w)>1
        w = reshape(w, numel(w), 1);
    end
    
    
    [result,Tcell,Fcell,Ycell, meanf, peakf] = iceweb.spectrogram_iceweb(s, w, 'plot_metrics',p.Results.plot_metrics,'relative_time',p.Results.relative_time);
    
%     if p.Results.plot_metrics
%         [result,Tcell,Fcell,Ycell, meanf, peakf] = iceweb.spectrogram_iceweb(s, w, 'plot_metrics',1);
%     else
%         [result,Tcell,Fcell,Ycell, meanf, peakf] = iceweb.spectrogram_iceweb(s, w);
%     end
    
    
end
                

    
