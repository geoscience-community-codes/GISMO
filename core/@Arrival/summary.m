function summary(obj, showall)
%SUMMARY Display a compact summary of the Arrival object

if nargin < 2
    showall = false;
end

N = height(obj.table);
fprintf('Number of arrivals: %d\n', N);

if N == 0
    return
end

if N <= 50 || showall
    disp(obj.table)
else
    disp(obj.table(1:50,:))
    disp('* Only showing first 50 rows/arrivals')
end
end
