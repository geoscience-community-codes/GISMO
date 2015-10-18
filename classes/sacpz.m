classdef sacpz
	properties
		z = [];
		p = [];
		k = [];
		% could also read things like channel, starttime, endtime, latitude, longitude, description=station name, elevation, depth, sample rate, input unit, output unit, insttype, instgain, sensitivity, A0
	end
	methods
		function obj = sacpz(sacpzfile)
		%sacpz.sacpz Constructor for sacpz
        % sacpz(sacpzfile)
			obj.z = []; obj.p = []; obj.k = NaN;
			if ~exist(sacpzfile, 'file')
				warning(sprintf('File not found %s',sacpzfile))
			end
			fin = fopen(sacpzfile,'r');
			thisline = fgetl(fin);
			while ischar(thisline),
				if (numel(thisline)>0 & thisline(1)=='*')
                    thisline = fgetl(fin);
					continue
                end
				if strfind(thisline,'ZEROS')
                    thisline = strrep(thisline, 'ZEROS', '');
                    numzeros = sscanf(thisline, '%d', 1);
                    for zidx = 1:numzeros
                        thisline = fgetl(fin);
                        a = sscanf(thisline,'%e',2);
                        obj.z(zidx, 1) = a(1) + 1j*a(2);
                    end
                end
				if strfind(thisline,'POLES')
                    thisline = strrep(thisline, 'POLES', '');
                    numpoles = sscanf(thisline, '%d', 1);
                    for pidx = 1:numpoles
                        thisline = fgetl(fin);
                        a = sscanf(thisline,'%e',2);
                        obj.p(pidx, 1) = a(1) + 1j*a(2);
                    end
                end
				if strfind(thisline,'CONSTANT')
                    thisline = strrep(thisline, 'CONSTANT', '');
					obj.k = sscanf(thisline, '%f',1);
                end
                thisline = fgetl(fin);
			end
			fclose(fin);
		end

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
	end
end





