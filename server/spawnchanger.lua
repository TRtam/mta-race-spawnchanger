--
-- SpawnChanger
--
local SpawnChanger = {};

function SpawnChanger.changeSpawnpoint(vModel, vPosition, vRotation)
    if(client)then
        local vehicle = getPedOccupiedVehicle(client);

        setElementModel(vehicle, vModel);
        setElementPosition(vehicle, vPosition[1], vPosition[2], vPosition[3]);
        setElementRotation(vehicle, vRotation[1], vRotation[2], vRotation[3]);
    end
end
addEvent("SpawnChanger.changeSpawnpoint", true);
addEventHandler("SpawnChanger.changeSpawnpoint", resourceRoot, SpawnChanger.changeSpawnpoint);

function SpawnChanger.handleRaceStateChanging(state)
    triggerClientEvent(root, "SpawnChanger.onRaceStateChanging", resourceRoot, state);
end
addEvent("onRaceStateChanging");
addEventHandler("onRaceStateChanging", root, SpawnChanger.handleRaceStateChanging);