function printfunctionstack(symbol)
% PRINTFUNCTIONSTACK print the list of functions in the stack
%
%    PRINTFUNCTIONSTACK prints a full list of the nested function calls on the stack, so it tells you where in your code you are.
%    
%    EXAMPLE:
%	function myfunc1()
%		debug.printfunctionstack('>')
%		myfunc2()
%		debug.printfunctionstack('<')
%	end
%	function myfunc2()
%		debug.printfunctionstack('>')
%		myfunc3()
%		debug.printfunctionstack('<')
%	end
%	function myfunc3()
%		debug.printfunctionstack('>')
%		disp('hello world')
%		debug.printfunctionstack('<')
%	end
%
%	debug.set_debug(1)
%	myfunc1()
%	
%	would result in:
%	>myfunc1
%	>myfunc1>myfunc2
%	>myfunc1>myfunc2>myfunc3
%	hello world	
%	<myfunc1<myfunc2<myfunc3
%	<myfunc1<myfunc2
%	<myfunc1
%
%    See also debug.set_debug, debug.get_debug, debug.print_debug, setpref.

% AUTHOR: Glenn Thompson, UAF-GI
% $Date: $
% $Revision: -1 $

st = dbstack;
outstr='';
if numel(st)>1
        for c=numel(st):-1:2
                outstr = sprintf('%s%s%s',outstr, symbol,st(c).name);
        end
end
debug.print_debug(1, '%s at %s',outstr,datestr(utnow()));
