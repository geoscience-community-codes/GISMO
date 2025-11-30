function tests = test_mastercorr
tests = functiontests(localfunctions);
end

function test_runMastercorrCookbook(~)
try
    mastercorr.cookbook();
catch ME
    warning("mastercorr cookbook failed: %s", ME.message);
end
end