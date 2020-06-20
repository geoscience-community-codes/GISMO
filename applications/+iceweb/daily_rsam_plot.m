function r=daily_rsam_plot(filepattern, snum, enum, ctag, measure)
    fprintf('RSAM plot from %s to %s\n',datestr(snum),datestr(enum))
    for c=1:numel(ctag)
        r(c) = rsam.read_bob_file(filepattern, 'snum', snum, 'enum', enum, 'sta', ctag(c).station, 'chan', ctag(c).channel, 'measure', measure);
    end
    r.plot('yaxistype','logarithmic'); 
end