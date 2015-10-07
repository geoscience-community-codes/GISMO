function montserrat_remove_analog_sites
debug.printfunctionstack('>')
    load pf/Montserrat.mat
    sites = subnets.sites;
    k = 0;
    for c=1:numel(sites)
        site = sites(c);
        sta = site.channeltag.station;
        chan = site.channeltag.channel;
        if strcmp(sta(1:2),'MB') && chan(3)=='Z' && ~strcmp(sta,'MBET') && ~strcmp(sta,'MBUN') && ~strcmp(sta,'MB??')
            k = k + 1;
            goodsites(k) = site;
        end
    end
    subnets.sites = goodsites;
    clear c k goodsites sta sites site
    save pf/Montserrat.mat
debug.printfunctionstack('<')
end        
    
