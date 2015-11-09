function plot_counts(catalogObject)
    %CATALOG.PLOT_COUNTS Plot event counts - i.e. number of events
    %per unit time. See also the EventRate class.
    erobj = catalogObject.eventrate();
    erobj.plot()
end
         