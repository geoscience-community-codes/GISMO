function ds = setinterpreter(ds,funchandle)
%SETINTERPRETER changes the associated interpreter function
% datasource = setinterpreter(datasource,function_handle)

if ~isa(funchandle,'function_handle')
  error('Trying to set a function handle to a %s',class(funchandle));
end

ds = datasource(funchandle,ds.file_string,ds.file_args{:});