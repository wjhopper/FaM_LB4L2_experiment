function [onset, response, firstPress, lastPress] = testing(data, inputHandler, window, constants)

% Switch to high priority mode and increase the fontsize
oldPriority = Priority(1);
oldsize = Screen('TextSize', window, 40);
onset = nan(size(data,1),1);
response = cell(size(data,1),1);
firstPress = nan(size(data,1),1);
lastPress = nan(size(data,1),1);
duration = constants.testDur;
KbQueueFlush;
KbQueueStart;

for j = 1:size(data,1)
    string = '';
    rt = [];
    advance = 0;
    inputFlag = 0; 
    drawCueTarget(data.cue{j}, '?', window, constants);
    vbl = Screen('Flip', window);
    onset(j) = vbl;
    while GetSecs < onset(j) + duration && advance == 0
        [string, rt, advance] = inputHandler([], string, rt, data.target{j});
        if ~isempty(string) || inputFlag
            drawCueTarget(data.cue{j},  string, window, constants);
            vbl = Screen('Flip', window, vbl + constants.ifi/2);
            duration = duration + 3;
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