function cobj2 = subset(cobj, varargin)
    %CATALOG.SUBSET Create a new catalogObject by subsetting based
    %on indices. 
    % Usage:
    %   cobj.subset('indices', [])
    % or:
    %   cobj.subset('start_time', [], 'end_time', [])
    % can also just give one of start_time or end_time
    
    %if nargin>0
        % Parse required, optional and param-value pair arguments,
        % set default values, and add validation conditions
        p = inputParser;
        p.addParameter('start_time', [], @isnumeric) % positional
        p.addParameter('end_time', [], @isnumeric)
        p.addParameter('indices', [], @isnumeric)
        p.parse(varargin{:});
        fields = fieldnames(p.Results);
        for i=1:length(fields)
            field=fields{i};
            val = p.Results.(field);
            eval(sprintf('%s = val;',field));
        end
    %end
    
%     datestr(min(cobj.otime))
%     datestr(max(cobj.otime))
%     datestr(start_time)
%     datestr(end_time)

    if isempty(indices)
        i1 = 1:numel(cobj.otime);
        if start_time
            i1 = find(cobj.otime >= start_time);
            debug.print_debug(1,sprintf('Found %d events after %s',numel(i1), datestr(start_time)));
        end
        i2 = 1:numel(cobj.otime);
        if end_time
            i2 = find(cobj.otime <= end_time);
            debug.print_debug(1,sprintf('Found %d events before %s',numel(i1), datestr(end_time)));
        end
        indices = intersect(i1, i2);
    end    
    

    cobj2 = cobj;
    N = numel(cobj.otime);
    debug.print_debug(1,sprintf('Subsetting from %d events to %d events',N, numel(indices)));
    cobj2.otime = cobj.otime(indices);
    if numel(cobj.lon)==N
        cobj2.lon = cobj.lon(indices);
    end
    if numel(cobj.lat)==N
        cobj2.lat = cobj.lat(indices);
    end
    if numel(cobj.depth)==N
        cobj2.depth = cobj.depth(indices);
    end
    if numel(cobj.mag)==N
        cobj2.mag = cobj.mag(indices);
    end
    if numel(cobj.magtype)==N
        dummy=[];
%         try % there is a limit on subsetting cell array
%         cobj2.magtype = cobj.magtype{indices};
%         end
        for c=1:numel(indices)
            dummy{c} = cobj.magtype{indices(c)};
        end
        cobj2.magtype = dummy;
        clear dummy
    end
    if numel(cobj.etype)==N
        dummy=[];
        for c=1:numel(indices)
            dummy{c} = cobj.etype{indices(c)};
        end
        cobj2.etype = dummy;
        clear dummy;
    end
    if numel(cobj.arrivals)==N
        cobj2.arrivals = cobj.arrivals(indices);
    end
    if numel(cobj.waveforms)==N
        cobj2.waveforms = cobj.waveforms(indices);
%         counter = 1;
%         indices
%         for thisindex=indices
%             cobj2.waveforms{counter} = cobj.waveforms{thisindex};
%             counter = counter + 1;
%         end
    end
    if numel(cobj.ontime)==N
        cobj2.ontime = cobj.ontime(indices);
    end
    if numel(cobj.offtime)==N
        cobj2.offtime = cobj.offtime(indices);
    end 
    
    %% Added by Glenn Thompson 2018-05-01 to add a request start & end time
    if isempty(start_time)
        cobj2.request.start_time = min(cobj2.otime);
    else
        cobj2.request.start_time = start_time;
    end
    if isempty(end_time)
        cobj2.request.end_time = max(cobj2.otime);
    else
        cobj2.request.end_time = end_time;
    end    
    
    
end