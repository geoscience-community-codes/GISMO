%SACPZ Class for reading SAC pole-zero files downloaded from IRIS
classdef sacpz
	properties
		z = [];
		p = [];
		k = [];
      created = NaN;
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
        comment = '';
        sensitivity = '';
        sensitivityunits = '';
        a0 = NaN;
	end
	methods
      function s = sacpz(filename)
         %sacpz.sacpz Constructor for sacpz
         % pz = sacpz(fileContents)
         % pz = sacpz(webpage)  %defined by 'http://...'
         % pz = sacpz(file)
         %
         % will return one sacpz object for each epoch in file
         
         % Examples:
         % 1. Read a sacpz file:
         %     pz = sacpz(fileread('SACPZ.IU.COLA.BHZ'))
         % 2. Read from a webservices URL (SCAFFOLD: code can only handle 1 time period / channel currently)
         %     pz = sacpz(webread('http://service.iris.edu/irisws/sacpz/1/query?net=AV&sta=OKSO&loc=--&cha=BHZ&starttime=2011-03-21T00:00:00'))
         
         if nargin == 0
            return;
         end
         % read file into variable for later processing
         if length(filename)>7 && strncmpi(filename,'http://',7)
            fcontents = webread(filename);
         elseif exist(filename,'file')
            fcontents = fileread(filename);
         else
            fcontents = filename;
         end
         
         if isempty(fcontents)
            return;
         end
         
         s = s.new_readroutine(fcontents);
         
      end
      
      function obj = new_readroutine(obj, fileContents)
         persistent fieldmap
         if isempty(fieldmap)
            fieldmap = getFieldmap();
         end
         
         % SACPZ file may contain multiple epochs
         epochs = splitEpochs(fileContents);
         
         for N = 1 : numel(epochs)
            [obj(N).p, obj(N).z, obj(N).k] = parsePZC(responsePart(epochs(N)));
            
            H = getHeaderLines(epochs(N));
            
            [hFields, hValues] = cellfun(@parseHeaderLine, H, 'UniformOutput', false);
            
            for M = 1:numel(hFields)
               f = hFields{M};
               % convert
               switch f
                  case {'START','END', 'CREATED'}
                     v = datenum(hValues{M},'yyyy-mm-ddTHH:MM:SS');
                     
                  case {'LONGITUDE','LATITUDE','ELEVATION',...
                        'DEPTH','DIP','AZIMUTH','SAMPLE RATE','A0'}
                     v = str2double(hValues{M});
                     
                  case {'INSTGAIN', 'SENSITIVITY'}
                     [v, units] = splitOffUnits(hValues{M});
                     unitfield = [f, 'UNITS'];
                     obj(N).(fieldmap(unitfield)) = units;
                     
                  otherwise
                     v = hValues{M};
               end
               
               if fieldmap.isKey(f)
                  obj(N).(fieldmap(f)) = v;
               else
                  error('%s is not a known key', f);
               end
            end
         end
         
         function [val, unit] = splitOffUnits(val)
            % splitOffUnits    adds units field in obj and returns numeric measurement
            % For use in sacpz lines such as:
            %  SENSITIVITY       : 8.485070e+08 (M/S)
            if isempty(val)
               unit = '';
               return;
            end
            tmp = textscan(val,'%f %s');
            val = tmp{1};
            if ~isempty(tmp{2})
               unit = tmp{2}{1};
            else
               unit = '';
            end
         end
         
         function  X = splitEpochs(multipleEpochs)
            % splitEpochs   returns cell for each epoch
            % divisions between epochs are represented in the SACPZ file as
            % multiple blank lines.
            % Each epoch starts with a line of asterisks
            % '* **********[...]'
            X = strsplit(multipleEpochs,'\n\n\n');
            X(cellfun(@isempty,X)) = [];
            isLikelyEpoch = cellfun(@(x) strncmp('* **',x,4'),X);
            X(~isLikelyEpoch) = [];
         end
         
         function PZC = responsePart(t)
            % the response follows the last asterisk in the epoch.
            splitPoint = find(t{1}=='*',1, 'last');
            PZC = t{1}(splitPoint+1:end);
         end
            
         function tLines = getHeaderLines(t)
            % getHeaderLines   returns header as cell of 1 line/variable
            
            % grab only header
            splitPoint = find(t{1}=='*',1, 'last');
            t = t{1}(1:splitPoint);
            
            % remove extraneous asterisks
            t(t=='*') = '';
            
            % split header into individual lines
            tLines = textscan(t,'%s','delimiter','\n');
            
            %tidy up
            tLines = strtrim(tLines{:});
            tLines(cellfun(@isempty,tLines)) = [];
         end
                     
         function [field, val] = parseHeaderLine(t)
            % expects FIELDNAME   (maybesomething) :  VALUE
            colLoc = find(t==':',1,'first');
            if colLoc
               field = t(1:colLoc-1);
               val = strtrim(t(colLoc+1:end));
            else
               field=''; val = ''; %error parsing!
            end
            parenLoc = find(field =='(',1,'first');
            if parenLoc
               field = field(1:parenLoc-1);
            end
            field = strtrim(field);
         end
         
         function [p, z, c] = parsePZC(t)
            lines = textscan(t,'%s','delimiter','\n');
            lines = lines{:};
            
            z = getComplex('ZEROS', lines);
            p = getComplex('POLES', lines);
            
            ConstHeader= strncmp('CONSTANT',lines,8);
            
            if any(ConstHeader)
               c = str2double(lines{ConstHeader}(9:end));
            else
               c = NaN;
            end
         end
         
         function x = getComplex(fName, lines)
            x = [];
            fLen = length(fName);
            header = find(strncmp(fName, lines, fLen));
            if ~isempty(header)
               nValues = str2double(lines{header}((fLen+1):end));
               for q = 1 : nValues
                  vals = str2num(lines{header + q});
                  x(q,1) = vals(1) + vals(2) * 1i;
               end
            end
         end
         
         function M = getFieldmap()
            % getFieldmap  maps SACPZ text headers to sacpz object fields
            M = containers.Map('KeyType', 'char', 'ValueType', 'char') ;
            M('NETWORK') = 'network';
            M('STATION') = 'station';
            M('LOCATION') = 'location';
            M('CHANNEL') = 'channel';
            M('CREATED') = 'created';
            M('START') = 'starttime';
            M('END')='endtime';
            M('DESCRIPTION') = 'description';
            M('LATITUDE') = 'latitude';
            M('LONGITUDE') = 'longitude';
            M('ELEVATION') = 'elevation';
            M('DEPTH') = 'depth';
            M('DIP') = 'dip';
            M('AZIMUTH') = 'azimuth';
            M('SAMPLE RATE') = 'samplerate';
            M('INPUT UNIT') = 'inputunit';
            M('OUTPUT UNIT') = 'outputunit';
            M('INSTTYPE') = 'instrumenttype';
            M('INSTGAIN') = 'instrumentgain';
            M('INSTGAINUNITS') = 'instrumentgainunits';
            M('SENSITIVITY') = 'sensitivity';
            M('SENSITIVITYUNITS') = 'sensitivityunits';
            M('COMMENT') = 'comment';
            M('A0') = 'a0';
         end
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
        
        function [num,den] = transfer(obj)
            % sacpz.transfer Compute the numerator and denominator of the
            % transfer function with the zeros and poles given in a sacpz
            % object.
            [num,den] = zp2tf(obj.z, obj.p, obj.k);
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



%{
Notes about the format of a SACPZ file:
- header information surrounded by lines of '*'
- Each header field starts with '*'
- Some header fields include a second variable name eg. '(KNETWK)'
  + these fields are surrounded by parenthesis 
- Header values follow ':'
- INSTGAIN and SENSITIVITY have (or may not have) 2 value & unit
- CREATED, START, END all are dates

- Header is followed by list of Poles, Zeros, and Constant.
  + Number of values for Poles & Zeros is listed on first line
  + Poles & Zeros are complex numbers
  + CONSTANT may or may not appear.

- Each epoch is separated by multiple spaces
%}

%{
<SAMPLE SACPZ FILE follows>
* **********************************
* NETWORK   (KNETWK): IU
* STATION    (KSTNM): ANMO
* LOCATION   (KHOLE): 00
* CHANNEL   (KCMPNM): BH1
* CREATED           : 2016-01-04T11:50:14
* START             : 1998-10-26T20:00:00
* END               : 2000-10-19T16:00:00
* DESCRIPTION       : Albuquerque, New Mexico, USA
* LATITUDE          : 34.945900
* LONGITUDE         : -106.457200
* ELEVATION         : 1700.0
* DEPTH             : 150.0
* DIP               : 90.0
* AZIMUTH           : 280.0
* SAMPLE RATE       : 20.0
* INPUT UNIT        : M
* OUTPUT UNIT       : COUNTS
* INSTTYPE          : Geotech KS-54000 Borehole Seismometer
* INSTGAIN          : 2.023580e+03 (M/S)
* COMMENT           : orientation changed 1997,099
* SENSITIVITY       : 8.485070e+08 (M/S)
* A0                : 8.608300e+04
* **********************************
ZEROS	3
	+0.000000e+00	+0.000000e+00	
	+0.000000e+00	+0.000000e+00	
	+0.000000e+00	+0.000000e+00	
POLES	5
	-5.943130e+01	+0.000000e+00	
	-2.271210e+01	+2.710650e+01	
	-2.271210e+01	-2.710650e+01	
	-4.800400e-03	+0.000000e+00	
	-7.319900e-02	+0.000000e+00	
CONSTANT	7.304203e+13


* **********************************
* NETWORK   (KNETWK): IU
<ETC>
%}

