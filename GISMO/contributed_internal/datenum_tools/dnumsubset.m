function [dnum,data]=dnumsubset(dnum, data, snum, enum)
i = find(dnum >= snum & dnum <= snum);
dnum = dnum(i);
data = data(i);
