local RESOURCE_NAME = GetCurrentResourceName()
local RELEASE_API_URL = "https://api.github.com/repos/Czmenz/cz_targetX/releases/latest"

local function normalizeVersion(version)
    return tostring(version or "0.0.0"):lower():gsub("^v", ""):gsub("%s+", "")
end

local function compareVersions(a, b)
    local va = {}
    local vb = {}

    for n in normalizeVersion(a):gmatch("%d+") do
        va[#va + 1] = tonumber(n) or 0
    end

    for n in normalizeVersion(b):gmatch("%d+") do
        vb[#vb + 1] = tonumber(n) or 0
    end

    local len = math.max(#va, #vb)
    for i = 1, len do
        local na = va[i] or 0
        local nb = vb[i] or 0

        if na > nb then
            return 1
        elseif na < nb then
            return -1
        end
    end

    return 0
end

local function checkForUpdates()
    local currentVersion = Config.BuildId or GetResourceMetadata(RESOURCE_NAME, "version", 0) or "0.0.0"

    PerformHttpRequest(
        RELEASE_API_URL,
        function(statusCode, body)
            if statusCode ~= 200 or not body or body == "" then
                print(("[^3%s^7] Update check failed (HTTP %s)."):format(RESOURCE_NAME, tostring(statusCode)))
                return
            end

            local ok, payload = pcall(json.decode, body)
            if not ok or type(payload) ~= "table" then
                print(("[^3%s^7] Update check failed (invalid GitHub response)."):format(RESOURCE_NAME))
                return
            end

            local latestTag = payload.tag_name
            local releaseUrl = payload.html_url or "https://github.com/Czmenz/cz_targetX/releases"
            if type(latestTag) ~= "string" or latestTag == "" then
                print(("[^3%s^7] Update check failed (missing tag_name)."):format(RESOURCE_NAME))
                return
            end

            local cmp = compareVersions(latestTag, currentVersion)
            if cmp > 0 then
                print(("[^3%s^7] Update available: current ^1%s^7, latest ^2%s^7 | URL: %s"):format(
                    RESOURCE_NAME,
                    tostring(currentVersion),
                    tostring(latestTag),
                    tostring(releaseUrl)
                ))
            else
                print(("[^2%s^7] Running latest version: %s | URL: %s"):format(
                    RESOURCE_NAME,
                    tostring(currentVersion),
                    tostring(releaseUrl)
                ))
            end
        end,
        "GET",
        "",
        {
            ["Accept"] = "application/vnd.github+json",
            ["User-Agent"] = RESOURCE_NAME
        }
    )
end

CreateThread(function()
    Wait(2000)
    local enabled = tostring(Config.CheckForUpdates or "false"):lower() == "true"
    if enabled then
        checkForUpdates()
    end
end)
