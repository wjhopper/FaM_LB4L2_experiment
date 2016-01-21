function []= giveInstructions(phase_name, inputHandler, window, constants, varargin)

% oldTextSize=Screen('TextSize', window, 28);
switch phase_name
    case 'intro'
        input = varargin{1};
        data = cell2table([{'building'; 'painting'; 'tape'; 'cloth'; 'mug';}, ...
            {'car'; 'trash'; 'jacket'; 'pine'; 'trunk'}], 'VariableNames', {'cue','target'});
        KbQueueCreate;
        KbQueueStart;
        %% Screen
        text = ['Welcome to the experiment!' ...
            '\n\nIn this experiment, you will be shown pairs of words.' ...
            '\nYour task is to learn these pairs, so that you will be able to remember them later on a test.'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        KbQueueWait;

        %% Screen
        KbQueueStop;
        text = ['Each word pair will have the first word on the left side of the screen, and the second word on the right side.', ...
            '\n\nThe pairs you study will be grouped into "lists" of 20 pairs, and you will study each pair one at a time.'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        KbQueueStart;
        KbQueueWait;

        %% Screen
        KbQueueStop;
        text = ['The best way to remember the words in the pair is to think of an association between them.' ...
            '\n\nFor instance, if the pair is "library - oval", you could imagine an oval shaped library.' ...
            '\n\n Or if the pair is "picture - bread", you could imagine a picture of some bread.',...
            '\n\nTry to do this for every pair you see.'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        KbQueueStart;
        KbQueueWait;
       
        %% Screen
        KbQueueStop;
        text = ['Below you will see an example of what a list of word pairs will look like when you study it during the experiment.', ...
            '\n\nPress any key to begin'];
        DrawFormattedText(window, text,constants.leftMargin, constants.winRect(4)*.25, [],constants.wrapat,[],[],1.5);
        Screen('Flip', window);
        KbQueueStart;
        KbQueueWait;
        study(data, window, constants);
        DrawFormattedText(window, 'Press any key to continue', 'center', constants.winRect(4)*.9, [],constants.wrapat,[],[],1.5);
        Screen('Flip',window);
        KbQueueStart;
        KbQueueWait;
        
        %% Screen
        KbQueueStop;
        text = ['After you study each list of pairs, you will get a chance to practice some of the word pairs you just studied.' ...
            '\n\nSome of the pairs will be shown to you again, so you''ll have another chance to study them.'...
            '\n\nFor other pairs, you will take a practice test where you try to remember a word that is missing from the pair.'];
        drawInstructions(text, 'any key', constants.readtime*2, window, constants);
        KbQueueStart;
        KbQueueWait;
        
        %% Screen
        KbQueueStop;
        text = ['During the memory test, you will be shown a word on the left, but the word on the right will be missing.' ...
            '\n\nYour job is to remember the word that is missing from the pair, and type it in using the keyboard.'...
            '\n\nWhen you finish typing the missing word, press Enter to continue to the next pair.', ...
            '\n\nIf you do not type anything after 8 seconds, the test will automatically continue to the next pair.'];
        drawInstructions(text, 'any key', constants.readtime*2, window, constants);
        KbQueueStart;
        KbQueueWait;
        
        %% Screen
        KbQueueStop;
        text = 'Here is an example of a memory test. Type in the word you remember being paired with the given word and then press Enter.';
        keysOfInterest = zeros(1,256);
        keysOfInterest([65:90 KbName('BACKSPACE') KbName('RightArrow') KbName('RETURN')]) = 1;
        KbQueueCreate([], keysOfInterest);

        duration = constants.testDur;
        KbQueueStart;
        for j = [3 4 5]
            string = '';
            rt = [];
            advance = 0;
            inputFlag = 0;
            DrawFormattedText(window, text,constants.leftMargin, constants.winRect(4)*.25, [],constants.wrapat,[],[],1.5);
            drawCueTarget(data.cue{j}, '?', window, constants);
            vbl = Screen('Flip',window);
            while GetSecs < vbl + duration && advance == 0
                [string, rt, advance] = inputHandler([], string, rt, data.target{j});
                DrawFormattedText(window, text,constants.leftMargin, constants.winRect(4)*.25, [],constants.wrapat,[],[],1.5);
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
        end
        KbQueueRelease;
        
        %% Screen
        KbQueueCreate;
        DrawFormattedText(window, 'In case you missed some, the answers were "jacket", "pine" and "trunk"', constants.leftMargin, 'center', ...
            [], constants.wrapat, [],[], 1.5);
        DrawFormattedText(window, 'Press any key to continue', 'center', constants.winRect(4)*.9);
        Screen('Flip',window);
        KbQueueStart;
        KbQueueWait;

        %% Screen
        KbQueueStop;
        if strcmp('immediate', input.group)
            text = 'After you finish the practice phase for each lists, you will take a final memory test on the pairs from that list.';
        else
            text = 'After you study and practicing every lists, you will take a final memory test on pairs from all the lists.';
        end
        text = [text, '\n\nYour job on the final test is to recall the missing word from the pair and type it in, just like on the practice test.'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        KbQueueStart;
        KbQueueWait;
        
        %% Screen
        KbQueueStop;
        text = ['You will get a 5 minute break in between some of the lists.',...
            '\n\nDuring these breaks, you can relax by playing a game of Tetris which will popup on the screen.', ...
            '\n\nWhen its time to resume the experiment, your game will pause and the experiment will pick up where you left off'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        KbQueueStart;
        KbQueueWait;
        
        %% Screen
        KbQueueStop;
        text = ['That is everything you need to know to start the experiment. If you have any questions, please ask the experimenter now.' ...
            '\n\nIf not, press the Enter key to begin studying the first list of pairs!'];
        DrawFormattedText(window, text, constants.leftMargin, 'center',[],constants.wrapat,[],[],1.5);
        vbl= Screen('Flip',window,[],1);
	    Screen('Flip',window, vbl + constants.readtime);
        koi=zeros(1,256);
        koi(KbName('RETURN'))=1;
        KbQueueCreate([], koi);
        KbQueueStart;
        KbQueueWait;
        KbQueueRelease;
    
    case 'final'
        input = varargin{1};
        if strcmp('immediate', input.group)
            text = 'Its time for the final test on this list of pairs.';
        else
            text = 'Now it''s time for the final test. You will be test on pairs from all the lists you''ve studied in the entire experiment.';
        end
        text = [text '\n\nThe final test will begin in'];
        countdown(text, constants.finalTestCountdown, constants.countdownSpeed, window, constants)

    case 'resume'
        text = 'Welcome back! Its time to resume the experiment.';
        drawInstructions(text, 'any key', constants.ifi, window, constants);
           
    case 'bye'
        text = ['The experiment is over, thanks for participating!', ...
            '\n\nPlease let the RA know you have finished on your way out.'];
        DrawFormattedText(window,text, constants.leftMargin,'center',[],constants.wrapat,[],[],1.5);
        Screen('Flip',window);
        WaitSecs(10);
        
end
% Reset text size
% Screen('TextSize', window, oldTextSize);
end

function drawInstructions(text, advanceKey, when, window, constants, varargin)
    DrawFormattedText(window, text, constants.leftMargin, 'center', [], constants.wrapat ,[],[],1.5);
    vbl = Screen('Flip',window,[],1);
    msg = strjoin({'Press' advanceKey, 'to continue'}, ' ');
    DrawFormattedText(window, msg, 'center', constants.winRect(4)*.9, [], constants.wrapat, [],[], 1.5);
    Screen('Flip',window, vbl + when);
end