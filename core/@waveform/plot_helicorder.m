function plot_helicorder( w, varargin )
%WAVEFORM/PLOT_HELICORDER Plot waveform objects as helicorders
%   Each waveform object is plotted as a separate helicorder plot using the
%   drumplot class

% Glenn Thompson 20160513
    debug.printfunctionstack('>');
    
    for c=1:numel(w)
        %figure
        drumobj0 = drumplot(demean(w(c)), varargin{:})
        plot(drumobj0);
        pause(2)
    end
    debug.printfunctionstack('<');
end


