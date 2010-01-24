function reducedisp_write_wfmeas(dbname,w,flt,algorithm);

% Opens DBNAME and inserts new reduced dispacement rows, one 
% for each waveform element. Assumes that each waveform element 
% has a field named REDUCEDISP. The filter FLT is assumed to be the
% same for all entries

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks

% PREP FIELDS
cutoff = get(flt,'cutoff');
poles = get(flt,'poles');
filterstr = ['BW ' num2str(cutoff(1),'%2.1f') ' ' num2str(poles) ' ' num2str(cutoff(2),'%2.1f') ' ' num2str(poles) ];
time = get(w,'START_EPOCH');
endtime =  get(w,'END_EPOCH');
tmeas = mean([time ; endtime]);
twin = get(w,'DURATION_EPOCH');
D = get(w,'REDUCEDISP');
sta = get(w,'STATION');
chan = get(w,'CHANNEL');


% WRITE DB ROWS
db = dbopen(dbname,'r+');
db = dblookup_table(db,'wfmeas');
for i = 1:length(D)
    if strcmpi(algorithm,'BODY')    
        dbaddv(db,'sta',sta{i},'chan',chan{i},'meastype','Dr_body','filter',filterstr,'time',time(i),'endtime',endtime(i),'tmeas',tmeas(i),'twin',twin(i),'val1',D(i),'units1','cm**2');
    elseif strcmpi(algorithm,'SURF')
            dbaddv(db,'sta',sta{i},'chan',chan{i},'meastype','Dr_surf','filter',filterstr,'time',time(i),'endtime',endtime(i),'tmeas',tmeas(i),'twin',twin(i),'val1',D(i),'units1','cm**2');
    else 
        error('Algorithm not recognized'); 
    end;
end;
dbclose(db);

