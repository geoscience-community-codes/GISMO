function check_block_balance(fname)
% Simple block token counter to help locate missing ENDs
txt = fileread(fname);
tokens = {'function','classdef','if','for','while','switch','try','parfor'};
openers = 0;
for k=1:numel(tokens)
    openers = openers + numel(regexpi(txt,['\<' tokens{k} '\>']));
end
closers = numel(regexpi(txt,'\bend\b'));
fprintf('File: %s\nOpeners: %d  End tokens: %d  Balance: %d\n', fname, openers, closers, closers-openers);
% print nearby context around reported line if imbalance
if closers < openers
    lines = split(txt,newline);
    for i=1:numel(lines)
        if ~isempty(regexpi(lines{i},'\<function|\bclassdef\b|\bif\b|\bfor\b|\bwhile\b|\bswitch\b|\btry\b'))
            idx = max(1,i-3):min(numel(lines),i+3);
            fprintf('Context near line %d:\n', i);
            fprintf('%4d: %s\n', [idx; lines(idx)]');
            break
        end
    end
end
end