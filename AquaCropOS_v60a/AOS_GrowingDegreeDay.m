function [GDD,NewCond] = AOS_GrowingDegreeDay(Crop,InitCond,Tmax,Tmin,FieldMngt)
% Function to calculate number of growing degree days on current day

%% Store initial conditions for updating %% 
NewCond = InitCond;


%% Calculate GDDs %%
if Crop.GDDmethod == 1
    % Method 1
    Tmean = (Tmax+Tmin)/2;
    Tmean(Tmean>Crop.Tupp) = Crop.Tupp;
    Tmean(Tmean<Crop.Tbase) = Crop.Tbase;
    GDD = Tmean-Crop.Tbase;
elseif Crop.GDDmethod == 2
    % Method 2
    Tmax(Tmax>Crop.Tupp) = Crop.Tupp;
    Tmax(Tmax<Crop.Tbase) = Crop.Tbase;
    Tmin(Tmin>Crop.Tupp) = Crop.Tupp;
    Tmin(Tmin<Crop.Tbase) = Crop.Tbase;
    Tmean = (Tmax+Tmin)/2;
    GDD = Tmean-Crop.Tbase;
elseif Crop.GDDmethod == 3
    % Method 3
    Tmax(Tmax>Crop.Tupp) = Crop.Tupp;
    Tmax(Tmax<Crop.Tbase) = Crop.Tbase;
    Tmin(Tmin>Crop.Tupp) = Crop.Tupp;
    Tmean = (Tmax+Tmin)/2;
    Tmean(Tmean<Crop.Tbase) = Crop.Tbase;
    GDD = Tmean-Crop.Tbase;
end

%% conditions in case Mulches present
if FieldMngt.Mulches == 'Y'
    %mulches present
	[deltaT, Ts, Tsf]=temperatureincreaseundermulch(Crop,NewCond);
%    printf('deltaT %s',deltaT);
%    printf('Ts %s',Ts);
%    printf('Tsf %s',Tsf);
    GDD = GDD + deltaT;    
end


%% Update cumulative GDD counter %%
NewCond.GDDcum = InitCond.GDDcum+GDD;

end

