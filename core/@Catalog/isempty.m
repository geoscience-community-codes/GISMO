function bool=isempty(cobj)
    if isempty(cobj.otime)
        bool=true;
    else
        bool=false;
    end
end