function rsamobj = loadbobfile(infile, snum, enum)
    % LOADBOBFILE Load an RSAM binary file
    % Usage:
    %   self = loadbobfile(infile, snum, enum)
    % Example:
    rsamobj = rsam();
    if nargin<3
        help rsam/loadbobfile
        warning('Not enough input parameters')
        return
    end
    f = struct;
    f.file = infile;
    f.found = false;
    f.snum = snum;
    f.enum = enum;

    if exist(infile,'file')
        f.found = true;
    end
    
    [dirname,basename] = fileparts(infile);
    if length(basename)==8
        rsamobj.sta = basename(1:4);
    end
    
    rsamobj.files = f;
    rsamobj = load(rsamobj); 
    rsamobj.snum = snum;
    rsamobj.enum = enum;
end