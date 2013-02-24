classdef CFSV < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Instr
        Span
        CenterFreq
    end
    
    methods
        %�����������
        function RS = CFSV
            
        end
        %��������� ����������
        function [Status] = setConnection(RS, IP, port)
            Status = 0;
            RS.Instr = tcpip(IP, port);
            %set(RS.Instr, InputBufferSize, 2000);
            %set(RS.Instr, OutputBufferSize, 2000);
            fopen(RS.Instr);
            if  strcmp(get(RS.Instr,'Status'),'open')
                disp('Connection OK');
                Status = 1;
            else
                disp('Connection Problem');
            end
        end
        
        %�������� ���������� � ��������� � ������� ����������
        function closeConnection(RS)
            fprintf(RS.Instr,'&GTL');
            fclose(RS.Instr);
        end
        
        %�������� �������
        function [Status] = sendCommand(RS, strCommand)
            Status = 0;
            % �������� ���������� ������� ����������
            if( nargin ~= 2 )
                disp( '*** Wrong number of input arguments' )
                return;
            end
            
            % �������� 1�� ���������
            if( isobject(RS) ~= 1 )
                disp( '*** The first parameter is not an object.' );
                return;
            end
            
            % �������� 2�� ���������
            if( isempty(strCommand) || (ischar(strCommand)~= 1) )
                disp ('*** Command string is empty or not a string.');
                return;
            end
            
            %���������� �������� �������
            fprintf (RS.Instr, strCommand);
            Error = queryError(RS);
            if (Error==1)
                return;
            end
            Status = 1;
        end
        
        %�������� ������� � ��������� ������
        function [Status, Result] = sendQuery(RS, strCommand)
            Status = 0;
            Result = '';
            
            % �������� ���������� ������� ����������
            if( nargin ~= 2 )
                disp( '*** Wrong number of input arguments' )
                return;
            end
            
            % �������� 1�� ���������
            if( isobject(RS) ~= 1 )
                disp( '*** The first parameter is not an object.' );
                return;
            end
            
            % �������� 2�� ���������
            if( isempty(strCommand) || (ischar(strCommand)~= 1) )
                disp ('*** Command string is empty or not a string.');
                return;
            end
            
            % ��������, ���� �� � ������� ������
            if( isempty( strfind(strCommand, '?' ) ) )
                disp( '*** Queries must end with a question mark.' );
                return;
            end
            
            % �������� ������� � ��������� ����������
            fprintf (RS.Instr, strCommand);
            Result = fscanf(RS.Instr, '%c');
            Status = 1;
            
        end
        
        %����� �� ������� ������
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
        
        %��������� ����������� �������
        function [Status] = SetCenterFreq(RS, Freq)
            Status = 0;
            if (ischar(Freq))
                [Stat] = RS.sendCommand(['FREQ:CENT ' Freq]);
                if ( Stat == 0)
                    return;
                end
            else
                [Stat] = RS.sendCommand(sprintf('FREQ:CENT %.5f',Freq));
                if ( Stat == 0)
                    return;
                end
            end
           Status = 1;
        end
        
        %��������� ������
        function [Status] = SetSpan(RS, Span)
            Status = 0;
            if (ischar(Span))
                [Stat] = RS.sendCommand(['FREQ:CENT ' Span]);
                if ( Stat == 0)
                    return;
                end
            else
                [Stat] = RS.sendCommand(sprintf('FREQ:CENT %.5f',Span));
                if ( Stat == 0)
                    return;
                end
            end
            Status = 1;
        end
        
        %��������� �������� � ������
        function [measure] = PowerMeasure(RS, TXCHCount, CHANSpan)
            RS.sendCommand(sprintf('SENS:POW:ACH:TXCH:COUNT %i', TXCHCount));
            if (ischar(CHANSpan))
                RS.sendCommand(['SENS:POW:ACH:BAND:CHAN1 ', CHANSpan]);
            else
                RS.sendCommand(sprintf('SENS:POW:ACH:BAND:CHAN1 %.5f', CHANSpan));
            end
            [status, result] = RS.sendQuery('*OPC?');
            if (status == 0 || result(1)~='1'),
                return;
            end
            [Stat] = RS.sendCommand('INIT:CONT OFF');
            if ( Stat == 0)
                return;
            end
            [Stat] = RS.sendCommand('INIT;*WAI');
            if ( Stat == 0)
                return;
            end
            [m, measure] = FSV.sendQuery('CALC:MARK:FUNC:POW:RES? CPOW');
            if (m == 0 || result(1)~='1'),
                return;
            end
            disp(['Measure result:' measure]);
            
        end
    end
end


