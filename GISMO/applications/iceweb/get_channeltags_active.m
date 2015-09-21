function goodsites = get_channeltags_active(sites, snum)
    % sites active for this day
    k=0;
    %goodsites = [];
    for c=1:numel(sites)
        if sites(c).ondnum <= snum+1 && sites(c).offdnum >= snum
            k = k + 1;
            goodsites(k) = sites(c);
            disp(sprintf('Keeping %s',sites(c).channeltag.string()));
%             sites(c).ondnum
%             sites(c).offdnum
%             snum
        else
            disp(sprintf('Rejecting %s',sites(c).channeltag.string()));
            sites(c).ondnum
            sites(c).offdnum
            snum
        end
    end
    if k==0
        goodsites = [];
    end
end
