function w = winston_access(varargin)
   p.channel = 'EHZ';
   p.station = 'UNK';
   p.tStart = datenum(1970, 1, 1, 0 ,0, 0);
   p.tEnd = datenum(1970, 1, 1, 0, 5, 0);
   p.network = '';
   p.location = ''; %should this be '--' ?
   p.server = 'churchill.giseis.alaska.edu';
   p.port = 16022;
   
   warning('Waveform:waveform:oldUsage',updateWarningMessage);
   
   % INPUT: waveform (station, channel, start, end, network,
   %                  location, server, port)
   
   MyVars = {'station', 'channel', 'tStart', 'tEnd', 'network', ...
      'location', 'server', 'port'};
   
   %Fill in all the variables with the appropriate default values
   for N = 1:argCount
      if ~isempty(varargin{N}),
         p.(MyVars{N}) = varargin{N};
      end
   end
   thesechans = ChannelTag(p.station,p.channel,p.network,p.location);
   
   mysource = datasource('winston',p.server,p.port);
   w = waveform(mysource, thesechans, datenum(p.tStart), datenum(p.tEnd));
end

function s = updateWarningMessage()
   
   updateMessageBase = ...
      ['Instead, please call the waveform constructor with '...
      ' a datasource and locationtag. \n'...
      'USAGE: w = waveform(datasource, locationtag, starttimes, endtimes)\n'...
      '   ...modifying request and proceeding.'];
   s = sprintf('%s',updateMessageBase);
end