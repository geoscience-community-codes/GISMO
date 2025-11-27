function run_all_tests()
clc;
disp('=== RUNNING ALL GISMO UNIT TESTS ===');

results = runtests('tests');

disp(table(results));
disp('=== UNIT TESTS COMPLETE ===');

if any([results.Failed])
    error('Some GISMO unit tests FAILED.');
end
end