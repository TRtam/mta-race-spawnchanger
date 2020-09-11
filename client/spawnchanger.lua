--
-- SpawnChanger
--
local SpawnChanger = {};
SpawnChanger.cache           = {};
SpawnChanger.vehiclesColor   = {255, 255, 255};
SpawnChanger.vehiclesAlpha   = 100;
SpawnChanger.enabled         = false;
SpawnChanger.currentIndex    = 0;
SpawnChanger.minIndex        = 1;
SpawnChanger.maxIndex        = 0;
SpawnChanger.showVehiclesKey = "c";
SpawnChanger.hashedMapName   = false;

function SpawnChanger.getSpawnpoints()
    local spawnpoints = {};

    for i, spawnpoint in ipairs(getElementsByType("spawnpoint")) do
        local vModel    = getElementData(spawnpoint, "vehicle");
        local vPosition = {getElementData(spawnpoint, "posX"), getElementData(spawnpoint, "posY"), getElementData(spawnpoint, "posZ")};
        local vRotation = {getElementData(spawnpoint, "rotX"), getElementData(spawnpoint, "rotY"), getElementData(spawnpoint, "rotation") or getElementData(spawnpoint, "rotZ")};
        local vehicle   = createVehicle(vModel, vPosition[1], vPosition[2], vPosition[3], vRotation[1], vRotation[2], vRotation[3]);

        if(isElement(vehicle))then
            setVehicleColor(vehicle, SpawnChanger.vehiclesColor[1], SpawnChanger.vehiclesColor[2], SpawnChanger.vehiclesColor[3]);
            setElementAlpha(vehicle, SpawnChanger.vehiclesAlpha);
            setElementCollisionsEnabled(vehicle, false);
            setElementFrozen(vehicle, true);
            setElementDimension(vehicle, 999);

            table.insert(spawnpoints, i, {vehicle = vehicle, vModel = vModel, vPosition = vPosition, vRotation = vRotation});
        end
    end

    return spawnpoints;
end

function SpawnChanger.changeSpawnpoint(index)
    local spawnpoint = SpawnChanger.cache[index or SpawnChanger.currentIndex];

    if(spawnpoint)then
        triggerServerEvent("SpawnChanger.changeSpawnpoint", resourceRoot, spawnpoint.vModel, spawnpoint.vPosition, spawnpoint.vRotation);

        for i, spawnpoint in ipairs(SpawnChanger.cache) do
            if(isElement(spawnpoint.vehicle))then
                if(i == SpawnChanger.currentIndex)then
                    setElementAlpha(spawnpoint.vehicle, 0);
                else
                    setElementAlpha(spawnpoint.vehicle, SpawnChanger.vehiclesAlpha);
                end
            end
        end
    end
end

function SpawnChanger.handleMapStarting(mapInfo)
    SpawnChanger.cache         = SpawnChanger.getSpawnpoints();
    SpawnChanger.minIndex      = 1;
    SpawnChanger.maxIndex      = #SpawnChanger.cache;
    SpawnChanger.currentIndex  = SpawnChanger.minIndex;
    SpawnChanger.enabled       = true;
    SpawnChanger.hashedMapName = md5(mapInfo.name);

    if(fileExists("spawnpoints/" .. SpawnChanger.hashedMapName))then
        local file = fileOpen("spawnpoints/" .. SpawnChanger.hashedMapName, true);

        if(file)then
            local fileSize    = fileGetSize(file);
            local fileContent = fileRead(file, fileSize);
            fileContent       = tonumber(fileContent);

            fileClose(file);

            if(fileContent)then
                SpawnChanger.currentIndex = math.min(math.max(SpawnChanger.minIndex, fileContent), SpawnChanger.maxIndex);
            end
        end
    end

    SpawnChanger.changeSpawnpoint();
end
addEvent("onClientMapStarting");
addEventHandler("onClientMapStarting", localPlayer, SpawnChanger.handleMapStarting);

function SpawnChanger.handleMouseWheel(key, state)
    if(SpawnChanger.enabled)then
        if(key == "mouse_wheel_up")then
            SpawnChanger.currentIndex = math.max(SpawnChanger.minIndex, SpawnChanger.currentIndex - 1);
            SpawnChanger.changeSpawnpoint();
        elseif(key == "mouse_wheel_down")then
            SpawnChanger.currentIndex = math.min(SpawnChanger.maxIndex, SpawnChanger.currentIndex + 1);
            SpawnChanger.changeSpawnpoint();
        end
    end
end
bindKey("mouse_wheel_down", "down", SpawnChanger.handleMouseWheel);
bindKey("mouse_wheel_up", "down", SpawnChanger.handleMouseWheel);

function SpawnChanger.handleKey(key, pressed)
    if(SpawnChanger.enabled)then
        if(key == SpawnChanger.showVehiclesKey)then
            if(pressed)then
                showCursor(true);

                for i, spawnpoint in ipairs(SpawnChanger.cache) do
                    if(isElement(spawnpoint.vehicle))then
                        setElementDimension(spawnpoint.vehicle, getElementDimension(localPlayer));

                        if(i == SpawnChanger.currentIndex)then
                            setElementAlpha(spawnpoint.vehicle, 0);
                        else
                            setElementAlpha(spawnpoint.vehicle, SpawnChanger.vehiclesAlpha);
                        end
                    end
                end
            else
                showCursor(false);

                for i, spawnpoint in pairs(SpawnChanger.cache) do
                    if(isElement(spawnpoint.vehicle))then
                        setElementDimension(spawnpoint.vehicle, 999);
                    end
                end
            end
        end
    end
end
addEventHandler("onClientKey", root, SpawnChanger.handleKey);

function SpawnChanger.handleMouseClick(button, state, cursorX, cursorY, worldX, worldY, worldZ, clickedElement)
    if(SpawnChanger.enabled)then
        if(button == "left" and state == "down" and isElement(clickedElement))then
            for i, spawnpoint in ipairs(SpawnChanger.cache) do
                if(isElement(spawnpoint.vehicle) and spawnpoint.vehicle == clickedElement)then
                    SpawnChanger.currentIndex = i;
                    SpawnChanger.changeSpawnpoint();
                end
            end
        end
    end
end
addEventHandler("onClientClick", root, SpawnChanger.handleMouseClick);

function SpawnChanger.handleRaceStateChanging(state)
    if(state == "GridCountdown")then
        for i, spawnpoint in pairs(SpawnChanger.cache) do
            if(isElement(spawnpoint.vehicle))then
                destroyElement(spawnpoint.vehicle);
            end
        end

        if(SpawnChanger.hashedMapName)then
            if(fileExists("spawnpoints/" .. SpawnChanger.hashedMapName))then
                fileDelete("spawnpoints/" .. SpawnChanger.hashedMapName);
            end

            local file = fileCreate("spawnpoints/" .. SpawnChanger.hashedMapName);

            if(file)then
                fileWrite(file, tostring(SpawnChanger.currentIndex));
                fileFlush(file);
                fileClose(file);
            end
        end
        
        SpawnChanger.cache   = {};
        SpawnChanger.enabled = false;

        showCursor(false);
    end
end
addEvent("SpawnChanger.onRaceStateChanging", true);
addEventHandler("SpawnChanger.onRaceStateChanging", resourceRoot, SpawnChanger.handleRaceStateChanging);