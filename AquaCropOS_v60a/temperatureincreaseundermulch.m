function [ deltaT, Ts, Tsf] = temperatureincreaseundermulch(Crop)
% temperatureincreaseundermulch (?T)
%   above the soil underneath a film cover 

Weather = AOS_ExtractWeatherData();
% Get weather inputs for current time step %%
Tmin = Weather.MinTemp;
Tmax = Weather.MaxTemp;
Tmean = (Tmax+Tmin)/2;

Ts=0.89+1.017*Tmean;
%Ts is the soil temperature at 5 cm depth without mulching

Tsf=7.5725+0.8303*Tmean;
%Tsf is the soil temperature at 5 cm depth under film mulch mulching
%gdd=GDDcum(Crop.Canopy10Pct);
GDD = Tmean-Crop.Tbase;
if GDD> 0 && GDD<= Crop.Canopy10Pct
%C is a coefficient from 0 to 1, C=0.51 from emergence to recovering,
%c=0.22 from recovering to flowering and equal zero after flower because the film cover will be heavily shaded.
    c=0.51;
elseif GDD>Crop.Canopy10Pct && GDD <=Crop.Flowering
    c=0.22;
elseif GDD>Crop.Flowering
    c=0;
end

deltaT=c *(Tsf-Ts)*(Tmean-Crop.Tbase)/(Ts-Crop.Tbase);

%Crop.deltaT= deltaT;
%Crop.Tsf=Tsf;
%Crop.Ts=Ts;
end

