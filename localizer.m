%Presents images in fMRI experiment
%Record responses to one-back task.

%Operands to the || and && operators must be convertible to logical scalar values. 
%�߼�����߼���ֻ�����ڱ�������������������������ʵ������У�����ctrl alt֮���find keycode��һ������������ֵ�������³���ֱ���˳�����
%ͬʱ��������find keycodeҲ��һ������������ֵ�������³���
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
    %����12������12�Ź��ߣ��Ա㱻testindex���ã�
    %MakeTexture��ָ�Ѵ���ͼ�����ֵ������һ���ĸ�ʽ�����Դ��У�ʹ֮�ܹ������ٵ���ʾ�����������Դ�֮����Щ���ݱ���Ϊtexture;
    %DraweTexture�ǰѷ����Դ��е�Textureд��֡���棬Ҳ������ʾ����Ļ�ϵĹ��̡�
    for number = 1:nimages
        imagename = eval(strcat('face',num2str(number))); 
        faceindex(number)=Screen('MakeTexture', window, imagename); 
        imagename = eval(strcat('tool',num2str(number))); 
        toolindex(number)=Screen('MakeTexture', window, imagename); 
    end
    
    %size(conditions,1)�����conditions����1����2
    testindex = zeros(size(conditions,1),1);
    %congditions��һ����160����16��trails * 10��blocks(runs);
    %10��run��.����runΪface��ż��runΪtool
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
            scanstart = GetSecs; %����ctrl+sʱ�̿�ʼ��ʱ
        end
        if ~isempty(pulse) && (pulse == 83) %���ctrl+s�Ѿ������£����˳�����
            break;
        end
    end   
    
    
       %% START TRIALS
    %the time when pressed s after ready text;
    begintime = GetSecs; 
    trial = 1;
    fixation = 1;
    presentations = zeros(ntrials,5);  %160��5��,�洢ʲôimage��ʲôʱ����֣�ʲôʱ����ֽ�����
    botpress = zeros(ntrials,1); %160 after see a picture ,require subject to pree a key,botpress stores the keynumber;
    timepress = zeros(ntrials,1); %160 after see a picture ,require subject to pree a key,timepress stores the time:when fixation time end ---to---the time subject press the key;
    %PREP FOR FIRST FIXATION
    DrawFormattedText(window, fixationtext, 'center', 'center', black);
      
    %%
    %һ����160��trials
    while trial <= size(conditions,1) %plus one allows for final fixation   
            if fixation == 1; %1 fixation block
                %%  
                Screen('Flip', window); %Shows fist fixation
                starttime = GetSecs; %at the mimute presented fixation;
                while GetSecs - starttime < fixationtime-.2 %����ʾfixation�Ĺ����У����ں�̨���ƺ�Ҫ��ʾ��image and fixation,�Ա�Ȼ���ã��
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
                Screen('Flip', window);%��ʾ֮ǰ�ں�̨�Ѿ����ƺõ�image��
                starttime1 = GetSecs;%at the minute presented first image;
                %presentations160��5�У�1�У�160��trails��2�У�face�����ƣ�3�У�1����2��4�У�the time when pressed s after ready text;5�У�at the minute presented first image;       
                presentations (trial,:) = [conditions(trial,:), begintime, starttime1];
                DrawFormattedText(window, fixationtext, 'center', 'center', black);
                if ~DEBUG              
                    while 1
                        while 1
                            pulse=IOPort('read',P4,0,1);
                            %������԰����˾ͼ�¼������ʱ�䣬Ȼ���˳���
                            if ~isempty(pulse) && (pulse ~= 83) 
                                botpress(trial,1)=pulse;
                                %����ʾͼƬ�Ĺ����м�¼���Եķ�Ӧʱ��
                                %RT = timepress =������Ӧ��һ��-��ʾͼƬ��һ�̣�
                                timepress(trial,1)=GetSecs-starttime1;
                                break
                            end
                            %�������û�а������ȴ�testtime��ʱ��������
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
                             %������԰����˾ͼ�¼������ʱ�䣬Ȼ���˳���
                            if ~isempty(pulse) && (pulse ~= 83)
                                botpress(trial,1)=pulse;
                                timepress(trial,1)=GetSecs-starttime1;
                                break
                            end
                             %�������û�а������ȴ�testtime��ʱ��������
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
                Screen('Flip', window); % ����֮ǰ�Ѿ��ں�̨���ƺõ�fixation         
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
                                %����ʾfixation�Ĺ����м�¼���Եķ�Ӧʱ��
                                %RT = timepress =������Ӧ��һ��-��ʾͼƬ��һ�̣�
                                timepress(trial,1)=GetSecs-starttime1;
                                break
                            end
                            %�������û��������Ӧ����fixation��ʾ��ʱ��Ϊposttime
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
                %presentations160��5�У�1�У�160��trails��2�У�face�����ƣ�3�У�1����2��4�У�the time when pressed s after ready text;5�У�at the minute presented first image;    
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
                            %���ڶ���fixation������ʱ�� - ����һ��image��ʱ�� = TR��TRΪ��������ͼƬ��ʱ�� = image+fixation+image+fixation��
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