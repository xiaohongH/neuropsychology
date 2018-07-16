% Experimental session parameters:
filename=[];
while isempty(filename)
    filename=input('Enter name of data file: ', 's');
    if filename == ' '
        filename = [];
    end
end
run = [];
temprun = input('Enter run number:\n');
while isempty(run)
    sid = strcat(filename, '_local', num2str(temprun));
    sd = exist(sprintf('data\\%s.mat', sid));
    if(sd > 0)
        temprun = input('You have already done this run, please pick a new run:\n');
    else
        run = temprun;
    end
end
DEBUG = input('Are we debugging? 0 or 1:\n');
s = RandStream('mt19937ar','Seed', sum(100*clock));
%RandStream.setGlobalStream(s); 
%%%%%%timing
posttime = 0.5; % fixation time
testtime = 0.5; % image time
TR = 2;  %TR（TR为呈现两张图片的时间 = image+fixation+image+fixation）
fixationtime = 5;
%*******************************
nreps = 5; % number of image repetitions per run
nconds = 2; %刺激的种类，脸和工具
nimages = 12; %一个run中有12张图片%
noneback = 4;%一个block中重复图片的个数
%% Create List of Trial Parameters conditions
    ntrials = nconds*(nimages+noneback)*nreps; %16*2*5 = 160
    conditions = zeros(ntrials,3);
    trialindex = 1;
    randruns=randperm(10);
    for rep = 1:nreps
        conds = [randruns(rep*2-1) randruns(rep*2)];
        for condindex = 1:nconds
            %12 photos random%
            randimage = randperm(nimages); 
            temp = randperm(nimages);  
            %the first four numbers %
            randtrial =[temp(1),temp(2),temp(3),temp(4)];%12张脸的图片，16个trials，所以有4张是重复的；
            for i = 1:(nimages)
                conditions(trialindex,:) = [conds(condindex) randimage(i) 0];% fifth colum of conditions will indicate whether it is a repeat
                trialindex = trialindex+1;
                if randtrial(1) == i || randtrial(2) == i || randtrial(3) == i|| randtrial(4) == i  % IF this is the randomly selected trial to be repeated
                    conditions(trialindex,:) = [conds(condindex) randimage(i) 1];% fifth colum of conditions will indicate whether it is a repeat
                    trialindex = trialindex +1;
                end                
            end
        end
    end
%*************************************
%Load Stimuli
load sti_loc
[stimheight, stimwidth] = size(face1); 
fixationtext = '+';
waitingtext = 'task is new face/house detection';
waitingtextt = '                                 ';
pulse = [];