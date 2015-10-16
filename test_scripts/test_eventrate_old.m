function test_eventrate()
    % TEST_EVENTRATE
        %   A basic test suite to ensure EVENTRATE still works following
        %   updates

           catalog.test_helper('erobj = eventrate');
           
           catalog.test_helper('erobj = eventrate(catalog,1)');
           
           dirname = fileparts(which('catalog')); 
           dbroot = [dirname,'/demo/avodb200903']; 

           str = sprintf('catalog( ''%s'', ''antelope'', ''snum'', datenum(2009,3,20), ''enum'', datenum(2009,3,23),''region'',''Redoubt'')',dbroot);
           catalog.test_helper(sprintf('erobj = eventrate(%s,1)',str));

           catalog.test_helper(sprintf('erobj = eventrate(%s,1,''stepsize'', 1/4)',str));
         end

