%% SUBCLASSIFY
function c = subclassify(catalogObject, subclasses)
    % CATALOG.SUBCLASSIFY Split catalogObject into multiple
    % catalogObjects where each one contains only a single etype
    % (event type). THIS NEED CHANGING BECAUSE ETYPE IS NOW A CELL
    % ARRAY OF STRINGS

    catalogObjects = subclassify(catalogObject, subclasses)
    if strcmp(subclasses, '*')==0
        for i = 1:length(subclasses);
            c(i) = catalogObject;
            subclass = subclasses(i);
            index = strfind(catalogObject.etype, subclass); % previously findstr
            if numel(catalogObject.lat)==numel(catalogObject.etype)
                c(i).lat = catalogObject.lat(index);
                c(i).lon = catalogObject.lon(index);
                c(i).depth = catalogObject.depth(index);
            end
            c(i).otime = catalogObject.otime(index);
            c(i).mag = catalogObject.mag(index);
            c(i).etype = catalogObject.etype(index);
        end
    end     
end

