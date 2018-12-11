function daily_rsam_plot(filepattern, snum, enum, ctag, measure)
    for c=1:numel(ctag)
        r(c) = rsam.read_bob_file(filepattern, 'snum', snum, 'enum', enum, 'sta', ctag(c).station, 'chan', ctag(c).channel, 'measure', measure, 'units', 'Hz')
    end
    r.plot_panels();
end