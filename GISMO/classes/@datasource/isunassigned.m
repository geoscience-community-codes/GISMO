function val = isunassigned(ds)
%ISUNASSIGNED is true when no data source is associated with this object
val = true(size(ds));
for n=1:numel(ds)
  val(n) = strcmp(get(ds,'type'),'none');
end