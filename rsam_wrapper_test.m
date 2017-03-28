datasourceObject = datasource('antelope', '/home/t/thompsong/Cassandra/sak/dbSAK')
gulpMinutes = 60;
samplingIntervalSeconds = 10;
measures = {'mean';'max';'median'};

%% Days with data from SAKA only  
ChannelTagList = ChannelTag.array('JP','SAKA','',{'BD1';'BD2';'BD3';'HHE';'HHN';'HHZ'});
startTime = datenum(2015,5,21);
endTime = datenum(2015,5,24);
iceweb.rsam_wrapper('Sakurajima', datasourceObject, ChannelTagList, ...
            startTime, endTime, gulpMinutes, ...
            samplingIntervalSeconds, measures);
        
%% Days with data from SAKA and SAKB       
ChannelTagList = [ChannelTagList ChannelTag.array('JP','SAKB','',{'BD1';'BD2';'BD3';'HHE';'HHN';'HHZ'}) ];   
startTime = datenum(2015,5,24);
endTime = datenum(2015,6,8);
iceweb.rsam_wrapper('Sakurajima', datasourceObject, ChannelTagList, ...
            startTime, endTime, gulpMinutes, ...
            samplingIntervalSeconds, measures);
   
%% Days with data from SAKC too        
%ChannelTagList = [ChannelTagList ChannelTag.array('JP','SAKC','',{'BD1';'HHE';'HHN';'HHZ'}) ]; 
% startTime = datenum(2015,5,24);
% endTime = datenum(2015,6,8);
% iceweb.rsam_wrapper('Sakurajima', datasourceObject, ChannelTagList, ...
%             startTime, endTime, gulpMinutes, ...
%             samplingIntervalSeconds, measures);