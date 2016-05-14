function self = iris(ev)
    %READ_CATALOG.IRIS
    % convert an events structure from irisfetch into an Catalog object
    
    debug.printfunctionstack('>')
  
    for i=1:length(ev) % Loop over each element in vector

        otime(i) = datenum(ev(i).PreferredTime);
        lon(i) = ev(i).PreferredLongitude;
        lat(i) = ev(i).PreferredLatitude;
        depth(i) = ev(i).PreferredDepth;
        
        if ~isnan(ev(i).PreferredMagnitudeValue)
            mag(i) = ev(i).PreferredMagnitude.Value;
            magtype{i} = ev(i).PreferredMagnitude.Type;
        else
            mag(i) = NaN;
            magtype{i} = '';
        end
        
        etype{i} = ev(i).Type;

    end
    
    request.dataformat = 'iris';
    self = Catalog(otime', lon', lat', depth', mag', magtype', etype', 'request', request);
    
    debug.printfunctionstack('<')
    
end
