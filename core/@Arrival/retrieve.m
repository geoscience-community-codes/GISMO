function self = retrieve(dataformat, varargin)
%RETRIEVE Static loader for Arrival objects

debug.printfunctionstack('>')

self = Arrival();   % always return a valid object

switch lower(dataformat)

    case {'css3.0','antelope','datascope'}

        if admin.antelope_exists()
            try
                tmp = Arrival.read_antelope(varargin{:});
                if ~isempty(tmp)
                    self = tmp;
                else
                    warning('No arrivals returned from Antelope')
                end
            catch ME
                warning('Arrival.retrieve:antelopeFailed', ...
                    'Antelope load failed: %s', ME.message);
            end
        else
            warning('Antelope toolbox not found')
        end

    case 'hypoellipse'
        try
            self = Arrival.readphafile(varargin{:});
        catch ME
            warning('Arrival.retrieve:hypoellipseFailed', ...
                'Hypoellipse read failed: %s', ME.message);
        end

    otherwise
        warning

