function arrivalObject = combine(arrivalObject1, arrivalObject2)
    %CATALOG.COMBINE combine two Arrival objects
    % catalogObject = COMBINE(arrivalObject1, arrivalObject2)

    arrivalObject = [];

    if nargin<2
        help Arrival.combine
        return
    end

    arrivalObject = arrivalObject1;

    arrivalObject.table = union(arrivalObject1.table, arrivalObject2.table);
    %arrivalObject.table = [arrivalObject1.table; arrivalObject2.table]
    arrivalObject.table = sortrows(arrivalObject.table, 'datenum', 'ascend'); 
end