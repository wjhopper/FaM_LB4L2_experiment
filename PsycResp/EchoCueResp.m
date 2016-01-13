function [string, onset, rt] = EchoCueResp(windowPtr, cue, msg, cueRect, respRect, varargin)
KbName('UnifyKeyNames')
HideCursor();
% string = EchoCue Resp(window, cue, msg, left, right, [KbHandler], dev, [duration],[answers],[textColor], [bgColor] )

% REQUIRED ARGUMENTS
%
% Get a string typed at the keyboard. Entry is terminated by <return> or
% <enter>. Adapted from GetEchoString, part of the psychtoolbox-basic set
% of functions, distributed with psychtoolbox
%
% Typed characters are displayed in the window. The delete or backspace key
% is handled correctly, ie., it erases the last typed character. Useful for
% i/o in a Screen window.
%
% 'window' = Window to draw to. 
%
% 'cue' = A string to draw on the left half. Can be blank (i.e. the empty
% vector []), but argument cannot be completely left out. 
% NOTE: EMPTY  VECTOR USAGE IS UNTESTED!!!!!!!!!!!!
%
% 'msg' = A message string displayed to  prompt for input. Can be blank 
% (i.e. the empty vector []), but argument cannot be completely left out. 
% NOTE: EMPTY  VECTOR USAGE IS UNTESTED!!!!!!!!!!!! 
%
% 'cueRect' = coordinate positions for region where cue word is placed.
% Defined by [x1,y1,x2,y2] vector where (x1,y1) is the top 
% left vectice of the rectangular region and (x2,y2) is the bottom right
% vertice of the rectangular region.
%
% 'respRect' = coordinate positions for region where response input is drawn.
% Defined by [x1,y1,x2,y2] vector where (x1,y1) is the top 
% left vectice of the rectangular region and (x2,y2) is the bottom right
% vertice of the rectangular region. 
%
% OPTIONAL ARGUMENTS
%
% 'KbHandler' = a string specifying the the psychtoolbox key press handling 
% function you want to use. Can be 'KbQueue' (the default),
% 'KbCheck', 'GetChar' or 'Robot'. Using 'Robot' requires
% using an instance of the Java robot class, so it is not suitable for the matlab --no-jvm environment
% and forces the use of KbQueue to handle presses from the robot. 
%
% 'dev' = device number of connected keyboard you want to use 
%
% 'duration' = numeric scalar value which determines how long input will be
% accepted for. Default is 'inf', which allows for an infinite responding
% period.
%
%
% 'answer' = a character vector which the Java robot will type in. Default
% is [], as 
% 
% 'textColor' = Color to use for drawing the text. 
% 'bgColor' = Background color for text. By default, the background is transparent. If a non-empty
% bgColor value is specified it will be used. The current alpha blending
% setting will affect the appearance of the text if 'bgColor' is specified!

% See also: GetNumber, GetString, GetEchoNumber


if nargin > 12
    error('EchoCueResp:EchoCueResp:TooManyInputs', ...
            'accepts at most 12 argument inputs');
end

optargs = {'KbQueue',[], 35, inf, [], @dummy_draw, {}, Screen('TextColor', windowPtr), []};
optargs(1:length(varargin)) = varargin;
[KbHandler,dev, spacing,duration, answer, draw, params, textColor, bgColor] = optargs{:}; %#ok<ASGLU>

% If RobotEchoHandler is used, check that robot and answer arguments are
% given
if strcmp(KbHandler,'Robot') && isempty(answer)
     error('EchoCueResp:EchoCueResp:MissingRobotInputs', ...
            'Use of RobotEchoHandler requires optional arguments ''robot'' and ''answer'' to be specified');
end

% Enable user defined alpha blending if a text background color is
% specified. This makes text background colors actually work, e.g., on OSX:
if ~isempty(bgColor)
    oldalpha = Screen('Preference', 'TextAlphaBlending', 1-IsLinux); 
end

%% ------------- Drawing and Writing --------------------------------------
DisableKeysForKbCheck([9,20,27,32,37,39,44,46,93,160:165,188,190,191]);
string=msg;
onset = draw(windowPtr,cue,string,cueRect,respRect,params) ;% Write the initial message
string='';
KbHandler=eval(['@' KbHandler '_EchoHandler']);
[string, rt] = KbHandler(string);

%% ------------ Cleanup before going home -------------------------------------------------------------
if ~isempty(bgColor)   % Restore text alpha blending state if it was altered:
    Screen('Preference', 'TextAlphaBlending', oldalpha);
end 
DisableKeysForKbCheck([]);
KbQueueFlush(dev);
return

%% ------------- KbHandler Functions ------------------------------------------------------------------

function [string, fliprt]= GetChar_EchoHandler(string) %#ok<DEFNU>
% listen_GetCharStyle
    while true
        char = GetChar;
        [string, dobreak] = checkchar(char,string);
        if dobreak
            break
        else
           fliprt = draw(windowPtr,cue,string,cueRect,respRect);
        end
    end
    ListenChar(0);
end    


function [string, fliprt] = KbCheck_EchoHandler(string) %#ok<DEFNU>
% listen_KbCheckStyle 
    timer=0;
    untilTime = GetSecs + duration;
    tic = GetSecs;       
    while true
        char = GetKbChar(dev,untilTime);
        [string, dobreak] = checkchar(char,string);
        if dobreak
            fliprt = GetSecs;
            break
        else
            fliprt = draw(windowPtr,cue,string,cueRect,respRect);
        end
        toc = GetSecs;
        timer = timer + (toc-tic);
        untilTime = GetSecs+(duration-timer);
    end
    ListenChar(0);    
end

function [string, rt ]=KbQueue_EchoHandler(string) %#ok<DEFNU>
    % listen_KbQueueStyle
    untilTime = GetSecs + duration;
    rt=[];
    KbQueueStart(dev);
    while GetSecs < untilTime;
        [ pressed, firstPress]=KbQueueCheck(dev);
        if pressed                 
            [pressTimes, ind] = sort(firstPress(firstPress ~= 0));
            keys = find(firstPress);

            if iscell(keys)
                keys =[keys{:}];
                keys = keys(ind);
            end

            for i=1:numel(keys)

                if keys(i) == 13  
                    untilTime=0;       
                elseif keys(i) == 8 % 'BACKSPACE
%                     if ~isempty(string)
                    string = string(1:end-1);       
                    rt = rt(1:end-1);
                    draw(windowPtr,cue,string,cueRect,respRect);                    
%                     end
                else
                    chars = KbName(keys(i));
                    string = [string, chars(1)]; %#ok<AGROW>
                    rt = [rt pressTimes(i)]; %#ok<AGROW>
                    draw(windowPtr,cue,string,cueRect,respRect);                    
                end
            end                
%             draw(windowPtr,cue,string,cueRect,respRect);
        end
    end
    KbQueueStop(dev);
    if isempty(rt)
        rt=[NaN,GetSecs];
        return
    elseif numel(rt) <2
        rt = [rt GetSecs];        
    end
    rt=[rt(1),rt(end)];
    
end    

function [string, rt]=Robot_EchoHandler(string) %#ok<DEFNU>
% listen_KbQueueStyle and draw with a robot!!!!

    rob = java.awt.Robot; %#ok<NASGU>
    import java.awt.event.KeyEvent
    press = {'rob.keyPress(KeyEvent.VK_', 'ENTER',');'};
    release = {'rob.keyRelease(KeyEvent.VK_','ENTER',');'};
    untilTime = GetSecs + duration;
    rt=[];
    KbQueueStart(dev);
    for j = 1:length(answer)
        press{2} = upper(answer(j));
        release{2} = upper(answer(j));
        while GetSecs < untilTime;
            eval([press{:}]);
            eval([release{:}]);
            [ pressed,  firstPress]=KbQueueCheck(dev);
            if pressed

                [pressTimes, ind] = sort(firstPress(firstPress ~= 0));
                keys = find(firstPress);

                if iscell(keys)
                    keys =[keys{:}];
                    keys = keys(ind);
                end

                for i=1:numel(keys)
                    if keys(i) == 13  % 'RETURN'
                        untilTime=0;       
                    elseif keys(i) == 8 % 'BACKSPACE
%                     if ~isempty(string)
                        string = string(1:end-1);       
                        rt = rt(1:end-1);
                        draw(windowPtr,cue,string,cueRect,respRect);                        
%                     end
                    else
                        chars = KbName(keys(i));
                        string = [string, chars(1)]; %#ok<AGROW>
                        rt = [rt pressTimes(i)]; %#ok<AGROW>
                        draw(windowPtr,cue,string,cueRect,respRect);                        
                    end
                end                
%                 draw(windowPtr,cue,string,cueRect,respRect);
                break
            end
        end
    end
    KbQueueStop(dev);
    if isempty(rt)
        rt=[NaN,GetSecs];
        return
    elseif numel(rt) <2
        rt = [rt GetSecs];
    end    
    rt=[rt(1),rt(end)];
end

    
%% ---------- checkchar(char) -----------------------------------------------------------------
    function [string, dobreak] = checkchar(char, string)
        if isempty(char)
            dobreak =1;
        end  
        switch abs(char)
            case {13, 3, 10} % ctrl-C, enter, or return
                dobreak = 1;
            case 8 % backspace
                if ~isempty(string)
                    string=string(1:end-1);              
                end
            otherwise
                string = [string, char]; 
        end
    end    
%% --------------- default drawing function -------------------------------------------------

function onset = dummy_draw(windowPtr,cue,string,cueRect,respRect,varargin)
    DrawFormattedText(windowPtr,cue,'center', 'center',[],[],[],[],[],[],cueRect);
    DrawFormattedText(windowPtr,string, respRect(1), 'center');
    [~, onset] = Screen('Flip', windowPtr);
end
    
end

