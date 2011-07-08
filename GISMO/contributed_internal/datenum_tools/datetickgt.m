function datetickgt(snum, enum, axh)

if ~exist('axh','var')

    axh = gca;
end

% add date labels
set(axh, 'XLim', [snum enum]);
datetick('x','keeplimits');

xticks = get(axh,'XTick');
nxticks = length(xticks);
xlim = get(axh,'XLim');
while (nxticks < 6)
	if (nxticks > 1)
		tickinterval = xticks(2) - xticks(1);
		xticks = xticks(1):tickinterval/2:xticks(end);
		if (xticks(1)-tickinterval/2 > xlim(1))
			xticks = [xticks(1)-tickinterval/2  xticks];
		end
		if (xticks(end)+tickinterval/2 < xlim(2))
			xticks = [xticks xticks(end)+tickinterval/2];
		end
		set(axh,'XTick',xticks);
		datetick('x','keeplimits','keepticks');
	else
		try
			DateTickLabel('x');
			datetick('x','keeplimits','keepticks');
		catch
			datetick('x','keeplimits');
		end
	end
	xticks = get(axh,'XTick');
	nxticks = length(xticks);
end

% set tick labels during a day to use hh:mm format
% those at start of days remain as they are

xticklabels = get(axh, 'XTickLabel');
for c=1:nxticks
	xticklabel{c} = xticklabels(c,:);
end
set(axh,'XTickLabel',xticklabel);
for index=1:nxticks
	if mod(xticks(index),1)>0
		xticklabel{index}=datestr(xticks(index),'HH:MM');
	end
	if (    strcmp(xticklabel{index},'Jan') || ...
		strcmp(xticklabel{index},'Feb') || ...
		strcmp(xticklabel{index},'Mar') || ...
		strcmp(xticklabel{index},'Apr') || ...
		strcmp(xticklabel{index},'May') || ...
		strcmp(xticklabel{index},'Jun') || ...
		strcmp(xticklabel{index},'Jul') || ...
		strcmp(xticklabel{index},'Aug') || ...
		strcmp(xticklabel{index},'Sep') || ...
		strcmp(xticklabel{index},'Oct') || ...
		strcmp(xticklabel{index},'Nov') || ...
		strcmp(xticklabel{index},'Dec')  )
		%xticklabel{index}=datestr(xticks(index),'yyyy/mm');
	end
end
set(axh,'XTickLabel',xticklabel);

xtl = get(axh,'XTickLabel'); 
if strfind(xtl{1},'Q')
	datetick(axh, 'x','mmmyy');
end 

% find anything labelled '00:00' and replace it with 'MM/DD'
xtl = get(axh,'XTickLabel'); xt = get(axh,'XTick');
for c=1:length(xtl)
	if iscell(xtl)
		if strcmp(xtl{c},'00:00')
			xtl{c} = datestr(xt(c),'mm/dd');
		end
		set(axh, 'XTickLabel', xtl);
	end
end 
