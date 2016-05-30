function [ output_args ] = plot_helicorder( w, varargin )
%WAVEFORM/PLOT_HELICORDER Plot waveform objects as helicorders
%   Each waveform object is plotted as a separate helicorder plot using the
%   drumplot class

% Glenn Thompson 20160513
    for c=1:numel(w)
        h = drumplot(demean(w(c)), varargin{:});
        plot(h);
    end
end

