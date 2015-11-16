function disp(obj, showall)
% ARRIVAL.DISP Display Arrival object
% properties(obj)
% methods(obj)
format long
    fprintf('Number of arrivals: %d\n',obj.numberOfArrivals);
    if ~exist('showall','var')
        showall = false;
    end
    if height(obj.table) <= 50 || showall
        disp(obj.table)
    else
        disp(obj.table([1:50],:))

        disp('* Only showing first 50 rows/arrivals - to see all rows/arrivals use:')
        disp('*      Arrivals.disp(true)')
    end
    format short
end