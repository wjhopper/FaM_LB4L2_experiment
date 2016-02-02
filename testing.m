function [onset, response, firstPress, lastPress] = testing(data, inputHandler, window, constants)

% Switch to high priority mode and increase the fontsize
oldPriority = Priority(1);
oldsize = Screen('TextSize', window, 40);

% Preallocate the output structures
onset = nan(size(data,1),1);
response = cell(size(data,1),1);
firstPress = nan(size(data,1),1);
lastPress = nan(size(data,1),1);

% Make a copy of the max test duration
duration = constants.testDur;

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
        [string, rt, advance] = inputHandler([], string, rt, data.target{j});
        if ~isempty(string) || inputFlag
            drawCueTarget(data.cue{j},  string, window, constants);
            vbl = Screen('Flip', window, vbl + constants.ifi/2);
            postpone = postpone + 1;
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

    if isempty(string)
        response = '';
    else
        response = string;
    end

    if isempty(RT)
        firstPress = NaN;
        lastPress = NaN;
    elseif numel(RT) == 1
        firstPress = NaN;
        lastPress = RT;
    else
        firstPress = RT(1);
        lastPress = RT(end);
    end
end