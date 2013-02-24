classdef CSMBV < handle
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        RefPoW
        Level
        Instr
    end
    
    methods
        %конструктор
        function RS = CSMBV
            
        end
        %установка соединения
        function [Status] = setConnection(RS, IP, port)
            Status = 0;
            RS.Instr = tcpip(IP, port);
%             set(RS.Instr, InputBufferSize, 2000);
%             set(RS.Instr, OutputBufferSize, 2000);
            fopen(RS.Instr);
            if  strcmp(get(RS.Instr,'Status'),'open')
                disp('Connection OK');
                Status = 1;
            else 
                disp('Connection Problem');
                return;
            end
        end
        
        %закрытие соединения с возвратом к ручному управлению
        function closeConnection(RS)
            fprintf(RS.Instr,'&GTL');
            fclose(RS.Instr);
        end
        
        %Отправка команды
        function [Status] = sendCommand(RS, strCommand)
            Status = 0;
            % проверка количества входных аргументов
            if( nargin ~= 2 )
                disp( '*** Wrong number of input arguments' )
                return;
            end
            
            % проверка 1го параметра
            if( isobject(RS) ~= 1 )
                disp( '*** The first parameter is not an object.' );
                return;
            end
           
            % проверка 2го параметра 
            if( isempty(strCommand) || (ischar(strCommand)~= 1) )
                disp ('*** Command string is empty or not a string.');
                return;
            end
            
            %Собственно отправка команды
            fprintf (RS.Instr, strCommand);
            Error = queryError(RS);
            if (Error==1)
                return;
            end
            Status = 1;
        end
        
        %Отправка запроса и получение ответа
        function [Status, Result] = sendQuery(RS, strCommand)
            Status = 0;
            Result = '';
            
            % проверка количества входных аргументов
            if( nargin ~= 2 )
                disp( '*** Wrong number of input arguments' )
                return;
            end
            
            % проверка 1го параметра
            if( isobject(RS) ~= 1 )
                disp( '*** The first parameter is not an object.' );
                return;
            end
           
            % проверка 2го параметра 
            if( isempty(strCommand) || (ischar(strCommand)~= 1) )
                disp ('*** Command string is empty or not a string.');
                return;
            end
            
            % Проверка, есть ли в команде запрос
            if( isempty( strfind(strCommand, '?' ) ) )
                disp( '*** Queries must end with a question mark.' );
                return;
            end
            
            % Отправка запроса и получение результата
            
                fprintf (RS.Instr, strCommand);
                Result = fscanf(RS.Instr, '%c');
                Status = 1;
            
        end
         
       %опрос на предмет ошибок
       function [Err] = queryError(RS)
            Result = '1';
            Counter = 0;
            Err = 0;
            % query for errors in a loop until "0, No error" is returned
            % and limit the number of iterations to 100
            while (Result(1) ~= '0' && Counter < 100)
                [status, Result] = sendQuery(RS, 'SYST:ERR?');
                if (status == 0)
                    disp( '*** Error occurred' );
                    Err = 1;
                    break;
                end
                if (Result(1)~='0')
                    disp (['*** Instrument Error: ' Result]);
                    Err = 1;
                end
                Counter = Counter + 1;
            end
       end
       %регулировка выходной мощности
       function [Status] = setLevel(RS, Level)
           Status = 0;
           RS.Level = Level;
           [Stat] = RS.sendCommand(sprintf('SOUR:POW %.1f', Level));
           if (Stat == 0)
               return;
           end
           Status = 1;
       end
       
       %установка частоты
       function [Status] = setFreq(RS, Freq)
           Status = 0;
           if (ischar(Freq))
               [Stat] = RS.sendCommand(['SOUR:FREQ ' Freq]);
               if ( Stat == 0)
                   return;
               end
           else
               [Stat] = RS.sendCommand(sprintf('SOUR:FREQ %.5f', Freq));
               if ( Stat == 0)
                   return;
               end
           end
           Status = 1;
       end
       
       %Инициализация GPS сценария
       function [Status] = setGPS(RS, SatNumber)
           Status = 0;
%           RS.RefPoW = RefPow;
          [Stat] = RS.sendCommand('SOUR:BB:GPS:PRES');
          if (Stat == 0)
              return;
          end
          [Stat, result] = RS.sendQuery('*OPC?');
          if (Stat == 0 || result(1)~='1')
              return;
          end
          [Stat] = RS.sendCommand('SOUR:BB:GPS:STAT OFF');
          if (Stat == 0)
              return;
          end
          [Stat] = RS.sendCommand('SOUR:BB:GPS:SMODE USER');
          if (Stat == 0)
              return;
          end
          [Stat] = RS.sendCommand('SOUR:BB:GPS:LOC:SEL "Moscow"');
          if (Stat == 0)
              return;
          end
%           [status] = RS.sendCommand(sprintf('SOUR:BB:GPS:POWER:REF %.1f', RefPow));
%           if (status<0)
%               return;
%           end
          
          [Stat] = RS.sendCommand(sprintf('BB:GPS:SAT:COUN %i', SatNumber));
          if (Stat == 0)
              return;
          end
          [Stat] = RS.sendCommand('SOUR:BB:GPS:GOC');
          if (Stat == 0)
              return;
          end
          [Stat, result] = RS.sendQuery('*OPC?');
          if (Stat == 0 || result(1)~='1')
              return;
          end
          [Error] = RS.queryError;
          if (Error == 1)
              return;
          end
          
          [Stat] = RS.sendCommand('SOUR:BB:GPS:STAT ON');
          if (Stat == 0)
              return;
          end
          
          progress = '0';
          [Stat, progress] = RS.sendQuery('SOUR:BB:PROG:MCOD?');
          while (str2num(progress) ~= 100)
              [Stat, progress] = RS.sendQuery('SOUR:BB:PROG:MCOD?');
          end
          
          [Stat, result] = RS.sendQuery('*OPC?');
          if (Stat == 0 || result(1)~='1')
              return;
          end
          
          [Stat] = RS.sendCommand('BB:GPS:TRIGger:EXECute');
          if (Stat == 0)
              return;
          end

          [Error] = RS.queryError;
          if (Error == 1)
              return;
          end
          Status = 1;
       end

    end
    
end

