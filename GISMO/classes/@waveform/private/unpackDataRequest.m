function [dataSource, chanInfo, startTimes, endTimes, combineWaves] = unpackDataRequest(request)
   dataSource = request.dataSource;
   chanInfo = request.chanInfo;
   startTimes = request.startTimes;
   endTimes = request.endTimes;
   combineWaves = request.combineWaves;
end
