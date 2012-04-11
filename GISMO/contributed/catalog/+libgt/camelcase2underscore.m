function str = camelcase2underscore(str)
% CAMELCASE2UNDERSCORE
%    Take a string like GreatSitkin and convert it to Great_Sitkin
%    strUS = camelcase2underscore(strCC)
%
%    See also underscore2camelcase

% AUTHOR: Glenn Thompson
% $Date$
% $Revision$

%str = firstalgorithm(str);
str = secondalgorithm(str);

function str2 = firstalgorithm(str)
% first algorithm
r = isupper(str);
f = find(r > 0);
if length(f) > 1
	str2 = str;
	for c=2:length(f)  
		str2 = strrep(str2, str(f(c)), sprintf('_%s', str(f(c))));
	end
end

function str2 = secondalgorithm(str)
str2 = strcat(str(1) ,regexprep(str(2:end), '[A-Z]', '_$0') );


