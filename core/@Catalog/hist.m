function hist(catalogObject); 
    %HIST plot histograms of magnitude distribution, depth
    %distribution etc
    %   catalog_object.hist()

    mmin = min(catalogObject.mag);
    mmax = max(catalogObject.mag);
    bincenters = floor(mmin*10)/10 + 0.05 : 0.1 : floor(mmax*10)/10 + 0.05;
    hist(catalogObject.mag, bincenters);

end