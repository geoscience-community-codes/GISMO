function test()
%TEST
%   A basic test suite to ensure CATALOG still works following
%   updates
%
% See also CATALOG
%
% AUTHOR: Glenn Thompson

% $Date: $
% $Revision: $

           catalog.test_helper('cobj = catalog');
           
           dirname = fileparts(which('catalog')); 
           dbroot = [dirname,'/demo/avodb200903']; 

           str = sprintf('cobj = catalog(''%s'', ''antelope'', ''snum'', datenum(2009,3,20), ''enum'', datenum(2009,3,23), ''region'', ''Redoubt'')',dbroot)
           catalog.test_helper(str);
           
           dbeval_expr = 'time > "2009/03/20" && time < "2009/03/23" && distance(lat, lon, 60.5, -152.6) < 0.2';
           str = sprintf('cobj = catalog(''%s'', ''antelope'', ''dbeval'', ''%s'')',dbroot, dbeval_expr);
           catalog.test_helper(str);
           
           if exist('/avort/oprun/events', 'dir')
           
                str = 'cobj = catalog(''/avort/oprun/events/earthworm/events_earthworm'', ''antelope'' )';
                catalog.test_helper(str);
           
                str = sprintf('cobj = catalog(''/avort/oprun/events/earthworm/events_earthworm'', ''antelope'', ''dbeval'', ''time > %f'' )', datenum2epoch(now-7));
                catalog.test_helper(str);
           end
end

