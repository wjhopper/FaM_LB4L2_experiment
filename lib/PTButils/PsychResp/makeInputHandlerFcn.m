function handlerFcn = makeInputHandlerFcn(handlerName)
switch handlerName
    case 'KbQueue'
        handlerFcn = @kbQueueHandler;
    case 'GoodRobot'
        rob = java.awt.Robot;
        n = 1;
        handlerFcn = @GoodRobot;
    case 'BadRobot'
        rob = java.awt.Robot;
        n = 1;
        handlerFcn = @BadRobot;
        
end

    function [string, rt, advance, redraw]= kbQueueHandler(device, string, rt, varargin) 
        %
        % The rules of this handler are as follows:
        %
        % 1: If the "Enter" of "Return" key is hit, then length of the response string
        %   is checked. If the response string is not empty, set the advance flag
        %   to 1.
        % 2: If the right arrow key is pressed, then length of the response string
        %   is checked. If the response string is empty, set the advance flag
        %   to 1.
        % 3: If the backspace key is pressed, then length of the response string
        %   is checked. If the response string is not empty, then set remove
        %   the final character from the string, and remove the last recorded
        %   RT. The value of the redraw flag is set to -1.
        % 4: If any other key is pressed, then that keys character value is
        %   concatenated to the existing response string, and the recorded time
        %   for that key presses is concatenated to the existing rt vector
        %   is checked. The value of redraw flag is set to 1.
        %
        % The response string and RT vector are returned (updated with any input
        % given by the participant) as well as the advance and redraw flags.
        %
        % The advance flag can be either 0 (the default) or  1 if the Enter
        % key or left arrow key were pressed, and can be caller to determine
        % if the subject has finalized  their response and thus the experiment
        % should continue to the next trial.
        %
        % The redraw flag can be either 0 (the default) or  1. A value of 1
        % means that valid input was given i.e., a-z was pressed, and 0 
        % means no valid input was given.
        
        % Set flag defaults
        advance = 0;
        redraw = 0;
        % Check the KbQueue for presses
        [ pressed, firstPress]=KbQueueCheck(device);
        if pressed
            % find the keycode for the keys pressed since last check            
            keys = find(firstPress);
            % sort the recorded press time to find their linear position
            [~, ind] = sort(firstPress(firstPress~=0));
            % Arrange the keycodes according to the order they were pressed
            keys = keys(ind);
            % Loop over each recorded keycode. There should ideally be only one,
            % but crazy things can happen
            for i = 1:numel(keys)
                switch keys(i)
                    case 13 %13 is return
                        if ~isempty(string) % set the advance flag is input has been given
                            advance = 1;
                        end
                    case 39  %39 is right arrow
                        if isempty(string) % set the advance flag if no input has been given
                            advance = 1;
                        end
                    case 8 %8 is BACKSPACE
                        % remove the last entered character and its
                        % keypress timestamp but only if some user input
                        % has been given previously (meaning the input
                        % string will not be ''.
                        if ~strcmp('',string) 
                            string = string(1:end-1);       
                            rt = rt(1:end-1);
                        end
                    otherwise
                        % Add the character just pressed to the input
                        % string, and record the timestamp of its keypress.
                        % Set the redraw flag to 1.
                        string = [string, KbName(keys(i))]; %#ok<AGROW>
                        rt = [rt firstPress(keys(i))]; %#ok<AGROW>
                        redraw = 1;
                end
            end
        end
    end

    function [string, rt, advance, redraw] = GoodRobot( device, string, rt, varargin)

    % This function is a wrapper around kbQueueHandler, which provides
    % automatic keyboard input by simulating a keypress of each character in the given response string
    % with Java Robot object instead of waiting for a human.
    %
    % The tricky bit here is that it doesn't loop over each character in the string,
    % Instead, this function is a closure and we share a stateful indexing variable n
    % with the parent function, makeInputHandlerFcn. n starts off set to 1 in the
    % parent function. If n is less than or equal to  the length of the answer,
    % we construct the robot press and release calls for that character, hand off
    % to the actual input handler function to record it, and increment the indexing
    % variable n (e.g. n = n + 1 =2). This increment is remembered the next
    % time we enter the function, because this function is a closure.
    %
    % When n grows larger than the length of the answer string, we press
    % and release the Enter key to confirm the previously recorded input
    % and advance. Before returning, n is reset to 1, and this reset is
    % remembered the next time we enter this function (which should be for
    % a new answer to input) and so we begin with inputing the first character of
    % the new answer.

        answer = varargin{1};
        if n <= length(answer)
            eval([ 'rob.keyPress(java.awt.event.KeyEvent.VK_', upper(answer(n)), ');' ]);
            eval([ 'rob.keyRelease(java.awt.event.KeyEvent.VK_', upper(answer(n)), ');' ]);        
            [string, rt, advance, redraw] = kbQueueHandler(device, string, rt);
            n = n + 1;
        else
            rob.keyPress(java.awt.event.KeyEvent.VK_ENTER);
            rob.keyRelease(java.awt.event.KeyEvent.VK_ENTER);           
            [string, rt, advance, redraw] = kbQueueHandler(device, string, rt);
            n = 1;
        end
   
    end


    function [string, rt, advance, redraw] = BadRobot(device, string, rt, varargin)

    % This function is a wrapper around kbQueueHandler, which provides
    % automatic keyboard input by simulating a keypress of each character in the given response string
    % with Java Robot object instead of waiting for a human.
    %
    % The tricky bit here is that it doesn't loop over each character in the string,
    % Instead, this function is a closure and we share a stateful indexing variable n
    % with the parent function, makeInputHandlerFcn. n starts off set to 1 in the
    % parent function. If n is less than or equal to  the length of the answer,
    % we construct the robot press and release calls for that character, hand off
    % to the actual input handler function to record it, and increment the indexing
    % variable n (e.g. n = n + 1 =2). This increment is remembered the next
    % time we enter the function, because this function is a closure.
    %
    % When n grows larger than the length of the answer string, we press
    % and release the Enter key to confirm the previously recorded input
    % and advance. Before returning, n is reset to 1, and this reset is
    % remembered the next time we enter this function (which should be for
    % a new answer to input) and so we begin with inputing the first character of
    % the new answer.

        answer = randsample('abcdefghijklmnopqrstuvwxys', 4);
        WaitSecs('UntilTime', GetSecs + .1);
        if n <= length(answer)
            eval([ 'rob.keyPress(java.awt.event.KeyEvent.VK_', upper(answer(n)), ');' ]);
            eval([ 'rob.keyRelease(java.awt.event.KeyEvent.VK_', upper(answer(n)), ');' ]);        
            [string, rt, advance, redraw] = kbQueueHandler(device, string, rt);
            n = n + 1;
        else
            rob.keyPress(java.awt.event.KeyEvent.VK_ENTER);
            rob.keyRelease(java.awt.event.KeyEvent.VK_ENTER);           
            [string, rt, advance, redraw] = kbQueueHandler(device, string, rt);
            n = 1;
        end
   
    end
end



