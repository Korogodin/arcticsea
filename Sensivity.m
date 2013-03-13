SMBV = CSMBV;
Rec = CReceiver;

%���������� � SMBV
[Stat] = SMBV.SetConnection('192.168.1.22',5025);
if (Stat == 0)
    error('Connection problem')
end
%����� �������� SMBV � ���������, ������� ���� ������
[Stat] = SMBV.Preset;
if (Stat == 0)
    error('Error')
end
%�������������
[status, result] = SMBV.SendQuery('*OPC?');
if (status == 0 || result(1)~='1')
    return; 
end
%������ ������, ��������� ������
[Stat, result] = SMBV.GetIDN;
if (Stat == 0)
    error('Error')
end
disp(result);
%�������� ��������� ������
[status, result] = SMBV.SendQuery('SYST:SERR?');
if (result(1) ~= '0' || status == 0 )
disp (['*** Instrument error : ' result]);
return;
end
%��������� ��������� ������������
StartLevel = -95; % ��������� �������� �������
%������ �������� ������� GPS
[Stat] = SMBV.SetGPS(6);
if (Stat == 0)
    error('Error')
end
%��������� ��������� ��������
[Stat] = SMBV.SetLevel(StartLevel);
if (Stat == 0)
    error('Error')
end
[Stat] = SMBV.SendCommand('OUTP ON');
if (Stat == 0)
    error('Error')
end

%��������� ���������� � ����������
Rec.SerialConfig('COM6',115200);
%���������� � ����������
Stat = Rec.SerialConnect;
if (Stat == 0)
    error('Serial: connection problem')
end
%������������ ���������, ������ ������� ������� �� ����� ��������
Rec.Reset;
pause(70);
tin_thislevel = tic;

%��������� ������������: ��� ��������� ��������, �������� �� ��������
LevelStep = 1; PauseOnLevel = 30;
HaveFix = 0;
k = 1;
RecIsDead5sec = 0;
RecOkOnLastStep = 0;
Pow_arr = cell(1,1);
p = 1;
m = 0;

%���� ������������
while (1)
    
    Rec.GetSolutionStatus;
    
    if (Rec.FixType == 3)
        RecOkOnLastStep = 1;
        HaveFix = 1;
        if (toc(tin_thislevel) > PauseOnLevel)
            LastOkLevel = SMBV.Level;
            Pow_arr{p,1} = [LastOkLevel 1];
            p = p + 1;
            if (LastOkLevel <= -95 && LastOkLevel >= -118) 
                LevelStep = 8;
            elseif (LastOkLevel == -119)
                LevelStep = 2;
            elseif (LastOkLevel <= -120 && LastOkLevel >= -135)
                LevelStep = 0.5;
            end
            Stat = SMBV.SetLevel(LastOkLevel - LevelStep);
            if (Stat == 0)
                error('SMBV error')
            end
            tin_thislevel = tic;
        end
    elseif ((Rec.FixType == 1 || Rec.FixType == 2) && RecOkOnLastStep == 1 )
        DeathTime = tic;
    end
   
    if ((Rec.FixType == 1 || Rec.FixType ==2) && HaveFix == 1 && RecOkOnLastStep == 0 )
    if ( toc(DeathTime) > 5 )
        RecIsDead5sec = 1;
    else
        RecIsDead5sec = 0;
    end
    end
    
    if (Rec.FixType == 1 || Rec.FixType == 2)
        RecOkOnLastStep = 0;
    end
    
    if (RecIsDead5sec == 1)
        ResultLevel(k) = LastOkLevel;
        k = k + 1;
        Pow_arr{p,1} = [(LastOkLevel - LevelStep) 0];
        p = p + 1;
        file = [num2str(m) 'MSHUpower.mat'];
        save(file, 'Pow_arr');
        m = m + 1;
        Rec.Reset;
        SMBV.SetLevel(StartLevel);
        HaveFix = 0;
        RecOkOnLastStep = 0;
        RecIsDead5sec = 0;
        toc(DeathTime);
        pause(70);
        tin_thislevel  = tic;
               
    end
  
end


