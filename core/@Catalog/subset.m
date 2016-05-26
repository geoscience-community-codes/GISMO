function catalogObject2 = subset(catalogObject, indices)
    %CATALOG.SUBSET Create a new catalogObject by subsetting based
    %on indices. 
    catalogObject2 = Catalog(catalogObject.table(indices,:));
end