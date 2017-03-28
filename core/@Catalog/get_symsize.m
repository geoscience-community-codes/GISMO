function symsize = get_symsize(catalogObject)
    %get_symsize Get symbol marker size based on magnitude of event
    % Compute Marker Size
    minsymsize = 3;
    maxsymsize = 50;
    symsize = (catalogObject.mag + 2) * 10; % -2- -> 1, 1 -> 10, 0 -> 20, 1 -> 30, 2-> 40, 3+ -> 50 etc.
    symsize(symsize<minsymsize)=minsymsize;
    symsize(symsize>maxsymsize)=maxsymsize;
    % deal with NULL (NaN) values
    symsize(isnan(symsize))=minsymsize;
end