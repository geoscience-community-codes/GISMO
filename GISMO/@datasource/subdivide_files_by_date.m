function datesToCheck = subdivide_files_by_date(ds,startt,endt)
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
switch minchange
  case 1; %year
    
    datesToCheck = datenum(startVec(1):endVec(1),1,1,0,0,0);
  case 2; %month
    nmonths = (endVec(1)*24 + endVec(2)) -(startVec(1)*24 + startVec(2)) + 1;
    datesToCheck = datenum(startVec(1),startVec(2)+(0:nmonths-1),1,0,0,0);
  case 3; %day
    datesToCheck = floor(startt):1:floor(endt);
  case 4; %hour
    datesToCheck = datenum(startVec(1),startVec(2),startVec(3),startVec(4),0,0):datenum(0,0,0,1,0,0):endt;
  case 5; %minute
    datesToCheck = datenum(startVec(1),startVec(2),startVec(3),startVec(4),startVec(5),0):datenum(0,0,0,0,1,0):endt;
  case 6; %second
    datesToCheck = startt:datenum(0,0,0,0,0,1):endt;
  case 0; %nothing
    datesToCheck = startt;
end

datesToCheck = datesToCheck(datesToCheck < endt);