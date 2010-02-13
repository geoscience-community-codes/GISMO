function n = mep2dep(n)
% convert a matlab date to an epoch date
n = (n - 719529) * 86400;