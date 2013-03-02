%*
%* @file
%* @author  Vladimir Dneprov <vvdneprov@gmail.com>  
%* Moscow Power Engineering Institute
%* 
%* @section LICENSE
%*
%* This program is free software; you can redistribute it and/or
%* modify it under the terms of the GNU General Public License as
%* published by the Free Software Foundation; either version 2 of
%* the License, or (at your option) any later version.
%*
%* This program is distributed in the hope that it will be useful, but
%* WITHOUT ANY WARRANTY; without even the implied warranty of
%* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
%* General Public License for more details at
%* http://www.gnu.org/copyleft/gpl.html
%*
%* @section DESCRIPTION
%*
%* Class for Rohde&Schwarz FSV signal & spectrum analyzers
%* Features:
%* 1) Bandwidth power measurement

classdef CFSV < handle
    %CFSV Class for Rohde&Schwarz FSV signal & spectrum analyzers
    
    properties
        Instr % Pointer of TCP/IP connection
        Span % Band for power measurement
        CenterFreq % Central frequency for power measurement
    end
    
    methods


        %*Consturctor of this class
        %*
        %*This is constructor of FSV control class
        %*Example: FSV3 = CFSV();
        %*
        %*@return RS Object of this class
        function RS = CFSV()
            
        end
        
        %*Connect to measurement unit by local network
        %*
        %*@param IP IP-address of measurement unit
        %*@param port Port for TCP/IP connection, usually 5025
        %*@return Status Is 0 - fail; 1 - ok.
        function Status = setConnection(RS, IP, port)
            Status = 0;
            RS.Instr = tcpip(IP, port);
            %set(RS.Instr, InputBufferSize, 2000);
            %set(RS.Instr, OutputBufferSize, 2000);
            fopen(RS.Instr);
            if  strcmp(get(RS.Instr,'Status'),'open')
                fprintf('FSV:Connection OK');
                Status = 1;
            else
                fprintf('FSV:Connection Problem');
            end
        end
        
        %*Close connection and return to manual control
        %*
        %*@return Status Returns a status of 0 when the close operation is successful. Otherwise, it returns -1
        function Status = closeConnection(RS)
            fprintf(RS.Instr,'&GTL');
            Status = fclose(RS.Instr);
        end
        
        %*Send SCPI command to FSV
        %*
        %*@param strCommand String of SCPI command
        %*@return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
        function [Status] = sendCommand(RS, strCommand)
            Status = 0;
            % Check number of input args
            if( nargin ~= 2 )
                disp( '*** Wrong number of input arguments' )
                return;
            end
            
            % Check first parameter
            if( isobject(RS) ~= 1 )
                disp( '*** The first parameter is not an object.' );
                return;
            end
            
            % Check second parameter
            if( isempty(strCommand) || (ischar(strCommand)~= 1) )
                disp ('*** Command string is empty or not a string.');
                return;
            end
            
            % Command sending
            fprintf (RS.Instr, strCommand);
            Error = queryError(RS);
            if (Error==1)
                return;
            end
            Status = 1;
        end
        
        %*Send request for answer
        %*
        %*@param strCommand String of SCPI command
        %*@return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
        %*@return Result Returns a answer of FSV
        function [Status, Result] = sendQuery(RS, strCommand)
            Status = 0;
            Result = '';
            
            % Check number of input args
            if( nargin ~= 2 )
                disp( '*** Wrong number of input arguments' )
                return;
            end
            
            % Check first parameter
            if( isobject(RS) ~= 1 )
                disp( '*** The first parameter is not an object.' );
                return;
            end
            
            % Check second parameter
            if( isempty(strCommand) || (ischar(strCommand)~= 1) )
                disp ('*** Command string is empty or not a string.');
                return;
            end
            
            % Check: is strCommand the question?
            if( isempty( strfind(strCommand, '?' ) ) )
                disp( '*** Queries must end with a question mark.' );
                return;
            end
            
            % Send request and receive answer
            fprintf (RS.Instr, strCommand);
            Result = fscanf(RS.Instr, '%c');
            Status = 1;
            
        end
        
        %*Check errors in FSV
        %*
        %*@return Err Instrument error
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
        
        %*Set central frequency in power measurement mode
        %*
        %*@param Freq Central frequency, Hz?
        %*@return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
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
        
        %*Set bandwidth in power measurement mode
        %*
        %*@param Span Bandwidth, Hz?
        %*@return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
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
        
        %*Get power in bandwith
        %*
        %*@param TXCHCount ???
        %*@param CHANSpan ???
        %*@return measure Power in bandwith, dBm?
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


