classdef CReceiver < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        obj
        FixType
    end
    
    methods
        %конструктор
        function RCV = CReceiver
            
        end
        
        %настройка порта
        function SerialConfig(RCV, COM, Baud)
            if ( nargin ~= 3)
                disp('***Wrong number of input arguments')
                return;
            end
            if ( isempty(COM) || (ischar(COM)~= 1) )
                disp('***Enter COM<x> as a string');
                return;
            end
            if (isempty(Baud))
                disp('***Enter Baud rate');
                return;
            end
            RCV.obj = serial(COM);
            set(RCV.obj,'BaudRate',Baud);
            
        end
        
        %соединение с портом
        function [Stat] = SerialConnect(RCV)
            Stat = 0;
            fopen(RCV.obj);
            if strcmp(get(RCV.obj,'Status'),'open')
                disp('***Serial: connection OK');
                Stat = 1;
            else
                disp('***Serial: connection error');
                return;
            end
        end
        
        %„тение данных с порта
        function [Answer] = RecieveString(RCV)
            Answer = fscanf(RCV.obj);
        end
        
        %закрытие порта
        function [Stat] = SerialClose(RCV)
            Stat = 0;
            fclose(RCV.obj);
            if strcpm(get(RCV.obj,'Status'),'close')
                disp('***Serial: close OK');
                Stat = 1;
            else
                disp('***Serial: close error');
                return;
            end
        end
        
        %Receiver reset 
        function Reset(RCV)
            fprintf(RCV.obj,'$GPSGG,CSTART*6B\n\r');
        end
                
        %ѕолучение статуса решени€ однократно
        function GetSolutionStatus(RCV)
            while(1)
                answer = RecieveString(RCV);
                if strcmp(answer(1:6),'$GNGSA')||strcmp(answer(1:6),'$GPGSA')
                    sol = answer(10);
                    switch sol
                        case '1'
                            RCV.FixType = 1;
                            disp('No solution')
                            return;
                        case '2'
                            RCV.FixType = 2;
                            disp('2D Fix')
                            return;
                        case '3'
                            RCV.FixType = 3;
                            disp('3D Fix')
                            return;
                    end
                end
                
            end
        end
        
        
    end
    
    
end

