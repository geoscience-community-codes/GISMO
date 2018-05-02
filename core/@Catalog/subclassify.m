%% SUBCLASSIFY
function c = subclassify(catalogObject, subclasses)
    % CATALOG.SUBCLASSIFY Split catalogObject into multiple
    % catalogObjects where each one contains only a single etype
    % (event type). THIS NEED CHANGING BECAUSE ETYPE IS NOW A CELL
    % ARRAY OF STRINGS

    %catalogObjects = subclassify(catalogObject, subclasses)
    if strcmp(subclasses, '*')==0
        for i = 1:length(subclasses);
            c(i) = catalogObject;
            subclass{i} = subclasses(i);
            index = strfind(char(catalogObject.etype)', subclass{i}); % previously findstr
            if length(index)>0
                c(i) = catalogObject.subset('indices',index);
            else
                c(i) = Catalog();
            end
            c(i).request = catalogObject.request;
            c(i).request.subclass = subclass{i};
        end
    end     
end

