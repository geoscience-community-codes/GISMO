function r=daily_rsam_plot(filepattern, snum, enum, ctag, measure)
    for c=1:numel(ctag)
        %r(c) = rsam.read_bob_file(filepattern, 'snum', snum, 'enum', enum, 'sta', ctag(c).station, 'chan', ctag(c).channel, 'measure', measure, 'units', 'Hz')
        r(c) = rsam.read_bob_file(filepattern, 'snum', snum, 'enum', enum, 'sta', ctag(c).station, 'chan', ctag(c).channel, 'measure', measure)
    end
    %r.plot_panels();
    r.plot()
end