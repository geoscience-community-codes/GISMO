%% GET
function val = get(obj,prop_name)
    %GET Get EventRate properties
    %   val = get(EventRate_object,'property_name')
    %
    %   To see valid property names, type:
    %       properties(EventRate_object)
    %
    %       If additional fields were added to EventRate using ADDFIELD, then
    %       values from these can be retrieved using the fieldname
    %
    %   See also EventRate/SET, EventRate/ADDFIELD, Catalog/GET

    mask = strcmp(prop_name, properties(obj));
    if any(mask)
        % eval(sprintf('val=obj.%s;',prop_name));
        val = obj.(prop_name);
    else
        mask = strcmp(upper(prop_name),obj.misc_fields);
        if any(mask)
            val = obj.misc_values{mask};
        else
            warning('%s:get:unrecognizedProperty',...
                'Unrecognized property name : %s',  class(obj), prop_name);
        end
    end
end