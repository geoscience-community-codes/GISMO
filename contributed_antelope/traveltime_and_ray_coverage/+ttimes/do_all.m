function do_all(dbName)

%DO_ALL execute all codes in the ttimes package.
% DO_ALL(dbName) runs each of the codes in the ttimes package on the
% database specified by dbName. See the ttimes.dbload function for a
% description.
%
% See also ttimres.dbload


ttimes.map(dbName);
ttimes.depth_section(dbName);
ttimes.tt_curve(dbName);
ttimes.arrival_histogram(dbName);
ttimes.write_lotos(dbName);
ttimes.dbload(dbName)
