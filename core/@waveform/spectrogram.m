function [Tcell, Fcell, Ycell, meanf, peakf] = spectrogram( w, varargin )
%SPECTROGRAM Plot an IceWeb-style spectrogram
% SPECTROGRAM(w) Creates an IceWeb style spectrogram by wrapping the
% function iceweb.spectrogram_iceweb(). By default it uses a window size of
% 1024 samples with 924 sample overlap. The upper frequency limit on the
% spectrogram defaults to the Nyquist frequency (if w is a vector of
% waveform objects, it will be the lowest Nyquist frequency). Spectral
% amplitude is converted to decibels (dB). 
%   
% To change the default window size, overlap, upper frequency limit and/or
% to fix the decibel range that the colormap corresponds to, a
% spectralobject must be created and passed as a name-value pair, e.g.
%   nfft = 512
%   noverlap = 412
%   fmax = 10
%   dbLims = [60 120]
%   s = SPECTRALOBJECT(nfft, noverlap, fmax, dbLims)
%   spectrogram(w, 'spectralobject', s)
%   
%   where [60 120] are the dB limits that correspond to the color map used.
%   If this is a blank vector, [], the spectrogram is autoscaled in absolute
%   amplitude, not plotted in dB with absolute dB limits.
%
%   spectrogram(w, 'plot_metrics', true) Will add frequency metrics computed
%   by the waveform/amplitude_spectrum function.
%
%   spectrogram(w, 'relative_time', true) Will use relative rather than
%   absolute time on the x-axis.
%
% For greater control, call
%   ICEWEB.SPECTROGRAM_ICEWEB() directly, or use the legacy codes 
%   SPECTRALOBJECT/SPECGRAM or SPECTRALOBJECT/SPECGRAM2. Note that
%   ICEWEB.SPECTROGRAM_ICEWEB() is significantly faster.

% Glenn Thompson 2016/05/19 to provide a simple, fast way to geenrate nice
% spectrograms without having to delve into specgram and specgram2
% Last modified 2021/05/04 in response to question by Jithin Murali
figure
nfft = 1024;
noverlap = 924;
fmax = min([get(w,'freq')])/2;
dbLims = []; % used to be [60 120] for IceWeb

p = inputParser;
p.addRequired('w');
p.addParameter('spectralobject', spectralobject(nfft, noverlap, fmax, dbLims));
p.addParameter('plot_metrics', false, @islogical);
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
                

    
