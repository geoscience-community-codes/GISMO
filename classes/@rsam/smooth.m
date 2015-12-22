function self2=smooth(self1, windowlength, avtype)
%RSAM/SMOOTH Smooth the data in an RSAM object
% rsamobj2 = rsamobj1(10) Smooth 10 samples. This means
% that each sample is the mean of the current sample plus
% the 9 previous samples.
% rsamobj2 = rsamobj1(4, 'nanmedian') Smooth 4 samples, but use
% nanmedian rather than nanmean. 

if numel(self1(1).data) > (1440*30)
    warning('smooth is very slow for long time series')
end

if ~exist('avtype','var')
	avtype = 'nanmean';
end

% Would be good to allow methods other than mean as in resample.
self2 = self1;

for vnum=1:numel(self1)
    
    self2(vnum).data = smooth(self2(vnum).data, windowlength);

%     if strcmp('avtype','nanmean')
%         for c=2:length(self1(vnum).data)
%         startindex = max( [1 c-windowlength+1]);
%         self2(vnum).data(c) = nanmean(self1(vnum).data(startindex:c));
%         end
%     elseif strcmp('avtype','nanmedian')
%         for c=2:length(self1(vnum).data)
%         startindex = max( [1 c-windowlength+1]);
%         self2(vnum).data(c) = nanmedian(self1(vnum).data(startindex:c));
%         end
%     else % other methods will be slow since not supported
%         for c=2:length(self1(vnum).data)
%         startindex = max( [1 c-windowlength+1]);
%         eval(sprintf('self2(vnum).data(c) = %s(self1(vnum).data(startindex:c));',avtype));
%         end
%     end

end
