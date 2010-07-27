function polezero = response_polezero_demo

%RESPONSE_POLEZERO_DEMO Create a polezero structure
%  RESPONSE = RESPONSE_POLEZERO_DEMO Simple function to create/show a
%  single polezero structure in a format suitable for use in the response
%  toolbox.


polezero.poles = [
      -4.21+4.66i
      -4.21-4.66i
    -133.29+133.29i
    -133.29-133.29i
    -133.29+133.29i
    -133.29-133.29i ];

polezero.zeros = [
    0
    0];

polezero.normalization = 1.6916e+009;






