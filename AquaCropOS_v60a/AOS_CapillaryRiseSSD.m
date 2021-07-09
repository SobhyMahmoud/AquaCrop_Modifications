function [NewCond,CrTot] = AOS_CapillaryRiseSSD(Soil,IrrMngt,Irr,InitCond,FluxOut)
% Function to calculate capillary rise from a subsurface drip irrigation(SSD)

%% Store initial conditions for updating %%
NewCond = InitCond;

%% Get emitter depth %%
zEmitter = IrrMngt.zdripper;

if InitCond.DAP == 2
    InitCond.DAP
end    

CrTot = 0;
% Note: irrigation amount adjusted for specified application efficiency

    NetIrr =(Irr*(IrrMngt.AppEff/100));
    
    
%% Calculate capillary rise %%
if IrrMngt.zdripper == 0  % surface drip irrigation
    % Capillary rise is zero
    CrTot = 0;
elseif IrrMngt.zdripper > 0  % SSD present
    % Get maximum capillary rise for bottom compartment
    zBot = sum(Soil.Comp.dz);
    zBotMid = zBot-(Soil.Comp.dz(Soil.nComp)/2);
    layeri = Soil.Comp.Layer(Soil.nComp);
    if (Soil.Layer.Ksat(layeri) > 0) && (zEmitter > 0) && ((zEmitter-zBotMid) < 4)
        if zBotMid >= zEmitter
            MaxCR = NetIrr;
        else
            MaxCR = exp((log(zEmitter-zBotMid)-Soil.Layer.bCR(layeri))/Soil.Layer.aCR(layeri));
            if MaxCR > NetIrr
                MaxCR = NetIrr;
            end
        end
    else
        MaxCR = 0;
    end
    % Find top of next soil layer that is not within modelled soil profile
    zTopLayer = 0;
    for ii = 1:Soil.Comp.Layer(Soil.nComp)
        % Calculate layer thickness
        LayThk = Soil.Layer.dz(ii);
        zTopLayer = zTopLayer+LayThk;
    end
    % Check for restrictions on upward flow caused by properties of
    % compartments that are not modelled in the soil water balance
    layeri = Soil.Comp.Layer(Soil.nComp);
    while (zTopLayer < zEmitter) && (layeri < Soil.nLayer)
        layeri = layeri+1;
        if (Soil.Layer.Ksat(layeri) > 0) && (zEmitter > 0) && ((zEmitter-zTopLayer) < 4)
            if zTopLayer >= zEmitter
                LimCR = NetIrr;
            else
                LimCR = exp((log(zEmitter-zTopLayer)-Soil.Layer.bCR(layeri))/...
                    Soil.Layer.aCR(layeri));
                if LimCR > NetIrr
                    LimCR = NetIrr;
                end
            end
        else
            LimCR = 0;
        end
        if MaxCR > LimCR
            MaxCR = LimCR;
        end
        zTopLayer = zTopLayer+Soil.Layer.dz(layeri);
    end
    % Calculate capillary rise
    compi = Soil.nComp; % Start at bottom of root zone
    WCr = 0; % Capillary rise counter
    while (round(MaxCR*1000)>0) && (compi > 0) 
        % Proceed upwards until maximum capillary rise occurs, soil surface
        % is reached, or encounter a compartment where downward
        % drainage/infiltration has already occurred on current day       
        % Find layer of current compartment
        layeri = Soil.Comp.Layer(compi);
        % Calculate driving force
        if (NewCond.th(compi) >= Soil.Layer.th_wp(layeri)) && (Soil.fshape_cr > 0)
            Df = 1-(((NewCond.th(compi)-Soil.Layer.th_wp(layeri))/...
                (NewCond.th_fc_Adj(compi)-Soil.Layer.th_wp(layeri)))^Soil.fshape_cr);
            if Df > 1
                Df = 1;
            elseif Df < 0
                Df = 0;
            end
        else
            Df = 1;
        end
        % Calculate relative hydraulic conductivity
        thThr = (Soil.Layer.th_wp(layeri)+Soil.Layer.th_fc(layeri))/2;
        if NewCond.th(compi) < thThr
            if (NewCond.th(compi) <= Soil.Layer.th_wp(layeri)) ||...
                    (thThr <= Soil.Layer.th_wp(layeri))
                Krel = 0;
            else
                Krel = (NewCond.th(compi)-Soil.Layer.th_wp(layeri))/...
                    (thThr-Soil.Layer.th_wp(layeri));
            end
        else
            Krel = 1;
        end
        % Check if room is available to store water from capillary rise
        dth = NewCond.th_fc_Adj(compi)-NewCond.th(compi);
        dth = round((dth*1000))/1000;
        
        % Store water if room is available
        if (dth > 0) && ((zBot-Soil.Comp.dz(compi)/2) < zEmitter)
            dthMax = Krel*Df*MaxCR/(1000*Soil.Comp.dz(compi));
            if dth >= dthMax
                NewCond.th(compi) = NewCond.th(compi)+dthMax;
                CRcomp = dthMax*1000*Soil.Comp.dz(compi);
                MaxCR = 0;
            else
                NewCond.th(compi) = NewCond.th_fc_Adj(compi);
                CRcomp   = dth*1000*Soil.Comp.dz(compi);
                MaxCR = (Krel*MaxCR)-CRcomp;
            end
            WCr = WCr+CRcomp;
        end
        % Update bottom elevation of compartment
        zBot = zBot-Soil.Comp.dz(compi);
        % Update compartment and layer counters
        compi = compi-1;
        % Update restriction on maximum capillary rise
        if compi > 0
            layeri = Soil.Comp.Layer(compi);
            zBotMid = zBot-(Soil.Comp.dz(compi)/2);
            if (Soil.Layer.Ksat(layeri) > 0) && (zEmitter > 0) && ((zEmitter-zBotMid) < 4)
                if zBotMid >= zEmitter
                    LimCR = NetIrr;
                else
                    LimCR = exp((log(zEmitter-zBotMid)-Soil.Layer.bCR(layeri))/...
                        Soil.Layer.aCR(layeri));
                    if LimCR > NetIrr
                        LimCR = NetIrr;
                    end
                end
                
            else
                LimCR = 0;
            end
            
            if MaxCR > LimCR
                MaxCR = LimCR;
            end
        end
    end
    % Store total depth of capillary rise
    CrTot = WCr;
end

end

