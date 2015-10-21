%SACPZ Class for reading SAC pole-zero files downloaded from IRIS
classdef sacpz
	properties
		z = [];
		p = [];
		k = [];
        starttime = NaN;
        endtime = NaN;
        network = '';
        station = '';
        location = '';
        channel = '';
        latitude = NaN;
        longitude = NaN;
        depth = NaN;
        elevation = NaN;
        dip = NaN;
        azimuth = NaN;
        samplerate = NaN;
        description = '';
        inputunit = '';
        outputunit = '';
        instrumenttype = '';
        instrumentgain = '';
        instrumentgainunits = '';
        sensitivity = '';
        sensitivityunits = '';
        a0 = NaN;
	end
	methods
		function obj = sacpz(fileContents)
		%sacpz.sacpz Constructor for sacpz
        % sacpz(fileContents)
        % Examples:
        % 1. Read a sacpz file:
        %     pz = sacpz(fileread('SACPZ.IU.COLA.BHZ'))
        % 2. Read from a webservices URL (SCAFFOLD: code can only handle 1 time period / channel currently)
        %     pz = sacpz(webread('http://service.iris.edu/irisws/sacpz/1/query?net=AV&sta=OKSO&loc=--&cha=BHZ&starttime=2011-03-21T00:00:00'))
			obj.z = []; obj.p = []; obj.k = NaN;
            tic
            lines = strread(fileContents, '%s', 'delimiter', sprintf('\n'));
            c = 1;
			while c <= numel(lines),
                thisline = lines{c};
                disp(thisline)
				if (numel(thisline)>0 & thisline(1)=='*')
                    if strfind(thisline, 'NETWORK');
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        obj.network = sscanf(thisline, '%s', 1);
                    elseif strfind(thisline, 'STATION');
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        obj.station = sscanf(thisline, '%s', 1);
                    elseif strfind(thisline, 'LOCATION')  ;  
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        obj.location = sscanf(thisline, '%s', 1);
                    elseif strfind(thisline, 'CHANNEL')  ;
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        obj.channel = sscanf(thisline, '%s', 1);                        
                    elseif strfind(thisline, 'START')  ;
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        obj.starttime = datenum(sscanf(thisline, '%s', 1),'yyyy-mm-dd');
                    elseif strfind(thisline, 'END')  ;
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        obj.endtime = datenum(sscanf(thisline, '%s', 1), 'yyyy-mm-dd'); 
                    elseif strfind(thisline, 'DESCRIPTION') ; 
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        obj.description = thisline;
                    elseif strfind(thisline, 'LATITUDE')  ;
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        obj.latitude = sscanf(thisline, '%f', 1); 
                    elseif strfind(thisline, 'LONGITUDE')  ;
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        obj.longitude = sscanf(thisline, '%f', 1);                         
                    elseif strfind(thisline, 'ELEVATION')  ;
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        obj.elevation = sscanf(thisline, '%f', 1);
                    elseif strfind(thisline, 'DEPTH') ; 
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        obj.elevation = sscanf(thisline, '%f', 1)                        
                    elseif strfind(thisline, 'DIP')  ;
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        obj.dip = sscanf(thisline, '%f', 1);                        
                    elseif strfind(thisline, 'AZIMUTH')  ;
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        obj.azimuth = sscanf(thisline, '%f', 1);                        
                    elseif strfind(thisline, 'SAMPLE RATE')  ;
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        obj.samplerate = sscanf(thisline, '%f', 1); 
                    elseif strfind(thisline, 'INPUT UNIT')  ;
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        obj.inputunit = sscanf(thisline, '%s', 1); 
                    elseif strfind(thisline, 'OUTPUT UNIT')  ;
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        obj.outputunit = sscanf(thisline, '%s', 1);   
                    elseif strfind(thisline, 'INSTTYPE')  ;
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        obj.instrumenttype = thisline;
                    elseif strfind(thisline, 'INSTGAIN')  ;
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        tmpfields = strread(thisline, '%s', 'delimiter', ' ');
                        obj.instrumentgain = sscanf(tmpfields{1}, '%e', 1);
                        obj.instrumentgainunits = tmpfields{2};
                        clear tmpfields
                    elseif strfind(thisline, 'SENSITIVITY')  ;
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        tmpfields = strread(thisline, '%s', 'delimiter', ' ');
                        obj.sensitivity = sscanf(tmpfields{1}, '%e', 1);
                        obj.sensitivityunits = tmpfields{2};
                        clear tmpfields
                    elseif strfind(thisline, 'A0')  ;
                        idx = strfind(thisline,':');
                        thisline = strtrim(thisline(idx+1:end));
                        obj.a0 = sscanf(thisline, '%f', 1);   
                    end
                    c = c + 1;
					continue
                end
				if strfind(thisline,'ZEROS')
                    thisline = strrep(thisline, 'ZEROS', '');
                    numzeros = sscanf(thisline, '%d', 1);
                    for zidx = 1:numzeros
                        c = c + 1;
                        thisline = lines{c};
                        a = sscanf(thisline,'%e',2);
                        obj.z(zidx, 1) = a(1) + 1j*a(2);
                    end
                end
				if strfind(thisline,'POLES')
                    thisline = strrep(thisline, 'POLES', '');
                    numpoles = sscanf(thisline, '%d', 1);
                    for pidx = 1:numpoles
                        c = c + 1;
                        thisline = lines{c};
                        a = sscanf(thisline,'%e',2);
                        obj.p(pidx, 1) = a(1) + 1j*a(2);
                    end
                end
				if strfind(thisline,'CONSTANT')
                    thisline = strrep(thisline, 'CONSTANT', '');
					obj.k = sscanf(thisline, '%f',1);
                end
                c = c + 1;
            end
            toc
		end

        %% -----------------------------------------------
		function plot(obj)
            %sacpz.plot() Plot poles & zeros, impulse response & frequency
            %response
            
            % Poles (x) & zeros (o) plot with unit circle
            figure(1)
            zplane(obj.z, obj.p)
            
            % Impulse response 
            figure(2)
            sos = zp2sos(obj.z, obj.p, obj.k);
            impz(sos)
            
            % Frequency response
            figure(3)
            freqz(sos)
            
            % Filter visualization GUI
            %fvtool(sos)
        end
        %% -----------------------------------------------
        function response = to_response_structure(obj, frequencies)
            %sacpz.to_response_structure(frequencies) Create response
            %structure from sacpz object
        
            % INITIALIZE THE OUTPUT ARGUMENT
            response.scnl = scnlobject(obj.station,obj.channel,obj.network,obj.location);
            response.time = obj.starttime;
            response.frequencies = reshape(frequencies,numel(frequencies),1);
            response.values = [];
            response.calib = NaN;
            response.units = obj.outputunit;
            response.sampleRate = obj.samplerate;
            response.source = 'FUNCTION: RESPONSE_GET_FROM_POLEZERO';
            response.status = [];


            % Pole/zeros can be normalized with the following if not already normalized:
            normalization = 1/abs(polyval(poly(obj.z),2*pi*1j)/polyval(poly(obj.p),2*pi*1j));


            % CALCULATE COMPLEX RESPONSE AT SPECIFIED FREQUENCIES USING
            % LAPLACE TRANSFORM FUNCTION freqs
            ws = (2*pi) .* response.frequencies;
            response.values = freqs(normalization*poly(obj.z),poly(obj.p),ws);

        end
	end
end





