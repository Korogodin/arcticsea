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
%* Class for Rohde&Schwarz SMBV100A vector signal generator
%* Features:
%* 1) Set up output power  
%* 2) Set up carrier frequency
%* 3) Simulate GPS signals of the given number of satellites


classdef CSMBV < handle
    %CSMBV Class for Rohde&Schwarz SMBV100A vector signal generator
    
    properties
        Freq  % Frequency of the carrier Hz
        Level % Output power dBm
        Instr % Pointer of TCP/IP connection
    end
    
    methods
        %*Consturctor of this class
        %*
        %*This is constructor of SMBV control class
        %*Example: SMBV1 = CSMBV;
        %*
        %*@return RS Object of this class
        function RS = CSMBV
            
        end
        %*Connect to unit by local network
        %*
        %*@param IP String IP-address of unit
        %*@param port Port for TCP/IP connection, usually 5025
        %*@return Status Is 0 - fail; 1 - ok.
        function Status = SetConnection(RS, IP, port)
            Status = 0;
            RS.Instr = tcpip(IP, port);
             
            %Uncomment to change tcpip object's R/W buffer size. 
            %Default = 512 bytes
            %set(RS.Instr, InputBufferSize, 2000);
            %set(RS.Instr, OutputBufferSize, 2000);
                                                   
            fopen(RS.Instr);
            if  strcmp(get(RS.Instr,'Status'),'open')
                fprintf('SMBV:Connection OK');
                Status = 1;
            else
                fprintf('SMBV:Connection Problem');
            end
        end
        
        %*Close connection and return to manual control
        %*
        %*@return Status Returns a status of 0 when the close operation is successful. Otherwise, it returns -1
        function Status = CloseConnection(RS)
            fprintf(RS.Instr,'&GTL');
            Status = fclose(RS.Instr);
        end
        
        %*Send SCPI command to SMBV
        %*
        %*@param strCommand String of SCPI command
        %*@return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
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
        
        %*Send request for answer
        %*
        %*@param strCommand String of SCPI command
        %*@return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
        %*@return Result Returns a answer of SMBV
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

        %*Get information about instrument
        %*
        %*@return IDN String information about instrument
        %*@return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
        function [Status, IDN] = GetIDN(RS)
            Status = 0;
            IDN = '';
            [Stat, IDN] = RS.SendQuery('*IDN?');
            if (Stat == 0)
                return;
            end
            Status = 1;
        end
        
        %*Preset instrument and clear errors log
        %*
        %*@return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
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
       
        %*Check errors in SMBV
        %*
        %*@return Err Instrument error
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
                    break;
                end
                if (Result(1)~='0')
                    disp (['*** Instrument Error: ' Result]);
                    Err = 1;
                end
                Counter = Counter + 1;
            end
        end
       
        %*Set the output power level
        %*
        %*@param Level Output power level, dBm
        %*@return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
        function [Status] = SetLevel(RS, Level)
           Status = 0;
           RS.Level = Level;
           [Stat] = RS.SendCommand(sprintf('SOUR:POW %.1f', Level));
           if (Stat == 0)
               return;
           end
           Status = 1;
       end
       
        %*Set the frequency of the carrier
        %*
        %*@param Freq Frequency of the carrier. Freq can be String 10GHz or float(Hz) 10.12345E9
        %*@return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
       function [Status] = SetFreq(RS, Freq)
           Status = 0;
           if (ischar(Freq))
               [Stat] = RS.SendCommand(['SOUR:FREQ ' Freq]);
               RS.Freq = str2num(Freq);
               if ( Stat == 0)
                   return;
               end
           else
               [Stat] = RS.SendCommand(sprintf('SOUR:FREQ %.5f', Freq));
               RS.Freq = Freq;
               if (Stat == 0)
                   return;
               end
           end
           RS.CenterFreq = Freq;
           Status = 1;
       end
       
       %*Set the RF output ON/OFF
       %*
       %*@param State String ON/OFF
       %*@return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
       function [Status] = SetRFOutput(RS, State)
           Status = 0;
           if (ischar(State))
               [Stat] = RS.SendCommand(['OUTP ' State]);
               if (Stat == 0)
                   return;
               end
           else
               disp('Output state is string ON/OFF');
               return;
           end
           Status = 1;
       end
      
        %*Simulate signals of several GPS satellites, satellite signal power is the same, 
        %*the frequency range is L1, location - Moscow
        %*
        %*@param SatNumber Integer number of satellites
        %*@return Status Returns a status of 1 when the operation is successful. Otherwise, it returns 0
       function [Status] = SetGPS(RS, SatNumber)
           Status = 0;
%           RS.RefPoW = RefPow;
          [Stat] = RS.SendCommand('SOUR:BB:GPS:PRES');
          if (Stat == 0)
              return;
          end
          [Stat, result] = RS.SendQuery('*OPC?');
          if (Stat == 0 || result(1)~='1')
              return;
          end
          [Stat] = RS.SendCommand('SOUR:BB:GPS:STAT OFF');
          if (Stat == 0)
              return;
          end
          [Stat] = RS.SendCommand('SOUR:BB:GPS:SMODE USER');
          if (Stat == 0)
              return;
          end
          [Stat] = RS.SendCommand('SOUR:BB:GPS:LOC:SEL "Moscow"');
          if (Stat == 0)
              return;
          end
%           [status] = RS.sendCommand(sprintf('SOUR:BB:GPS:POWER:REF %.1f', RefPow));
%           if (status<0)
%               return;
%           end
          
          [Stat] = RS.SendCommand(sprintf('BB:GPS:SAT:COUN %i', SatNumber));
          if (Stat == 0)
              return;
          end
          [Stat] = RS.SendCommand('SOUR:BB:GPS:GOC');
          if (Stat == 0)
              return;
          end
          [Stat, result] = RS.SendQuery('*OPC?');
          if (Stat == 0 || result(1)~='1')
              return;
          end
          [Error] = RS.QueryError;
          if (Error == 1)
              return;
          end
          
          [Stat] = RS.SendCommand('SOUR:BB:GPS:STAT ON');
          if (Stat == 0)
              return;
          end
          
          progress = '0';
          [Stat, progress] = RS.SendQuery('SOUR:BB:PROG:MCOD?');
          if (Stat == 0)
              return;
          end
          while (str2num(progress) ~= 100)
              [Stat, progress] = RS.SendQuery('SOUR:BB:PROG:MCOD?');
              if (Stat == 0)
                  return;
              end
          end
          
          [Stat, result] = RS.SendQuery('*OPC?');
          if (Stat == 0 || result(1)~='1')
              return;
          end
          
          [Stat] = RS.SendCommand('BB:GPS:TRIGger:EXECute');
          if (Stat == 0)
              return;
          end

          [Error] = RS.QueryError;
          if (Error == 1)
              return;
          end
          Status = 1;
       end

    end
    
end

