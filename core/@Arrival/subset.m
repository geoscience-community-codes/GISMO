function self2 = subset(self, columnname, findval)
%SUBSET Subset Arrival object by index or matching column value

self2 = self;

if nargin == 2
    % direct index usage
    idx = columnname;
else
    N = height(self.table);
    idx = [];

    for i = 1:N
        val = self.table.(columnname)(i);

        if iscell(val)
            if strcmp(val, findval)
                idx(end+1) = i; %#ok<AGROW>
            end
        elseif isnumeric(val)
            if val == findval
                idx(end+1) = i; %#ok<AGROW>
            end
        end
    end
end

self2.table = self.table(idx,:);

if ~isempty(self.waveforms)
    self2.waveforms = self.waveforms(idx);
end
end
