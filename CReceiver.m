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
%* Class to work with navigation receiver via serial port
%* Features:
%* 1) Reset receiver ( only for GEOS - 3 )
%* 2) Get solution status ( only for GEOS - 3 )
%* 3) Read data from receiver


classdef CReceiver < handle
    %CReceiver Class to work with navigation receiver via serial port
    
    properties
        obj % Pointer of serial connection
        FixType % Type of solution (1 - No solution, 2 - 2D, 3 - 3D)
    end
    
    methods
        
        
        %*Consturctor of this class
        %*
        %*This is constructor of Receiver control class
        %*Example: Rec1 = CReceiver;
        %*
        %*@return RCV Object of this class
        function RCV = CReceiver
            
        end
        
        %*Set parameters of serial port
        %*
        %*@param COM String port name
        %*@param Baud Baud
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
        
        %*Connect to receiver by serial port
        %*
        %*@return Status Is 0 - fail; 1 - ok.
        function [Status] = SerialConnect(RCV)
            Status = 0;
            fopen(RCV.obj);
            if strcmp(get(RCV.obj,'Status'),'open')
                disp('***Serial: connection OK');
                Status = 1;
            else
                disp('***Serial: connection error');
                return;
            end
        end
        
        %*Read data from receiver
        %*
        %*@return Answer Data from receiver
        function [Answer] = RecieveString(RCV)
            Answer = fscanf(RCV.obj);
        end
        
        %*Close connection to receiver
        %*
        %*@return Status Is 0 - fail; 1 - ok.
        function [Status] = SerialClose(RCV)
            Status = 0;
            fclose(RCV.obj);
            if strcpm(get(RCV.obj,'Status'),'close')
                disp('***Serial: close OK');
                Status = 1;
            else
                disp('***Serial: close error');
                return;
            end
        end
        
        %*Reset receiver ( NMEA string is true for GEOS-3 )
        %*
        function Reset(RCV)
            fprintf(RCV.obj,'$GPSGG,CSTART*6B\n\r');
        end
        
        %*Get solution status and store it in FixType 
        %*
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

