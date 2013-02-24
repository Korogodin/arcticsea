clear
clc
close all

SMBV = CSMBV;
Rec = CReceiver;

[Stat] = SMBV.setConnection('192.168.0.30',5025);
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

Rec.SerialConfig('COM4',115200);

Stat = Rec.SerialConnect;
if (Stat == 0)
    error('Serial: connection problem')
end

Rec.Reset;
tin_thislevel  = tic;

LevelStep = 1; PauseOnLevel = 120;
HaveFix = 0;
k = 0;

while (1)
    
    Rec.GetSolutionStatus;
    
    if (Rec.FixType == 3)
        HaveFix = 1;
        if (toc(tin_thislevel) > 120)
            LastOkLevel = SMBV.Level;
            SMBV.setLevel(LastOkLevel - LevelStep);
            tin_thislevel = tic; 
        end
    elseif (Rec.FixType == 1) 
        if (HaveFix == 1)
            DeathTime = tic;
            if (toc(DeathTime) > 5)
                ResultLevel(k) = LastOkLevel;
                k = k + 1;
                Rec.Reset;
                HaveFix = 0;
            end
        end
    end
    
end