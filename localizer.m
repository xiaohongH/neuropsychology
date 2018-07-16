%Presents images in fMRI experiment
%Record responses to one-back task.

%Operands to the || and && operators must be convertible to logical scalar values. 
%逻辑与和逻辑或，只能用于标量，不能用于向量，所以在实验过程中，按倒ctrl alt之类的find keycode是一个向量（两个值），导致出错，直接退出程序。
%同时按两个键find keycode也是一个向量（两个值），导致出错
try
    clear all;
    close all;
    clc;
    AssertOpenGL;
    oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel', 3);
    oldSupressAllWarnings = Screen('Preference', 'SuppressAllWarnings', 1);
    Screen('Preference','SkipSyncTests', 1);
    setupLocalizer;    
    %% Prepare Screen for Experiment
    HideCursor;
    screenNumber=max(Screen('Screens'));
    gray=GrayIndex(screenNumber);
    black=BlackIndex(screenNumber);
    %[window,screenRect]=Screen('OpenWindow',screenNumber,gray,[],8,2); % full SCREEN mode, in mid-level gray
    [window,screenRect]=Screen('OpenWindow',screenNumber,gray,[]);
    Screen('TextSize', window,30);
     %SETUP RECTS FOR IMAGE      
    facerect = [0 0 stimwidth stimheight];
    facerect = CenterRect(facerect, screenRect);
    %% Turn the images into Textures and Set Up Texture Order for Experiment
    faceindex=zeros(1,nimages);
    toolindex = zeros(1,nimages);
    %画出12张脸和12张工具，以便被testindex调用；
    %MakeTexture是指把代表图像的数值矩阵按照一定的格式放入显存中，使之能够被快速地显示出来，放入显存之后，这些数据被称为texture;
    %DraweTexture是把放入显存中的Texture写入帧缓存，也就是显示在屏幕上的过程。
    for number = 1:nimages
        imagename = eval(strcat('face',num2str(number))); 
        faceindex(number)=Screen('MakeTexture', window, imagename); 
        imagename = eval(strcat('tool',num2str(number))); 
        toolindex(number)=Screen('MakeTexture', window, imagename); 
    end
    
    %size(conditions,1)，获得conditions的行1和列2
    testindex = zeros(size(conditions,1),1);
    %congditions中一共有160个，16个trails * 10个blocks(runs);
    %10个run中.单数run为face，偶数run为tool
    for trial = 1:size(conditions,1)
        if conditions(trial,1) == 1 || conditions(trial,1) == 3 || conditions(trial,1) == 5 || conditions(trial,1) == 7 || conditions(trial,1) == 9
            testindex(trial) = faceindex(conditions(trial,2));
        elseif conditions(trial,1) == 2 || conditions(trial,1) == 4 || conditions(trial,1) == 6 || conditions(trial,1) == 8 || conditions(trial,1) == 10
            testindex(trial) = toolindex(conditions(trial,2));
        end
    end 
    %%
    %%%%%Prep Port
    if ~DEBUG
        [P4, openerror] = IOPort('OpenSerialPort', 'COM6','BaudRate=19200'); %opens port for receiving scanner pulse
        IOPort('Flush', P4); %flush event buffer
    end
    % SHOW READY TEXT
    DrawFormattedText(window, waitingtext, 'center', 'center', black);
    DrawFormattedText(window, waitingtextt, 'center', 460, black);
    Screen('Flip', window); % Shows 'READY text'
    Screen('TextSize', window,40);
  
    
    while 1
        if ~DEBUG
            [pulse,temptime,readerror] = IOPort('read7',P4,1,1);
            scanstart = GetSecs;
        else
            [keyIsDown,secs,keyCode] = KbCheck; 
            if keyCode(83) % If 83--s; 49--1 i              s pressed on the keyboard
                pulse = 83;
            end
            scanstart = GetSecs; %按下ctrl+s时刻开始计时
        end
        if ~isempty(pulse) && (pulse == 83) %如果ctrl+s已经被按下，则退出程序
            break;
        end
    end   
    
    
       %% START TRIALS
    %the time when pressed s after ready text;
    begintime = GetSecs; 
    trial = 1;
    fixation = 1;
    presentations = zeros(ntrials,5);  %160行5列,存储什么image在什么时候出现，什么时候呈现结束；
    botpress = zeros(ntrials,1); %160 after see a picture ,require subject to pree a key,botpress stores the keynumber;
    timepress = zeros(ntrials,1); %160 after see a picture ,require subject to pree a key,timepress stores the time:when fixation time end ---to---the time subject press the key;
    %PREP FOR FIRST FIXATION
    DrawFormattedText(window, fixationtext, 'center', 'center', black);
      
    %%
    %一共有160个trials
    while trial <= size(conditions,1) %plus one allows for final fixation   
            if fixation == 1; %1 fixation block
                %%  
                Screen('Flip', window); %Shows fist fixation
                starttime = GetSecs; %at the mimute presented fixation;
                while GetSecs - starttime < fixationtime-.2 %在显示fixation的过程中，先在后台绘制好要显示的image and fixation,以便等会调用！妙！
                    fixation =0;
                    pluse =0;
                    Screen('DrawTexture', window, testindex(trial), [], facerect);  
                    DrawFormattedText(window, fixationtext, 'center', 'center', black);
                    Screen('DrawingFinished', window);
                end
                
                 while 1
                     if ~DEBUG
                       [pulse,temptime,readerror] = IOPort('read',P4,1,1);
                       scanstart = GetSecs;
                     else
                       [keyIsDown,secs,keyCode] = KbCheck; 
                     if keyCode(83) % If s is pressed on the keyboard
                        pulse = 83;
                     end
                       scanstart = GetSecs;
                     end
                     if ~isempty(pulse) && (pulse == 83)
                       break;
                     end
                 end   
            %%
            else % PRESENT IMAGE BLOCK    
               
                  %% show image
                Screen('Flip', window);%显示之前在后台已经绘制好的image；
                starttime1 = GetSecs;%at the minute presented first image;
                %presentations160行5列，1列：160个trails；2列：face的名称；3列：1或者2；4列：the time when pressed s after ready text;5列：at the minute presented first image;       
                presentations (trial,:) = [conditions(trial,:), begintime, starttime1];
                DrawFormattedText(window, fixationtext, 'center', 'center', black);
                if ~DEBUG              
                    while 1
                        while 1
                            pulse=IOPort('read',P4,0,1);
                            %如果被试按键了就记录按键和时间，然后退出；
                            if ~isempty(pulse) && (pulse ~= 83) 
                                botpress(trial,1)=pulse;
                                %在显示图片的过程中记录被试的反应时；
                                %RT = timepress =做出反应的一刻-显示图片的一刻，
                                timepress(trial,1)=GetSecs-starttime1;
                                break
                            end
                            %如果被试没有按键，等待testtime的时间后继续；
                            if GetSecs-starttime1>=testtime
                                break
                            end
                        end
                        if GetSecs-starttime1>=testtime
                                break
                        end
                    end  
                else 
                     while 1
                        while 1
                           [keyIsDown,secs,keyCode] = KbCheck;
                           pulse = find(keyCode);
                             %如果被试按键了就记录按键和时间，然后退出；
                            if ~isempty(pulse) && (pulse ~= 83)
                                botpress(trial,1)=pulse;
                                timepress(trial,1)=GetSecs-starttime1;
                                break
                            end
                             %如果被试没有按键，等待testtime的时间后继续；
                            if GetSecs-starttime1>=testtime
                                break
                            end
                        end
                        
                        if GetSecs-starttime1>=testtime
                                break
                        end
                     end 
                end
                
                %%  show fixation 
                Screen('Flip', window); % 画出之前已经在后台绘制好的fixation         
                trial = trial+1;
                Screen('DrawTexture', window, testindex(trial), [], facerect); 
                DrawFormattedText(window, fixationtext, 'center', 'center', black);
                Screen('DrawingFinished', window);
                if ~DEBUG                 
                    while 1
                        while 1
                            pulse=IOPort('read',P4,0,1);
                            if ~isempty(pulse) && (pulse ~= 83)
                                botpress(trial,1)=pulse;
                                
                                timepress(trial,1)=GetSecs-starttime1;
                                break
                            end
                            if GetSecs-starttime1>=testtime+posttime
                                break
                            end
                        end
                        if GetSecs-starttime1>=testtime+posttime
                                break
                        end
                    end
                else 
                     while 1
                        while 1
                           [keyIsDown,secs,keyCode] = KbCheck;
                           pulse = find(keyCode);
                            if ~isempty(pulse) && (pulse ~= 83)
                                botpress(trial,1)=pulse;
                                %starttime1 == at the minute presented first image;
                                %在显示fixation的过程中记录被试的反应时；
                                %RT = timepress =做出反应的一刻-显示图片的一刻，
                                timepress(trial,1)=GetSecs-starttime1;
                                break
                            end
                            %如果被试没有做出反应，则fixation显示的时间为posttime
                            if GetSecs-starttime1>=testtime+posttime
                                break
                            end
                        end
                        if GetSecs-starttime1>=testtime+posttime
                                break
                        end
                     end 
                end       
                %%
                %Show Second image
                Screen('Flip', window);
                % %starttime2 == at the minute presented second image;
                starttime2 = GetSecs;            
                %presentations160行5列，1列：160个trails；2列：face的名称；3列：1或者2；4列：the time when pressed s after ready text;5列：at the minute presented first image;    
                presentations (trial,:) = [conditions(trial,:), begintime, starttime2];
                DrawFormattedText(window, fixationtext, 'center', 'center', black);
               if ~DEBUG            
                    while 1
                        while 1
                            pulse=IOPort('read',P4,0,1);
                            if ~isempty(pulse) && (pulse ~= 83)
                                botpress(trial,1)=pulse;
                                timepress(trial,1)=GetSecs-starttime2;
                                break
                            end
                            if GetSecs-starttime1>=testtime+testtime+posttime
                                break
                            end
                        end
                        if GetSecs-starttime1>=testtime+testtime+posttime
                                break
                        end
                    end
                else 
                     while 1
                        while 1
                           [keyIsDown,secs,keyCode] = KbCheck;
                           pulse = find(keyCode);
                            if ~isempty(pulse) && (pulse ~= 83)
                                botpress(trial,1)=pulse;
                                timepress(trial,1)=GetSecs-starttime2;
                                break
                            end
                            if GetSecs-starttime1>=testtime+testtime+posttime
                                break
                            end
                        end
                        if GetSecs-starttime1>=testtime+testtime+posttime
                                break
                        end
                     end 
               end
               %%
                Screen('Flip', window); % draw fixation             
                if ~DEBUG
                    while 1
                        while 1
                            pulse=IOPort('read',P4,0,1);
                            if ~isempty(pulse) && (pulse ~= 83)
                                botpress(trial,1)=pulse;
                                timepress(trial,1)=GetSecs-starttime2;
                                break
                            end
                            if GetSecs-starttime1>=TR
                                break
                            end
                        end
                        if GetSecs-starttime1>=TR
                                break
                        end
                    end
                else 
                     while 1
                        while 1
                           [keyIsDown,secs,keyCode] = KbCheck;
                           pulse = find(keyCode);
                            if ~isempty(pulse) && (pulse ~= 83)
                                botpress(trial,1)=pulse;
                                timepress(trial,1)=GetSecs-starttime2;
                                break
                            end
                            %at the minute presented first image;
                            %画第二张fixation结束的时间 - 画第一张image的时间 = TR（TR为呈现两张图片的时间 = image+fixation+image+fixation）
                            if GetSecs-starttime1>=TR
                                break
                            end
                        end
                        if GetSecs-starttime1>=TR
                                break
                        end
                     end 
                end           
                trial = trial+1;%trials =3;
                %%
                   %End of current dynamic scan prep for next trial
                   %if trials<16,then draw fixationtex;
                   %else draw face+fixationtext
                if mod(trial, nimages+noneback)== 1  %if trial ==16,then draw fixation
                    fixation = 1;
                    DrawFormattedText(window, fixationtext, 'center', 'center', black);
                                                    %if trial <16,then draw trial 3;
                else
                    Screen('DrawTexture', window, testindex(trial), [], facerect);     
                    DrawFormattedText(window, fixationtext, 'center', 'center', black);
                    Screen('DrawingFinished', window);
                end
            end
    end
       %% Final Fixation
    while 1
        if ~DEBUG
            [pulse,temptime,readerror] = IOPort('read',P4,1,1);
            scanstart = GetSecs;
        else
            [keyIsDown,secs,keyCode] = KbCheck; 
            if keyCode(83) % If s is pressed on the keyboard
                pulse = 83;
            end
            scanstart = GetSecs;
        end
        if ~isempty(pulse) && (pulse == 83)
            break;
        end
    end    
    DrawFormattedText(window, fixationtext, 'center', 'center', black);
    Screen('Flip', window); % Shows fixation
    starttime = GetSecs;
    while GetSecs - starttime < fixationtime
    end
    endtime = GetSecs;
    toalexptime = endtime - btegintime;
    save(sprintf('data\\data_%s.mat', sid), 'presentations', 'botpress','timepress');   
  
catch ME
    display(sprintf('Error in Experiment. Please get experimenter.'));
    Priority(0);
    ShowCursor
    Screen('CloseAll');
end
ShowCursor
Screen('CloseAll');