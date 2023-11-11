--[[
Netatmo SDK
@author ikubicki
]]
class 'Netatmo'

function Netatmo:new(config)
    self.config = config
    self.user = config:getUsername()
    self.pass = config:getPassword()
    self.client_id = config:getClientID()
    self.client_secret = config:getClientSecret()
    self.device_id = config:getDeviceID()
    self.module_id = config:getModuleID()
    self.access_token = config:getAccessToken()
    self.token = Globals:get('netatmo_atoken', '')
    self.refresh_token = config:getRefreshToken()
    self.http = HTTPClient:new({})
    return self
end

function Netatmo:searchDevices(types, callback)
    if #types < 1 then types = nil end
    local buildModule = function(module)
        return {
            id = module._id,
            name = module.module_name,
            type = module.type,
            data_type = module.data_type,
        }
    end
    local buildStation = function(data)
        local station = {
            id = data._id,
            home_id = data.home_id,
            name = data.station_name,
            modules = {},
        }
        table.insert(station.modules, buildModule(data))
        return station
    end
    local getStationsDataCallback = function(devices)
        local stations = {}
        for _, device in ipairs(devices) do
            local station = buildStation(device)
            local add = false
            for _, module in ipairs(device.modules) do
                if not types or utils:contains(types, module.type) then
                    table.insert(station.modules, buildModule(module))
                    add = true
                end
            end
            if add == true then
                table.insert(stations, station)
            end
        end
        if callback ~= nil then
            callback(stations)
        end
    end
    local authCallback = function(response)
        self:getStationsData(getStationsDataCallback)
    end
    self:auth(authCallback)
end

function Netatmo:getSensorData(types, moduleID, callback)
    if callback == nil then
        callback = function() end
    end
    local getStationsDataCallback = function(devices)
        for _, device in ipairs(devices) do
            if device._id == moduleID then
                return callback({
                    id = device._id,
                    type = device.type,
                    data = device.dashboard_data,
                    name = device.module_name,
                    battery = nil,
                    dead = device.reachable ~= true,
                })
            end
            for _, module in ipairs(device.modules) do
                if module._id == moduleID then
                    return callback({
                        id = module._id,
                        type = module.type,
                        data = module.dashboard_data,
                        name = module.module_name,
                        battery = math.ceil((tonumber(module.battery_vp) - 4300) / 17),
                        dead = module.reachable,
                    })
                end
            end
        end
        if callback ~= nil then
            callback({})
        end
    end
    local authCallback = function(response)
        self:getStationsData(getStationsDataCallback)
    end
    local searchDevicesCallback = function(stations)
        if self.device_id == "" then
            QuickApp:debug(json.encode(stations))
            QuickApp:trace('Assigning DeviceID: ' .. stations[1].id)
            self:setDeviceID(stations[1].id)
        end
        if moduleID == nil or string.len(moduleID) < 10 then
            moduleID = ""
            for _, module in pairs(stations[1].modules) do
                if utils:contains(types, module.type) then
                    moduleID = module.id
                end
            end
            if moduleID ~= nil then
                QuickApp:trace('Assigning ModuleID: ' .. moduleID)
                self:setModuleID(moduleID)
            end
        end
        if string.len(moduleID) > 10 then
            self:auth(authCallback)
        elseif (callback ~= nil) then
            callback({})
        end
    end
    if string.len(moduleID) < 10 or self.device_id == "" then
        self:searchDevices(types, searchDevicesCallback)
    else
        searchDevicesCallback({{modules = {{id = moduleID}}}})
    end
end

function Netatmo:getWeatherData(callback)
    local getStationsDataCallback = function(devices)
        local device = devices[1]
        local weatherData = {
            _id = device._id,
            temp = tonumber(device.dashboard_data["Temperature"]),
            humi = tonumber(device.dashboard_data["Humidity"]),
            rain = 0,
            wind = 0,   
        }
        for _, module in pairs(device.modules) do
            if module.type == "NAModule1" then
                weatherData.temp = tonumber(module.dashboard_data.Temperature)
                weatherData.humi = tonumber(module.dashboard_data.Humidity)
            end
            if module.type == "NAModule2" then
                weatherData.wind = tonumber(module.dashboard_data.WindStrength)
            end
            if module.type == "NAModule3" then
                weatherData.rain = tonumber(module.dashboard_data.Rain)
            end
        end
        if callback ~= nil then
            callback(weatherData)
        end
    end
    local authCallback = function(response)
        self:getStationsData(getStationsDataCallback)
    end
    self:auth(authCallback)
end

function Netatmo:getStationsData(callback, attempt)
    if attempt == nil then
        attempt = 0
    end
    local fail = function(response)
        QuickApp:error('Unable to pull devices')
        QuickApp:debug(json.encode(response.data))
        Netatmo:setToken('')
        if attempt < 3 then
            attempt = attempt + 1
            fibaro.setTimeout(3000, function()
                QuickApp:debug('Netatmo:getStationData - Retry attempt #' .. attempt)
                local authCallback = function(response)
                    self:getStationsData(callback, attempt)
                end
                Netatmo:auth(authCallback)
            end)
        end
    end
    local success = function(response)
        if response.status > 299 then
            fail(response)
            return
        end
        local data = json.decode(response.data)
        if callback ~= nil then
            callback(data.body.devices)
        end
    end
    local url = 'https://api.netatmo.com/api/getstationsdata'
    if string.len(self.device_id) > 1 then
        url = url .. '?device_id=' .. self.device_id
    end
    local headers = {
        Authorization = "Bearer " .. self:getToken()
    }
    self.http:get(url, success, fail, headers)
end

function Netatmo:auth(callback)
    if string.len(self:getToken()) > 10 then
        -- QuickApp:debug('Already authenticated')
        if callback ~= nil then
            callback({})
        end
        return
    end
    if string.len(self.access_token) > 10 then
        if callback ~= nil then
            Netatmo:setToken(self.access_token)
            callback({})
        end
        return
    end
    local data = {
        ["grant_type"] = 'password',
        ["scope"] = 'read_station',
        ["client_id"] = self.client_id,
        ["client_secret"] = self.client_secret,
        ["username"] = self.user,
        ["password"] = self.pass,
    }
    if string.len(self.refresh_token) > 10 then
        data = {
            ["grant_type"] = 'refresh_token',
            ["refresh_token"] = self.refresh_token,
            ["client_id"] = self.client_id,
            ["client_secret"] = self.client_secret,
        }
    end
    local fail = function(response)
        QuickApp:error('Unable to authenticate')
        if self.access_token == self.token then
            QuickApp:error('Removing configured AccessToken')
            self.config:setAccessToken('')
        end
        Netatmo:setToken('')
    end
    local success = function(response)
        if response.status > 299 then
            fail(response)
            return
        end
        local data = json.decode(response.data)
        Netatmo:setToken(data.access_token)
        if callback ~= nil then
            callback(data)
        end
    end
    self.http:postForm('https://api.netatmo.net/oauth2/token', data, success, fail)
end

function Netatmo:setDeviceID(deviceID)
    self.device_id = deviceID
    self.config:setDeviceID(deviceID)
end

function Netatmo:setModuleID(moduleID)
    self.module_id = moduleID
    self.config:setModuleID(moduleID)
end

function Netatmo:setToken(token)
    self.token = token
    Globals:set('netatmo_atoken', token)
end

function Netatmo:getToken()
    if not self.token and self.access_token ~= nil then
        self.token = self.access_token
    end
    if string.len(self.token) > 10 then
        return self.token
    elseif string.len(Globals:get('netatmo_atoken', '')) > 10 then
        return Globals:get('netatmo_atoken', '')
    end
    return ""
end