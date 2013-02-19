clear
clc
close all

SMBV = CSMBV();

Rec = CReceiver();
Rec.setPort();
Rec.setBaundRate();
Rec.Connect();

LevelStep = 1; PauseOnLevel = 120;

k = 0; RecOKOnLastStep = 0;
while ~(STOP)
	Rec.ReceiveString()

	if RecOKOnLastStep && Rec.OK == 0
		TimeofDead = tic();
	end

	if (Rec.OK == 0)&&(Rec.HaveFix == 1)
		if toc(TimeofDead) > 5
			RecIsDead5sec = 1;
		else
			RecIsDead5sec = 0;
		end
	end

	if ~RecIsDead5sec	
		if toc(tin_thislevel) > PauseOnLevel
			LastOKLevel = SMBV.getLevel();
			SMBV.setLevel(LastOKLevel - LevelStep);
			tin_thislevel  = tic();
		end
	else
		k = k + 1;
		Level(k) = LastOkLevel;
	end

	if (Rec.OK)
		RecOKOnLastStep = 1;
	end
end