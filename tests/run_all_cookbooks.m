function run_all_cookbooks()
clc;
disp('=== RUNNING ALL GISMO COOKBOOKS (SMOKE TEST) ===');

cookbooks = {
    'core/@Catalog/cookbook'
    'core/@EventRate/cookbook'
    'core/@Response/cookbook'
    'core/@threecomp/cookbook'
    'core/@correlation/cookbook'
    'core/@waveform/cookbook'
    'core/@drumplot/cookbook'
};

for k = 1:numel(cookbooks)
    cb = cookbooks{k};
    fprintf('\n--- Running %s ---\n', cb);
    try
        feval(cb);
        fprintf('SUCCESS: %s\n', cb);
    catch ME
        warning('FAILED: %s\n%s', cb, ME.message);
    end
end

disp('=== COOKBOOK RUN COMPLETE ===');
end