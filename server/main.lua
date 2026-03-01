local targets = {}

local function broadcastTargets(playerId)
    for id, data in pairs(targets) do
        TriggerClientEvent('cz_targetX:addTarget', playerId, id, data)
    end
end

function AddTarget(id, data)
    if not id or not data then return end
    targets[id] = data
    TriggerClientEvent('cz_targetX:addTarget', -1, id, data)
end

function RemoveTarget(id)
    targets[id] = nil
    TriggerClientEvent('cz_targetX:removeTarget', -1, id)
end

function UpdateTarget(id, data)
    if not id or not data then return end
    if not targets[id] then return end
    for k, v in pairs(data) do
        targets[id][k] = v
    end
    TriggerClientEvent('cz_targetX:updateTarget', -1, id, data)
end

exports('AddTarget', AddTarget)
exports('RemoveTarget', RemoveTarget)
exports('UpdateTarget', UpdateTarget)

AddEventHandler('playerJoining', function()
    local playerId = source
    broadcastTargets(playerId)
end)
