function self = loadwfmeastable(sta, chan, snum, enum, measure, dbname)
    self = rsam();
    [data, dnum, datafound, units] = datascopegt.load_wfmeas(station, snum, enum, measure, dbname);
    self.dnum = dnum;
    self.data = data;
    self.measure = measure;
    self.units = units;
end