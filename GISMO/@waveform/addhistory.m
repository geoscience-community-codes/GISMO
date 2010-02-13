function w = addhistory(w, whathappened,varargin)
%ADDHISTORY function in charge of adding history to a waveform
%   waveform = addhistory(waveform, whathappened);
%   waveform = addhistory(waveform, formatString, [variables...])
%
%   Mostly, addhistory is internal to the waveform methods, and will be
%   updated automatically when you change the waveform.  Things like
%   filtering, taking a hilbert envelope, or detrending will automatically
%   drop notes into the waveform's HISTORY field.
%
%   The second way of using addhistory follows the syntax of sprintf
%
%   Input Arguments
%       WAVEFORM: a waveform object   N-DIMENSIONAL
%       WHATHAPPENED: absolutely anything.  Really.
%
%   AddHistory appends not only what happened, but also keeps track of WHEN
%   it happened.
%
%   Control of whether or not history is added automatically lies within
%   the waveform constructor (in a global variable called WAVEFORM_HISTORY)
%
%   example
%       w = waveform; %create a blank waveform
%       w = addhistory(w,'the following procedures done by DoIt.m');
%       N = 1; M = 'Today'
%       w = addhistory(w,'this is sample #%d date:%s',N,M);
%       % output: "this is sample #1 date:Today"
%
%
% See also WAVEFORM/ADDFIELD, WAVEFORM/GET, WAVEFORM/HISTORY, SPRINTF

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/14/2009



global WAVEFORM_HISTORY
if nargin > 2,
    whathappened = sprintf(whathappened, varargin{:});
end
if WAVEFORM_HISTORY
modtime = now;
    for N = 1 : numel(w);
        %History is stored in a cell, the format of which is [WHAT, WHEN]
        isHistory = strcmp('HISTORY', w(N).misc_fields);
        if any(isHistory) %ismember('HISTORY', get(w(N),'misc_fields'))
            w(N).misc_values(isHistory) = {[w(N).misc_values{isHistory}; {whathappened, modtime}]};
        else
            newhist = {whathappened, now};
            w(N) = addfield(w(N),'HISTORY', newhist);
        end
    end
end