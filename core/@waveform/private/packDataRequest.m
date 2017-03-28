function datarequest = packDataRequest(ds, chanInfo, starts, ends, combineWaves)
   % packDataRequest - encapsulate the request, allowing single structure to be passed around.
   % request = packDataRequest(datasource, channelTags, startTimes,
   % endTimes, combineWaveforms)
   %
   % number of startTimes should match number of endTimes  (expected to be
   % in matlab data format)
   %
   % channelTags is an array of one or more channelTag objects
   % combineWaveforms is a logical that will trigger the joining of
   % waveforms if appropriate/possible.
   %
   % Created array has fields "dataSource", "chanInfo", "startTimes",
   % "endTimes", and "combineWaves"
   %
   % decode with unpackDataRequest (or just access the fields..)
   
   % move to datasource?
   datarequest = struct(...
      'dataSource', ds, ...  % datasource
      'chanInfo', chanInfo, ...  % ChannelTag (array)
      'startTimes', starts,... % startTime (array)
      'endTimes',ends, ... % endTime (array)
      'combineWaves', combineWaves);  % T/F combine the waveforms if possible?
end
