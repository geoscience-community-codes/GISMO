function handlePlot = plot(rsam_vector, varargin)
    % RSAM/PLOT plot rsam data
    % handle = plot(rsam_vector, varargin)
    % Properties include:
    %   yaxistype, h, addgrid, addlegend, fillbelow, plotspikes, plottransients, plottremor
    % to change where the legend plots set the global variable legend_ypos
    % a positive value will be within the axes, a negative value will be below
    % default is -0.2. For within the axes, log(20) is a reasonable value.
    % yaxistype is like 'logarithmic' or 'linear'
    % h is an axes handle (or an array of axes handles)
    % use h = generatePanelHandles(numgraphs)

    % Glenn Thompson 1998-2009
    %
    % % GTHO 2009/10/26 Changed marker size from 5.0 to 1.0
    % % GTHO 2009/10/26 Changed legend position to -0.2
    
    w = rsam2waveform(rsam_vector);
    plot_panels(w)
end

