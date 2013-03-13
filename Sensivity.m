SMBV = CSMBV;
Rec = CReceiver;

%соединение с SMBV
[Stat] = SMBV.SetConnection('192.168.1.22',5025);
if (Stat == 0)
    error('Connection problem')
end
%сброс настроек SMBV в дефолтные, очистка лога ошибок
[Stat] = SMBV.Preset;
if (Stat == 0)
    error('Error')
end
%синхронизация
[status, result] = SMBV.SendQuery('*OPC?');
if (status == 0 || result(1)~='1')
    return; 
end
%запрос модели, серийного номера
[Stat, result] = SMBV.GetIDN;
if (Stat == 0)
    error('Error')
end
disp(result);
%проверка системных ошибок
[status, result] = SMBV.SendQuery('SYST:SERR?');
if (result(1) ~= '0' || status == 0 )
disp (['*** Instrument error : ' result]);
return;
end
%начальные настройки эксперимента
StartLevel = -95; % стартовая мощность сигнала
%запуск имитации сигнала GPS
[Stat] = SMBV.SetGPS(6);
if (Stat == 0)
    error('Error')
end
%установка стартовой мощности
[Stat] = SMBV.SetLevel(StartLevel);
if (Stat == 0)
    error('Error')
end
[Stat] = SMBV.SendCommand('OUTP ON');
if (Stat == 0)
    error('Error')
end

%Настройка соединения с приемником
Rec.SerialConfig('COM6',115200);
%Соединение с приемником
Stat = Rec.SerialConnect;
if (Stat == 0)
    error('Serial: connection problem')
end
%Перезагрузка приемника, запуск отсчета времени на даннй мощности
Rec.Reset;
pause(70);
tin_thislevel = tic;

%Параметры эксперимента: шаг изменения мощности, ожидание на мощности
LevelStep = 1; PauseOnLevel = 30;
HaveFix = 0;
k = 1;
RecIsDead5sec = 0;
RecOkOnLastStep = 0;
Pow_arr = cell(1,1);
p = 1;
m = 0;

%цикл эксперимента
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


