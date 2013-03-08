%> @file CRSC.m
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
%> Class for Rohde&Schwarz RSC attenuator\n
%> Features:\n
%> 1) Set up attenuation

%> @brief Class for Rohde&Schwarz RSC attenuator
classdef CRSC < handle
        
    properties
        %> Pointer of TCP/IP connection
        Instr 
        %> Attenuation dB
        Attenuation 
    end
    
    methods
        
        
        %> @brief Consturctor of this class
        %>
        %> This is constructor of RSC control class\n
        %> Example: RSC3 = CRSC;
        %>
        %> @return RS Object of this class
        function RS = CRSC
            
        end
        
        %> @brief Connect to unit by local network
        %>
        %> Example: RSC3.SetConnection('192.168.1.58', 5025);
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
                fprintf('RSC:Connection OK');
                Status = 1;
            else
                fprintf('RSC:Connection Problem');
            end
        end
        
        %> @brief Close connection and return to manual control
        %>
        %> Example: RSC3.CloseConnection;
        %> @return Status Returns a status of 0 when the close operation is successful. Otherwise, it returns -1
        function Status = CloseConnection(RS)
            fprintf(RS.Instr,'&GTL');
            Status = fclose(RS.Instr);
        end
        
        %> @brief Send SCPI command to RSC
        %>
        %> Example: RSC3.SendCommand('*RST');
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
        %> Example: RSC3.SendQuery('*IDN?');
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
        %> Example: RSC3.GetIDN;
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
        %> Example: RSC3.Preset;
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
        
        %> @brief Check errors in RSC
        %>
        %> Example: RSC3.QueryError;
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
        
        %> @brief Set the attenuation
        %>
        %> Example: RSC3.SetAttenuation(30);
        %> @param ATT attenuation dB
        %> @return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
        function [Status] = SetAttenuation(RS, ATT)
            Status = 0;
            [Stat] = RS.SendCommand(sprintf('ATT1:ATT %.2f', ATT));
            if ( Stat == 0)
                return;
            end
            RS.Attenuation = ATT;
            Status = 1;
        end
    end
    
end

