%% ADDFIELD
function obj = addfield(obj,fieldname,val)
    %ADDFIELD add fields and values to object(s) 
    %   obj = addfield(obj, fieldname, value)
    %   This function creates a new user defined field, and fills it with the
    %   included value.  If fieldname exists, it will overwrite the existing
    %   value.
    %
    %   Input Arguments
    %       obj: an EventRate object
    %       fieldname: a string name
    %       value: a value to be added for those fields.  Value can be anything
    %
    %   EventRate objects can hold user-defined fields.  To access the contents, 
    %   use EventRate/get.
    %
    %   Example:
    %       % add a field called "TESTFIELD", containing the numbers 1-45
    %       obj = addfield(obj,'TestField',1:45);
    %
    %       % add a cell field called "MISHMOSH"
    %       obj = addfield(obj,'mishmosh',{'hello';'world'});
    %
    %       % see the result
    %       disp(obj) 
    %
    % See also EventRate/set, EventRate/get

    % AUTHOR: Glenn Thompson

    if ischar(fieldname)
        mask = strcmp(fieldname, properties(obj));
        if any(mask)
            obj = obj.set(fieldname, val);
        else
            mask = strcmp(upper(fieldname),obj.misc_fields);
            if any(mask)
                obj = obj.set(fieldname, val);
            else
                obj.misc_fields = [obj.misc_fields, upper(fieldname)];
                obj = obj.set(upper(fieldname), val);
            end
        end   
    else
        error('%s:addfield:invalidFieldname','fieldname must be a string', class(catalogObject))
    end

end