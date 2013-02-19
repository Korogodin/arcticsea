classdef CReceiver < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        obj
        SolutionStatus
    end
    
    methods
        %�����������
        function RCV = CReceiver
            
        end
        
        %��������� �����
        function COMconfig(RCV, COM, Baud)
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
        
        %���������� � ������
        function [Stat] = COMconnect(RCV)
            Stat = 0;
            fopen(RCV.obj);
            if strcpm(get(RCV.obj,'Status'),'open')
                disp('***COM: connection OK');
                Stat = 1;
            else
                disp('***COM: connection error');
                return;
            end
        end
        
        %������ ������ � �����
        function [Answer] = RecieveString(RCV)
            Answer = fscanf(RCV.obj);
        end
        
        %�������� �����
        function [Stat] = COMclose(RCV)
            Stat = 0;
            fclose(RCV.obj);
            if strcpm(get(RCV.obj,'Status'),'close')
                disp('***COM: close OK');
                Stat = 1;
            else
                disp('***COM: close error');
                return;
            end
        end
                
        %��������� ������� ������� ����������
        function [SolutionStatus] = GetSolutionStatus(RCV)
            SolutionStatus = 0;
            while(1)
                answer = RecieveString(RCV);
                if strcmp(answer(1:6),'$GNGSA')||strcmp(answer(1:6),'$GPGSA')
                    sol = answer(10);
                    switch sol
                        case '1'
                            RCV.SolutionStatus = 1;
                            SolutionStatus = RCV.SolutionStatus; %!!! ��� � �� ������
                            disp('No solution')
                            return;
                        case '2'
                            RCV.SolutionStatus = 2;
                            SolutionStatus = RCV.SolutionStatus; %!!! ��� � �� ������
                            disp('2D')
                            return;
                        case '3'
                            RCV.SolutionStatus = 3;
                            SolutionStatus = RCV.SolutionStatus; %!!! ��� � �� ������
                            disp('3D')
                            return;
                    end
                end
                
            end
        end
        
        
    end
    
    
end

