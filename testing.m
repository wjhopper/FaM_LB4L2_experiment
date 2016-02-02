function [onset, response, firstPress, lastPress] = testing(data, inputHandler, window, constants)
% The onset vector holds the timestamp each trial began (as measured by the
% sync to the vertical backtrace

% The response cell array holds the input on each trial. If no input was
% given, the cell for the trial will hold an empty string ''

% the firstPress vector holds the timestamp of the first valid keypress
% (valid keys are a-z) belonging to the final response. Importantly, this
% is *NOT* neccesarily the ABSOLUTE first valid keypress participants made: a
% participants may use the backspace key to remove characters from their
% response e.g. in the event of a typo, and when this character is removed
% from the response string, the timestamp of its press is also removed from
% the RT vector. Thus, a participant may enter many characters, and remove
% all of them, and then complete their response for the trial. In
% that case, the firstPress timestamp would hold the time when the
% participant pressed the key for the first character in their FINAL
% response, not their initial (and subsequently removed) entry.

% the finalPress vector holds the timestamp of the last valid keypress
% belonging to the final response. Importantly, this is the *NOT* the time
% time the subject pressed the Enter or Return key to finalize their
% response, but is the final key in the range a-z they pressed

% Some important corner cases should be noted: If no response was given
% (i.e. an empty string is returned from the trial), then firstPress and
% lastPress should be NaN. If only a single valid keypress was recorded,
% then firstPress == lastPress. If multiple keypresses are recorded,
% firstPress and lastPress should be different, and the difference can be
% used to infer the amount of time spent typing.
% first
% Switch to high priority mode and increase the fontsize
oldPriority = Priority(1);
oldsize = Screen('TextSize', window, 40);

% Preallocate the output structures
onset = nan(size(data,1),1);
response = cell(size(data,1),1);
firstPress = nan(size(data,1),1);
lastPress = nan(size(data,1),1);

% Get rid of any random prior presses and start recording
KbQueueFlush;
KbQueueStart;

for j = 1:size(data,1)
    postpone = 0; % Don't postpone response deadline until the subject interacts
    string = ''; % Start with an empty response string for each target
    rt = []; % Start with an empty RT vector for each target
    advance = 0; % Enter or right-arrow key can be used to set this to 1, which will break out of the while loop
    inputFlag = 0; % 0 means to draw the cue and ? prompt, first keypress sets this to 1 so that reponse string is drawn.
    drawCueTarget(data.cue{j}, '?', window, constants); % Draw cue and prompt
    vbl = Screen('Flip', window); % Display cue and prompt
    onset(j) = vbl; % record trial onset
    while GetSecs < (onset(j) + constants.testDur + postpone) && advance == 0 % Until Enter is hit or deadline is reached, wait for input
        % string is the entirity of the subjects response thus far
        % rt 
        [string, rt, advance, azKeyPressed] = inputHandler([], string, rt, data.target{j});
        if ~isempty(string) || inputFlag
            drawCueTarget(data.cue{j},  string, window, constants);
            vbl = Screen('Flip', window, vbl + constants.ifi/2);
            postpone = postpone + azKeyPressed;
            inputFlag = 1;
        else
            drawCueTarget(data.cue{j}, '?', window, constants);
            vbl = Screen('Flip', window, vbl + constants.ifi/2);                
        end
    end
    [response{j}, firstPress(j), lastPress(j)] = cleanResponses(string, rt);
end
Screen('TextSize', window, oldsize); % reset text size
Priority(oldPriority);  % reset priority level
end

function [response, firstPress, lastPress] = cleanResponses(string, RT)

% Make sure response is a blank string, instead of some empty matrix or a
% char(0), as both of those are technically empty, but behave differently
% when trying to assign into a matrix or table
    if isempty(string)
        response = '';
    else
        response = string;
    end

% Check the rt vector. 
% if it is empty, mark both presses as missing
    if isempty(RT)
        firstPress = NaN;
        lastPress = NaN;
% if only a single key was pressed, make first and last press the same    
    elseif numel(RT) == 1
        firstPress = RT;
        lastPress = RT;
% if multiple keys were pressed, then first press is the first one, and last press is the last one.        
    else
        firstPress = RT(1);
        lastPress = RT(end);
    end
end