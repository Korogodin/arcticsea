clear
clc
close all

SMBV = CSMBV;
Rec = CReceiver;

[Stat] = SMBV.setConnection('192.168.1.22',5025);
if (Stat == 0)
    error('Connection problem')
end
[Stat] = SMBV.sendCommand('*RST; *CLS');
if (Stat == 0)
    error('Error')
end
[status, result] = SMBV.sendQuery('*OPC?');
if (status == 0 || result(1)~='1')
    return; 
end

[Stat, result] = SMBV.sendQuery('*IDN?');
if (Stat == 0)
    error('Error')
end
disp(result);
[status, result] = SMBV.sendQuery('SYST:SERR?');
if (result(1) ~= '0' || status == 0 )
disp (['*** Instrument error : ' result]);
return;
end

StartLevel = -111;
[Stat] = SMBV.setGPS(6);
if (Stat == 0)
    error('Error')
end
[Stat] = SMBV.setLevel(StartLevel);
if (Stat == 0)
    error('Error')
end
[Stat] = SMBV.sendCommand('OUTP ON');
if (Stat == 0)
    error('Error')
end

Rec.SerialConfig('COM7',115200);

Stat = Rec.SerialConnect;
if (Stat == 0)
    error('Serial: connection problem')
end

Rec.Reset;
tin_thislevel  = tic;

LevelStep = 1; PauseOnLevel = 90;
HaveFix = 0;
k = 1;
RecIsDead5sec = 0;
RecOkOnLastStep = 0;
Pow_arr = cell(1,1);
p = 1;
while (1)
    
    Rec.GetSolutionStatus;
    
    if (Rec.FixType == 3)
        RecOkOnLastStep = 1;
        HaveFix = 1;
        if (toc(tin_thislevel) > PauseOnLevel)
            LastOkLevel = SMBV.Level;
            Pow_arr{p,1} = [LastOkLevel 1];
            p = p + 1;
            if (LastOkLevel <= -111 && LastOkLevel >= -129) 
                LevelStep = 6;
            elseif (LastOkLevel <= -135 && LastOkLevel >= -145)
                LevelStep = 0.5;
            end
            SMBV.setLevel(LastOkLevel - LevelStep);
            tin_thislevel = tic;
        end
    elseif (Rec.FixType == 1 && RecOkOnLastStep == 1 )
        DeathTime = tic;
        RecOkOnLastStep = 0;
    end
    
    if (Rec.FixType == 1 && HaveFix == 1 )
    if ( toc(DeathTime) > 5 )
        RecIsDead5sec = 1;
    else
        RecIsDead5sec = 0;
    end
    end
    
    if (RecIsDead5sec == 1)
        ResultLevel(k) = LastOkLevel;
        k = k + 1;
        Pow_arr{p,1} = [(LastOkLevel - LevelStep) 0];
        p = p + 1;
        Rec.Reset;
        SMBV.setLevel(StartLevel);
        HaveFix = 0;
        RecOkOnLastStep = 0;
        RecIsDead5sec = 0;
        tin_thislevel  = tic;
    end
  
end


