%% Main function to generate tests
% to run this use
%   runtests('Catalog_test')
function tests = Catalog_test()
tests = functiontests(localfunctions);
end

%% Test Functions
function testFunctionOne(testCase)
Catalog.cookbook;
end

%% Optional file fixtures  
function setupOnce(testCase)  % do not change function name
% set a new path, for example
end

function teardownOnce(testCase)  % do not change function name
% change back to original path, for example
end

%% Optional fresh fixtures  
function setup(testCase)  % do not change function name
% open a figure, for example
close all
end

function teardown(testCase)  % do not change function name
% close figure, for example
close all
end
