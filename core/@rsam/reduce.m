function self = reduce(self, waveType, sourcelat, sourcelon, stationlat, stationlon, varargin)
    % s.reduce('waveType', 'surface', 'waveSpeed', 2000, 'f', 2.0, );
    % s.distance and waveSpeed assumed to be in metres (m)
    % (INPUT) s.data assumed to be in nm or Pa
    % (OUTPUT) s.data in cm^2 or Pa.m
    p = inputParser;
    p.addParameter('waveSpeed', 2000);
    p.addParamter('f', 2.0);
    p.parse(varargin{:});

    self.reduced.waveSpeed = p.Results.waveSpeed;

    if self.reduced.isReduced
        disp('Data are already reduced');
        return;
    end

    self.reduced.distance = deg2km(distance(sourcelat, sourcelon, stationlat, stationlon)) *1000; % m

    switch self.units
        case 'nm'  % Displacement
            % Do computation in cm
            self.data = self.data / 1e7;
            r = self.reduced.distance * 100; % cm
            ws = waveSpeed * 100; % cm/2
            self.measure = sprintf('%sR%s',self.measure(1),self.measure(2:end));
            switch self.reduced.waveType
                case 'body'
                    self.data = self.data * r; % cm^2
                    self.units = 'cm^2';
                case 'surface'
                    wavelength = ws / p.Results.f; % cm
                    try
                            self.data = self.data .* sqrt(r * wavelength); % cm^2
                    catch
                            debug.print_debug(5, 'mean wavelength instead')
                            self.data = self.data * sqrt(r * mean(wavelength)); % cm^2            
                    end
                    self.units = 'cm^2';
                    self.reduced.isReduced = true;
                otherwise
                    error(sprintf('Wave type %s not recognised'), self.reduced.waveType); 
            end
        case 'Pa'  % Pressure
            % Do computation in metres
            self.data = self.data * self.reduced.distance; % Pa.m    
            self.units = 'Pa m';
            self.reduced.isReduced = true;
            self.measure = sprintf('%sR%s',self.measure(1),self.measure(2:end));
        otherwise
            error(sprintf('Units %s for measure %s not recognised', self.units, self.measure));
    end
    self.reduced.sourcelat = sourcelat;
    self.reduced.sourcelon = sourcelon;
    self.reduced.stationlat = stationlat;
    self.reduced.stationlon = stationlon;

end