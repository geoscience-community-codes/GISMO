function r=daily_rsam_plot(filepattern, snum, enum, ctag, measure)

    fprintf('RSAM plot from %s to %s\n',datestr(snum),datestr(enum))
    ymax=[];ymin=[];
    cc = 0;
    for c=1:numel(ctag)
        disp(ctag)
        if strcmp(ctag(c).channel, 'HHZ')
            cc = cc + 1;
            r(cc) = rsam.read_bob_file(filepattern, 'snum', snum, 'enum', enum, 'sta', ctag(c).station, 'chan', ctag(c).channel, 'measure', measure);
            ymax(cc) = prctile(r(cc).data, 99.9);
            ymin(cc) = prctile(r(cc).data, 0.01);
            r(cc) = r(cc).medfilt1(10);
        end
    end
    %r.plot('yaxistype','logarithmic');
    if ~isempty(ymax) & ~isnan(ymax(1))
        r.plot('yaxistype','linear'); 
        set(gca,'YLim',[min(ymin) max(ymax)]);
    end
end