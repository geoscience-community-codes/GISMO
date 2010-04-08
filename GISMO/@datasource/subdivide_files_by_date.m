function allDatesToCheck = subdivide_files_by_date(ds,startt,endt)
%SUBDIVIDE_FILES_BY_DATE given a datasource and daterange return list of files
% datesToCheck = subdivide_files_by_date(ds,startt,endt)

%maxDateBins is currently unused
maxDateBins = 1000; %maximum number of files to be returned

startt = datenum(startt);
endt = datenum(endt);
startVec = datevec(startt);
endVec = datevec(endt);
fn = getfilename(ds,[],[]);
fn = fn{1};

changes = [any(findstr(fn,'[YEAR]')),any(findstr(fn,'[MONTH]')),...
    any(findstr(fn,'[DAY]')) || any(findstr(fn,'[JDAY]')),...
    any(findstr(fn,'[HOUR]')), any(findstr(fn,'[MINUTE]')),...
    any(findstr(fn,'[SECOND]'))];
%which aspect changes?
%changes = startVec ~= endVec;
minchange = find(changes,1,'last');
if isempty(minchange)
    minchange = 0;
end

allDatesToCheck = [];

for timesnip = 1:numel(startt)
    thisstart = startt(timesnip);
    thisend =  endt(timesnip);
    thisStartVec = startVec(timesnip,:);
    thisEndVec = endVec(timesnip,:);
    switch minchange
        case 1; %year
            
            datesToCheck = datenum(thisStartVec(1):thisEndVec(1),1,1,0,0,0);
        case 2; %month
            nmonths = (thisEndVec(1)*24 + thisEndVec(2)) -(thisStartVec(1)*24 + thisStartVec(2)) + 1;
            datesToCheck = datenum(thisStartVec(1),thisStartVec(2)+(0:nmonths-1),1,0,0,0);
        case 3; %day
            datesToCheck = floor(thisstart):1:floor(thisend);
        case 4; %hour
            datesToCheck = datenum(thisStartVec(1),thisStartVec(2),thisStartVec(3),thisStartVec(4),0,0):datenum(0,0,0,1,0,0):thisend;
        case 5; %minute
            datesToCheck = datenum(thisStartVec(1),thisStartVec(2),thisStartVec(3),thisStartVec(4),thisStartVec(5),0):datenum(0,0,0,0,1,0):thisend;
        case 6; %second
            datesToCheck = thisstart:datenum(0,0,0,0,0,1):thisend;
        case 0; %nothing
            datesToCheck = thisstart;
    end %switch
datesToCheck = datesToCheck(datesToCheck < thisend);
allDatesToCheck = [allDatesToCheck(:); datesToCheck(:)];
end %timesnip

allDatesToCheck = unique(allDatesToCheck);