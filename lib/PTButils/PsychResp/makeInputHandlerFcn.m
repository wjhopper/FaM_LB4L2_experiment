function handlerFcn = makeInputHandlerFcn(handlerName)
switch handlerName
    case 'KbQueue'
        handlerFcn = @kbQueueHandler;
    case 'Robot'
        rob = java.awt.Robot;
        n = 1;
        handlerFcn = @Robot;        
end

    function [string, rt, advance, redraw]= kbQueueHandler(device, string, rt, varargin) 
    % listen_KbQueueStyle
        advance = 0;
        redraw = 0;
        [ pressed, firstPress]=KbQueueCheck(device);
        if pressed
            keys = find(firstPress);
            [~, ind] = sort(firstPress(firstPress~=0));
            keys = keys(ind);
            for i = 1:numel(keys)
                if (keys(i) == 13 && ~isempty(string)) || keys(i) == 39 %13 is return, 39 is right arrow 
                    advance = 1;                   
                elseif keys(i) == 8
                    if ~isempty(string) % 'BACKSPACE
                        string = string(1:end-1);       
                        rt = rt(1:end-1);
                        redraw = 1;
                    end
                else
                    string = [string, KbName(keys(i))]; %#ok<AGROW>
                    rt = [rt firstPress(keys(i))]; %#ok<AGROW>
                    redraw = 1;
                end
            end
        end
    end

    function [string, rt, advance, redraw] = Robot( device, string, rt, varargin)

    % listen_KbQueueStyle and draw with a robot!!!!
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
end



