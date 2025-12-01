function w = attachWaveformFields(w, arrrow)
%EVENTMATRIX.ATTACHWAVEFORMFIELDS Attach metadata safely

w = addfield(w, 'EVENT_START', arrrow.time);
w = addfield(w, 'ORID', arrrow.orid);
w = addfield(w, 'OTIME', arrrow.otime);
w = addfield(w, 'SEAZ',  arrrow.seaz);
end