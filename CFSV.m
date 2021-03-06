%> @file CFSV.m
%> @author  Vladimir Dneprov <vvdneprov@gmail.com>  
%> Moscow Power Engineering Institute
%> 
%> @section LICENSE
%>
%> This program is free software; you can redistribute it and/or
%> modify it under the terms of the GNU General Public License as
%> published by the Free Software Foundation; either version 2 of
%> the License, or (at your option) any later version.
%>
%> This program is distributed in the hope that it will be useful, but
%> WITHOUT ANY WARRANTY; without even the implied warranty of
%> MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
%> General Public License for more details at
%> http://www.gnu.org/copyleft/gpl.html
%>
%> @section DESCRIPTION
%>
%> Class for Rohde&Schwarz FSV signal & spectrum analyzers\n
%> Features:\n
%> 1) Power measurement in the given bandwidth\n
%> 2) Setup center frequency of the spectrum analysis\n
%> 3) Setup bandwidth of the spectrum analysis\n 

%> @brief Class for Rohde&Schwarz FSV signal & spectrum analyzers
classdef CFSV < handle
    
    
    properties
        %> Pointer of TCP/IP connection
        Instr
        %> Band for spectrum analysis
        Span 
        %> Central frequency for spectrum analysis
        CenterFreq 
    end
    
    methods


        %> @brief Consturctor of this class
        %>
        %> This is constructor of FSV control class\n
        %> Example: FSV3 = CFSV;
        %>
        %> @return RS Object of this class
        function RS = CFSV
            
        end
        
        %> @brief Connect to unit by local network
        %>
        %> Example: FSV3.SetConnection('192.168.1.100', 5025);
        %> @param IP String IP-address of measurement unit
        %> @param port Port for TCP/IP connection, usually 5025
        %> @return Status Is 0 - fail; 1 - ok.
        function Status = SetConnection(RS, IP, port)
            Status = 0;
            RS.Instr = tcpip(IP, port);
            
            %Uncomment to change tcpip object's R/W buffer size.
            %Default = 512 bytes
            %set(RS.Instr, InputBufferSize, 2000);
            %set(RS.Instr, OutputBufferSize, 2000);
            
            fopen(RS.Instr);
            if  strcmp(get(RS.Instr,'Status'),'open')
                fprintf('FSV:Connection OK\n');
                Status = 1;
            else
                fprintf('FSV:Connection Problem');
            end
        end
        
        %> @brief Close connection and return to manual control
        %>
        %> Example: FSV3.CloseConnection;
        %> @return Status Returns a status of 0 when the close operation is successful. Otherwise, it returns -1
        function Status = CloseConnection(RS)
            fprintf(RS.Instr,'&GTL');
            Status = fclose(RS.Instr);
        end
        
        %> @brief Send SCPI command to FSV
        %>
        %> Example: FSV3.SendCommand('*RST');
        %> @param strCommand String of SCPI command
        %> @return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
        function [Status] = SendCommand(RS, strCommand)
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
            Error = QueryError(RS);
            if (Error==1)
                return;
            end
            Status = 1;
        end
        
        %> @brief Send request for answer
        %>
        %> Example: FSV3.SendQuery('*IDN?');
        %> @param strCommand String of SCPI command
        %> @return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
        %> @return Result Returns an answer of FSV
        function [Status, Result] = SendQuery(RS, strCommand)
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
        
        %> @brief Get information about instrument
        %> 
        %> Example: FSV3.GetIDN;
        %> @return IDN String information about instrument
        %> @return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
        function [Status, IDN] = GetIDN(RS)
            Status = 0;
            IDN = '';
            [Stat, IDN] = RS.SendQuery('*IDN?');
            if (Stat == 0)
                return;
            end
            Status = 1;
        end
        
        %> @brief Preset instrument and clear errors log
        %>
        %> Example: FSV3.Preset;
        %> @return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
        function [Status] = Preset(RS)
            Status = 0;
            [Stat] = RS.SendCommand('*RST; *CLS');
            if (Stat == 0)
                return;
            end
            [status, result] = RS.SendQuery('*OPC?');
            if (status == 0 || result(1)~='1')
                return;
            end
            Status = 1;
        end
        
        %> @brief Check errors in FSV
        %>
        %> Example: FSV3.QueryError;
        %> @return Err Err = 1 instrument error occured, 0 no error 
        function [Err] = QueryError(RS)
            Result = '1';
            Counter = 0;
            Err = 0;
            % query for errors in a loop until "0, No error" is returned
            % and limit the number of iterations to 100
            while (Result(1) ~= '0' && Counter < 100)
                [status, Result] = RS.SendQuery('SYST:ERR?');
                if (status == 0)
                    disp( '*** Error occurred' );
                    Err = 1;
                end
                if (Result(1)~='0')
                    disp (['*** Instrument Error: ' Result]);
                    Err = 1;
                end
                Counter = Counter + 1;
            end
        end
        
        %> @brief Set the center frequency of the spectrum analysis
        %>
        %> Example:\n FSV3.SetCenterFreq('1GHz');\n
        %> FSV3.SetCenterFreq(1E9);
        %> @param Freq Central frequency string 1GHz or float 1.11E9 (Hz)
        %> @return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
        function [Status] = SetCenterFreq(RS, Freq)
            Status = 0;
            if (ischar(Freq))
                [Stat] = RS.SendCommand(['FREQ:CENT ' Freq]);
                if ( Stat == 0)
                    return;
                end
            else
                [Stat] = RS.SendCommand(sprintf('FREQ:CENT %.5f',Freq));
                if ( Stat == 0)
                    return;
                end
            end
            RS.CenterFreq = Freq;
            Status = 1;
        end
        
        %> @brief Set bandwidth of the spectrum analysis
        %>
        %> Example:\n FSV3.SetSpan('1MHz');\n
        %> FSV3.SetSpan(1E6);
        %> @param Span String 1MHz or float 1.1E6
        %> @return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
        function [Status] = SetSpan(RS, Span)
            Status = 0;
            if (ischar(Span))
                [Stat] = RS.SendCommand(['FREQ:SPAN ' Span]);
                if ( Stat == 0)
                    return;
                end
            else
                [Stat] = RS.SendCommand(sprintf('FREQ:SPAN %.5f',Span));
                if ( Stat == 0)
                    return;
                end
            end
            RS.Span = Span;
            Status = 1;
        end
        
        %> @brief Measure power in given bandwith
        %>
        %> Example:\n FSV3.PowerMeasure('10MHz');\n
        %> FSV3.PowerMeasure(1E7);
        %> @param Bandwidth String 1MHz or float 1.123E6 (Hz)
        %> @return measure Power in bandwith, dBm
        %> @return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
        function [Status, measure] = PowerMeasure(RS, Bandwidth)
            Status = 0;
            if (ischar(Bandwidth))
                [Stat] = RS.SendCommand(['SENS:POW:ACH:BAND:CHAN1 ', Bandwidth]);
                if ( Stat == 0)
                    return;
                end
            else
                [Stat] = RS.SendCommand(sprintf('SENS:POW:ACH:BAND:CHAN1 %.5f', Bandwidth));
                if ( Stat == 0)
                    return;
                end
            end
            [status, result] = RS.SendQuery('*OPC?');
            if (status == 0 || result(1)~='1'),
                return;
            end
            [Stat] = RS.SendCommand('INIT:CONT OFF');
            if ( Stat == 0)
                return;
            end
            [Stat] = RS.SendCommand('INIT;*WAI');
            if ( Stat == 0)
                return;
            end
            [m, measure] = RS.SendQuery('CALC:MARK:FUNC:POW:RES? CPOW');
            if (m == 0 || result(1)~='1'),
                return;
            end
            Status = 1;
            disp(['Measure result:' measure]);
        end
    end
end


