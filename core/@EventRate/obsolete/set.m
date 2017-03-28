%% SET
function obj = set(obj, varargin)
    %SET Set properties for EventRate object(s)
    %   obj = set(obj,'property_name', val, ['property_name2', val2])
    %   SET is one of the two gateway functions of an object, such as EventRate.
    %   Properties that are changed through SET are typechecked and otherwise
    %   scrutinized before being stored within the EventRate object.  This
    %   ensures that the other EventRate methods are all retrieving valid data,
    %   thereby increasing the reliability of the code.
    %
    %   Another strong advantage to using SET and GET to change and retrieve
    %   properties, rather than just assigning them to EventRate object directly,
    %   is that the underlying data structure can change and grow without
    %   harming the code that is written based on the EventRate object.
    %
    %   For a list of valid property names, type:
    %       properties(obj)
    %   
    %   If user-defined fields were added to the EventRate object (ie, through
    %   addField), these fieldnames are also available through set.
    %
    %   Examples:
    %       (1) Change the description property
    %           obj = obj.set('description','hello world');
    %
    %       (2) Add new a field called CLOSEST_STATION with
    %           % the value 'MBLG'
    %           obj = obj.addfield('CLOSEST_STATION','MBLG');
    %
    %           % change the value of the CLOSEST_STATION field
    %           obj = obj.set('CLOSEST_STATION','MBWH');
    %
    %  See also EventRate/get, EventRate/addfield

    Vidx = 1 : numel(varargin);

    while numel(Vidx) >= 2
        prop_name = upper(varargin{Vidx(1)});
        val = varargin{Vidx(2)};
        mask = strcmp(upper(prop_name),upper(properties(obj)));
        if any(mask)
            mc = metaclass(obj);
            i = find(mask);
            prop_name = mc.PropertyList(i).Name;
            if isempty(mc.PropertyList(i).GetMethod)
                %eval(sprintf('obj.%s=val;',prop_name));
                obj.(prop_name) = val;
            else
                warning('Property %s is a derived property and cannot be set',prop_name);
            end
        else
            switch prop_name
                case obj.misc_fields
                    mask = strcmp(prop_name,obj.misc_fields);
                    obj.misc_values(mask) = {val};
                otherwise
                    error('%s:set:unknownProperty',...
                        'can''t understand property name : %s', mfilename,prop_name);
            end
        end
        Vidx(1:2) = []; %done with those parameters, move to the next ones...
    end 
end 