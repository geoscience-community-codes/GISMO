function goodsites = get_channeltags_active(sites, snum)
   % get_channeltags_active   return sites that were active on a date
    % sites active for this day
    k=0;
    %goodsites = [];
    for c=1:numel(sites)
        if sites(c).ondnum <= snum+1 && sites(c).offdnum >= snum
            k = k + 1;
            goodsites(k) = sites(c);
            disp(sprintf('Keeping %s',sites(c).channeltag.string()));
        else
            %datestr(snum+1),datestr(sites(c).ondnum)
            %datestr(snum),datestr(sites(c).offdnum)
            disp(sprintf('Rejecting %s',sites(c).channeltag.string()));
        end
    end
    if k==0
        goodsites = [];
    end
end
