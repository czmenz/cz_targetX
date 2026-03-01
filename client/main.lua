local targets = {}
local nuiVisible = false
local nuiReady = false
local lastUiX, lastUiY, lastUiEntriesHash, lastUiScale
local orderCounter = 0

local function hideNuiPrompt()
    if not nuiVisible then return end
    nuiVisible = false
    lastUiX, lastUiY, lastUiEntriesHash, lastUiScale = nil, nil, nil, nil
    SendNUIMessage({ action = 'hide' })
end

local function buildEntriesHash(entries)
    local out = {}

    for i = 1, #entries do
        local e = entries[i]
        out[#out + 1] = ("%s:%s:%s:%s"):format(e.id or "", e.key or "", e.active and "1" or "0", e.label or "")
    end

    return table.concat(out, "|")
end

local function drawNuiPrompt(coords, entries, playerDist, drawDist)
    local worldPos = coords + vector3(0.0, 0.0, 0.45)
    local onScreen, screenX, screenY = World3dToScreen2d(worldPos.x, worldPos.y, worldPos.z)

    if not onScreen then
        hideNuiPrompt()
        return
    end

    local maxDist = drawDist or Config.DefaultDrawDistance
    local t = math.min(1.0, math.max(0.0, playerDist / math.max(maxDist, 0.01)))
    local scale = 1.05 - (t * 0.30) -- near player: bigger, far player: smaller
    local entriesHash = buildEntriesHash(entries)

    local shouldUpdate = (not nuiVisible)
        or (not lastUiX or math.abs(screenX - lastUiX) > 0.0003)
        or (not lastUiY or math.abs(screenY - lastUiY) > 0.0003)
        or (entriesHash ~= lastUiEntriesHash)
        or (not lastUiScale or math.abs(scale - lastUiScale) > 0.01)

    if not shouldUpdate then return end

    lastUiX, lastUiY, lastUiEntriesHash, lastUiScale = screenX, screenY, entriesHash, scale
    nuiVisible = true
    SendNUIMessage({
        action = 'update',
        entries = entries,
        x = screenX,
        y = screenY,
        scale = scale
    })
end

RegisterNUICallback('ready', function(_, cb)
    nuiReady = true
    cb(1)
end)

local function ensureTargetDefaults(data)
    if not data.coords then return nil end
    data.drawDistance = data.drawDistance or Config.DefaultDrawDistance
    data.interactDistance = data.interactDistance or Config.DefaultInteractDistance
    data.label = data.label or 'Interact'
    data.eventType = data.eventType or 'client'
    data.buttonId = tonumber(data.buttonId) or Config.DefaultButtonId
    data.keyLabel = data.keyLabel or CZTargetXGetKeyLabel(data.buttonId)
    return data
end

function AddTarget(id, data)
    if not id or not data then return end
    data = ensureTargetDefaults(data)
    if not data then return end
    if not data.__order then
        orderCounter = orderCounter + 1
        data.__order = orderCounter
    end
    targets[id] = data
end

function RemoveTarget(id)
    targets[id] = nil
end

function UpdateTarget(id, data)
    if not id or not data then return end
    if not targets[id] then return end
    for k, v in pairs(data) do
        targets[id][k] = v
    end
    targets[id] = ensureTargetDefaults(targets[id])
end

exports('AddTarget', AddTarget)
exports('RemoveTarget', RemoveTarget)
exports('UpdateTarget', UpdateTarget)

RegisterNetEvent('cz_targetX:addTarget', function(id, data)
    AddTarget(id, data)
end)

RegisterNetEvent('cz_targetX:removeTarget', function(id)
    RemoveTarget(id)
end)

RegisterNetEvent('cz_targetX:updateTarget', function(id, data)
    UpdateTarget(id, data)
end)

CreateThread(function()
    while true do
        local sleep = next(targets) and 0 or 250
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)
        local visibleTargets = {}
        local activeTargets = {}
        local displayTarget = nil
        local closestDisplayDistance = nil
        local activeLookup = {}

        for id, data in pairs(targets) do
            local coords = data.coords
            local dist = #(pcoords - coords)

            if dist <= data.drawDistance then
                if not closestDisplayDistance or dist < closestDisplayDistance then
                    closestDisplayDistance = dist
                    displayTarget = data
                end

                visibleTargets[#visibleTargets + 1] = {
                    id = id,
                    data = data
                }
            end

            if dist <= data.interactDistance then
                activeTargets[#activeTargets + 1] = {
                    id = id,
                    data = data,
                    dist = dist
                }
            end
        end

        if #activeTargets > 0 then
            table.sort(activeTargets, function(a, b)
                if math.abs(a.dist - b.dist) > 0.001 then
                    return a.dist < b.dist
                end
                return (a.data.__order or 0) < (b.data.__order or 0)
            end)

            for i = 1, #activeTargets do
                activeLookup[activeTargets[i].id] = true
            end
        end

        if displayTarget then
            if nuiReady then
                local entries = {}
                local anchor = displayTarget.coords

                for i = 1, #visibleTargets do
                    local info = visibleTargets[i]
                    if #(info.data.coords - anchor) <= 0.6 then
                        entries[#entries + 1] = {
                            id = info.id,
                            key = (info.data.keyLabel or "E"):upper(),
                            label = info.data.label or "Interact",
                            active = activeLookup[info.id] == true,
                            order = info.data.__order or 0
                        }
                    end
                end

                table.sort(entries, function(a, b)
                    return (a.order or 0) < (b.order or 0)
                end)

                if #entries == 0 then
                    entries[1] = {
                        id = "fallback",
                        key = (displayTarget.keyLabel or "E"):upper(),
                        label = displayTarget.label or "Interact",
                        active = false,
                        order = displayTarget.__order or 0
                    }
                end

                drawNuiPrompt(displayTarget.coords, entries, closestDisplayDistance or 0.0, displayTarget.drawDistance)
            else
                hideNuiPrompt()
            end
        else
            hideNuiPrompt()
        end

        if #activeTargets > 0 then
            for i = 1, #activeTargets do
                local activeTarget = activeTargets[i].data

                if IsControlJustReleased(0, activeTarget.buttonId) and activeTarget.event then
                    if activeTarget.eventType == 'server' then
                        TriggerServerEvent(activeTarget.event, activeTarget.args)
                    else
                        TriggerEvent(activeTarget.event, activeTarget.args)
                    end
                    break
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    hideNuiPrompt()
end)
