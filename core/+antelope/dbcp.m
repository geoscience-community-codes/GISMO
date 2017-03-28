function dbcp( dbpath1, dbpath2 )
%DBCP Copy one Antelope database to another
%   dbcp(sourcedbpath, targetdbpath) calls the dbcp command
    
    cmdstr = sprintf('%s/bin/dbcp %s %s', getenv('ANTELOPE'),dbpath1, dbpath2);
    fprintf('Copying database:\n\t%s\n',cmdstr);
    result = system(cmdstr);

end

