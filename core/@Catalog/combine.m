function catalogObject = combine(catalogObject1, catalogObject2)
    %CATALOG.COMBINE combine two Catalog objects
    % catalogObject = COMBINE(catalogObject1, catalogObject2)

    catalogObject = [];

    if nargin<2
        help Catalog.combine
        return
    end

    catalogObject = catalogObject1;

    catalogObject.table = union(catalogObject1.table, catalogObject2.table);

end