function []= giveInstructions(phase_name, inputHandler, window, constants, varargin)
  %UNTITLED4 Summary of this function goes here
  %   Detailed explanation goes here

oldTextSize=Screen('TextSize', window, 28);

%%------------------------------------------------------------------------
% Study Instructions
%-------------------------------------------------------------------------
% ListenChar(2);
switch phase_name
    case 'intro'
        input = varargin{1}; %#ok<NASGU>
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
        text = 'The word pairs you will learn always have one word on the left side of the screen, and a second word on the right side of the screen.';
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        KbQueueStart;        
        KbQueueWait;
        
        %% Screen
        KbQueueStop;        
        text = ['The best way to remember the words in the pair is to think of an association between them.' ...
            '\n\nFor instance, if the pair is "library - oval", you could imagine an oval shaped library.' ...
            '\n\nTry to do this for every pair you see.'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        KbQueueStart;        
        KbQueueWait;
        
        %% Screen
        KbQueueStop;
        text = 'Below is an example of what a pair of words will look like when you study it during the experiment';        
        DrawFormattedText(window, text,'center', constants.winRect(4)*.25, [],constants.wrapat,[],[],1.5);        
        drawCueTarget('pencil', 'cave', window, constants);
        vbl = Screen('Flip',window,[],1);
        DrawFormattedText(window, 'Press any key to continue', 'center',constants.winRect(4)*.9,[],constants.wrapat,[],[],1.5);
        Screen('Flip',window, vbl + constants.readtime);
        KbQueueStart;        
        KbQueueWait;
        
        %% Screen
        KbQueueStop;
        text = ['During the memory test, you will be shown a word on the left, but the word that was shown on the right during study will be missing.' ...
            '\n\nYour job is to recall the missing word from the pair, and type it in using the keyboard.'...
            '\n\nWhen you are finished typing the missing word, press Enter to continue to the next pair.'];
        drawInstructions(text, 'any key', constants.readtime*2, window, constants);
        KbQueueStart;      
        KbQueueWait;

        %% Screen
        KbQueueStop;
        text = 'Here is an example of a memory test. Type in the word you remember being paired with "pencil" and press Enter';
        DrawFormattedText(window, text,'center', constants.winRect(4)*.25, [],constants.wrapat,[],[],1.5);
        Screen('Flip',window,[],1);
%         contants.testDur = 30;
%        testing('pencil', inputHandler, window, constants)
        DrawFormattedText(window, 'In case you missed it, the answer was "cave"', 'center', constants.winRect(4)*.75);
        DrawFormattedText(window, 'Press any key to continue', 'center', constants.winRect(4)*.9);
        Screen('Flip',window);
        KbQueueStart;        
        KbQueueWait;
        
        %% Screen
        KbQueueStop;
        text = ['Thats everything you need to know to start the experiment. If you have any questions, please ask the experimenter now.' ... 
            '\n\nIf not, press the Enter key to begin studying the first list of pairs!'];
        DrawFormattedText(window, text, 'center', 'center',[],constants.wrapat,[],[],1.5);
        vbl= Screen('Flip',window,[],1);
	    Screen('Flip',window, vbl + constants.readtime);
        koi=zeros(1,256);
        koi(KbName('RETURN'))=1;
        KbQueueCreate([], koi);
        KbQueueStart;        
        KbQueueWait;
        KbQueueRelease;
end

% Reset text size
Screen('TextSize', window, oldTextSize);
end

function drawInstructions(text, advanceKey, when, window, constants, varargin)

    DrawFormattedText(window, text, 'center','center', [], constants.wrapat,[],[],1.5);
    vbl = Screen('Flip',window,[],1);
    msg = strjoin({'Press' advanceKey, 'to continue'}, ' ');
    DrawFormattedText(window, msg, 'center',constants.winRect(4)*.9,[],constants.wrapat,[],[],1.5);
    Screen('Flip',window, vbl + when);
end