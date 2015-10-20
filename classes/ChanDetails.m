classdef ChanDetails
   %UNTITLED Summary of this class goes here
   %   Detailed explanation goes here
   
   properties
      channeltag
      lat
      lon
      elev
      depth
      azimuth
      dip
      sensordescription
      scale
      scalefreq
      scaleunits
      samplerate
      starttime
      endttime
   end
   properties(Dependent)
      network
      station
      location
      channel
   end
   methods
   end
   methods(Static)
      function chdeets = retrieve(ds,varargin)
         % get from fdsnws station service
        p = inputParser;
        p.addOptional('network','');
        p.addOptional('station','');
        p.addOptional('channel','');
        p.addOptional('location','');
        p.addOptional('starttime',[]);
        p.addOptional('endtime',[]);
        p.addOptional('startbefore',[]);
        p.addOptional('startafter',[]);
        p.addOptional('endbefore',[]);
        p.addOptional('endafter',[]);
        p.addOptional('minlat',[]);
        p.addOptional('maxlat',[]);
        p.addOptional('minlon',[]);
        p.addOptional('maxlon',[]);
        p.addOptional('lat',[])
        p.addOptional('lon',[]);
        p.addOptional('maxradius',[]);
        p.addOptional('minradius',[]);
        p.addOptional('sensor',[]);
        p.addOptional('includerestricted','');
        p.addOptional('includeavailability','');
        p.addOptional('updatedafter','');
        p.addOptional('matchtimeseries','');
        p.parse(varargin{:})
        R = p.Results;
        fn = fieldnames(R);
        urlstr = 'https://service.iris.edu/fdsnws/station/1/query?format=text&level=channel';
        for n=1:numel(fn) % make sure we keep only active fields
           f = fn{n}; v = R.(f);
           if isempty(v)
              R = rmfield(R,f);
           else
              switch(f)
                 case {'network','channel','location','station'}
                    % all strings, nothing to do
                 case {'starttime','endtime',...
                       'startbefore','endbefore',...
                       'startafter','endafter',...
                       'updatedafter'}
                    if ischar(v)
                       R.(f) = datestr(datenum(v),31);
                    elseif isnumeric(v)
                       %datenum
                       R.(f) = datestr(v,31);
                    end
                    
                       R.(f) = strrep(v,' ','T');
                    % all dates. further process
                 case {'lat', 'lon', 'maxradius', 'minradius'} 
                    assert(~any(ismember({'minlat','maxlat','minlon','maxlon'},fn)),...
                       'cannot describe with lat/lon and min/max lat/lon');
                    R.(f) = num2str(v);
                 case {'minlat','maxlat','minlon','maxlon'}
                    R.(f) = num2str(v);
                 case {'includerestricted', 'includeavailability', 'matchtimeseries'}
                    % translate into 'TRUE' and 'FALSE'
              end
           end
        end
        fnames = fieldnames(R);
        for n=1:numel(fnames)
           name = fnames{n}; 
           val = R.(name);
           urlstr = [urlstr, '&', name, '=', val];
        end
        chdeets = urlread(urlstr);
        % parse A
      end
   end
   
end

