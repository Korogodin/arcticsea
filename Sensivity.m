SMBV = CSMBV;
Rec = CReceiver;

%установка соединения с SMBV
[Stat] = SMBV.SetConnection('192.168.1.22',5025);
if (Stat == 0)
    error('Connection problem')
end

%сброс настроек SMBV в дефолтные
[Stat] = SMBV.Preset;
if (Stat == 0)
    error('Error')
end

%запрос модели/серийного номера
[Stat, result] = SMBV.SendQuery('*IDN?');
if (Stat == 0)
    error('Error')
end
disp(result);

%проверка на системные ошибки
[status, result] = SMBV.SendQuery('SYST:SERR?');
if (result(1) ~= '0' || status == 0 )
disp (['*** Instrument error : ' result]);
return;
end

%начальный уровень мощности для каждого эксперимента
StartLevel = -111;

%запуск имитации спутников
[Stat] = SMBV.SetGPS(4);
if (Stat == 0)
    error('Error')
end

%установка мощности сигнала
[Stat] = SMBV.SetLevel(StartLevel);
if (Stat == 0)
    error('Error')
end

%включение RF выхода
[Stat] = SMBV.SetRFOutput('ON');
if (Stat == 0)
    error('Error')
end

%настройка соединения с приемником
Rec.SerialConfig('COM6',115200);

%установка соединения с приемником
Stat = Rec.SerialConnect;
if (Stat == 0)
    error('Serial: connection problem')
end

%перезагрузка приемника, начало отсчета времени нахождения на данной мощности
Rec.Reset;
tin_thislevel  = tic;

%шаг мощности, другие параметры эксперимента
LevelStep = 1; PauseOnLevel = 90;
HaveFix = 0;
k = 1;
RecIsDead5sec = 0;
RecOkOnLastStep = 0;
Pow_arr = cell(1,1);
p = 0;
m = 0;

%цикл эксперимента
while (1)
    
    Rec.GetSolutionStatus;
    
    if (Rec.FixType == 3)
        RecOkOnLastStep = 1;
        HaveFix = 1;
        if (toc(tin_thislevel) > PauseOnLevel)
            LastOkLevel = SMBV.Level;
            p = p + 1;
            Pow_arr{p,1} = [LastOkLevel 1];
            if (LastOkLevel <= -111 && LastOkLevel >= -128) 
                LevelStep = 6;
            elseif (LastOkLevel == -129)
                LevelStep = 2;
            elseif (LastOkLevel <= -130 && LastOkLevel >= -160)
                LevelStep = 0.5;
            end
            SMBV.SetLevel(LastOkLevel - LevelStep);
            tin_thislevel = tic;
        end
    elseif (Rec.FixType == 1 && RecOkOnLastStep == 1 )
        DeathTime = tic;
    end
   
    if (Rec.FixType == 1 && HaveFix == 1 && RecOkOnLastStep == 0 )
    if ( toc(DeathTime) > 5 )
        RecIsDead5sec = 1;
    else
        RecIsDead5sec = 0;
    end
    end
    
    if (Rec.FixType == 1)
        RecOkOnLastStep = 0;
    end
    
    if (RecIsDead5sec == 1)
        ResultLevel(k) = LastOkLevel;
        k = k + 1;
        Pow_arr{p,1} = [(LastOkLevel - LevelStep) 0];
        p = p + 1;
        file = [num2str(m) 'newpower.mat'];
        save(file, 'Pow_arr');
        m = m + 1;
        SMBV.SetLevel(StartLevel);
        HaveFix = 0;
        RecOkOnLastStep = 0;
        RecIsDead5sec = 0;
        tin_thislevel  = tic;
        Rec.Reset;
        toc(DeathTime);
    end
  
end


