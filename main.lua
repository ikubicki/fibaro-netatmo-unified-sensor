--[[
Netatmo Unified Sensor
@author ikubicki
@version 1.1.1
]]
function QuickApp:onInit()
    self.config = Config:new(self)
    self.i18n = i18n:new(api.get("/settings/info").defaultLanguage)
    self.netatmo = Netatmo:new(self.config)
    self:trace('')
    self:trace('Netatmo Unified Sensor - ' .. self:getTypeLabel())
    self:updateProperty('manufacturer', 'Netatmo')
    self:updateProperty('model', 'Weather Station')
    self:updateView("button2_1", "text", self.i18n:get('search-devices'))
    self:updateView("button2_2", "text", self.i18n:get('refresh'))
    self.interfaces = api.get("/devices/" .. self.id).interfaces
    self:run()
end

function QuickApp:run()
    self:pullNetatmoData()
    local interval = self.config:getTimeoutInterval()
    if (interval > 0) then
        fibaro.setTimeout(interval, function() self:run() end)
    end
end

function QuickApp:pullNetatmoData()
    self:updateView("button2_2", "text", self.i18n:get('refreshing'))
    local getSensorDataCallback = function(sensorData)
        local property = self:getProperty()
        self:updateProperty("value", sensorData.data[property])
        if sensorData.battery ~= nil then
            self:updateProperty("batteryLevel", sensorData.battery)
            if not utils:contains(self.interfaces, "battery") then
                api.put("/devices/" .. self.id, { interfaces = {"quickApp", "battery"} })
            end
        else
            self:updateProperty("batteryLevel", sensorData.battery)
            if not utils:contains(self.interfaces, "power") then
                api.put("/devices/" .. self.id, { interfaces = {"quickApp", "power"} })
            end
        end
        self:updateView("label", "text", string.format(self.i18n:get('last-update'), os.date('%Y-%m-%d %H:%M:%S')))
        self:updateView("button2_2", "text", self.i18n:get('refresh'))
    end
    local types = self:getType()
    local id = self.config:getModuleID()
    self.netatmo:getSensorData(types, id, getSensorDataCallback)
end

function QuickApp:refreshEvent()
    self:pullNetatmoData()
end

function QuickApp:searchEvent()
    self:debug(self.i18n:get('searching-devices'))
    self:updateView("button2_1", "text", self.i18n:get('searching-devices'))
    local searchDevicesCallback = function(stations)
        -- QuickApp:debug(json.encode(stations))
        -- printing results
        for _, station in pairs(stations) do
            QuickApp:trace(string.format(self.i18n:get('search-row-station'), station.name, station.id))
            QuickApp:trace(string.format(self.i18n:get('search-row-station-modules'), #station.modules))
            for __, module in ipairs(station.modules) do
                QuickApp:trace(string.format(self.i18n:get('search-row-module'), module.name, module.id, module.type))
                QuickApp:trace(string.format(self.i18n:get('search-row-module_types'), table.concat(module.data_type, ', ')))
            end
        end
        self:updateView("button2_1", "text", self.i18n:get('search-devices'))
        self:updateView("label", "text", string.format(self.i18n:get('check-logs'), 'QUICKAPP' .. self.id))
    end
    local types = self:getType()
    self.netatmo:searchDevices(types, searchDevicesCallback)
end

function QuickApp:getType()
    if self.type == "com.fibaro.temperatureSensor" or self.config:getDeviceType() == "Temperature" then 
        return { "NAMain", "NAModule1", "NAModule4" } 
    end
    if self.type == "com.fibaro.windSensor" or self.config:getDeviceType() == "Wind" or self.config:getDeviceType() == "Gusts" or self.config:getDeviceType() == "Gust" then 
        self:updateProperty("unit", "km/h")
        return { "NAModule2" } 
    end
    if self.type == "com.fibaro.rainSensor" or self.config:getDeviceType() == "Rain" then 
        return { "NAModule3" } 
    end
    if self.type == "com.fibaro.humiditySensor" or self.config:getDeviceType() == "Humidity" then 
        return { "NAMain", "NAModule1", "NAModule4" } 
    end
    if self.config:getDeviceType() == "Pressure" then
        return { "NAMain" }
    end
    if self.config:getDeviceType() == "Noise" then
        return { "NAMain" }
    end
    if self.config:getDeviceType() == "CO2" then
        return { "NAMain", "NAModule4" } 
    end
end

function QuickApp:getTypeLabel()
    if self.type == "com.fibaro.temperatureSensor" or self.config:getDeviceType() == "Temperature" then 
        return "Temperature"
    end
    if self.type == "com.fibaro.windSensor" or self.config:getDeviceType() == "Wind" then
        return "Wind"
    end
    if self.config:getDeviceType() == "Gusts" or self.config:getDeviceType() == "Gust" then 
        return "Gusts"
    end
    if self.type == "com.fibaro.rainSensor" or self.config:getDeviceType() == "Rain" then 
        return "Rain"
    end
    if self.type == "com.fibaro.humiditySensor" or self.config:getDeviceType() == "Humidity" then 
        return "Humidity"
    end
    if self.config:getDeviceType() == "Pressure" then
        return "Pressure"
    end
    if self.config:getDeviceType() == "Noise" then
        return "Noise"
    end
    if self.config:getDeviceType() == "CO2" then
        return "CO2"
    end
end

function QuickApp:getProperty()
    if self.type == "com.fibaro.temperatureSensor" or self.config:getDeviceType() == "Temperature" then 
        return "Temperature"
    end
    if self.config:getDeviceType() == "Gusts" or self.config:getDeviceType() == "Gust" then 
        return "GustStrength"
    end
    if self.type == "com.fibaro.windSensor" or self.config:getDeviceType() == "Wind" then
        return "WindStrength"
    end
    if self.config:getDeviceType() == "Rain1h" or self.config:getDeviceType() == "Rain1" then 
        return "sum_rain_1"
    end
    if self.config:getDeviceType() == "Rain24h" or self.config:getDeviceType() == "Rain24" then 
        return "sum_rain_24"
    end
    if self.type == "com.fibaro.rainSensor" or self.config:getDeviceType() == "Rain" then 
        return "Rain"
    end
    if self.type == "com.fibaro.humiditySensor" or self.config:getDeviceType() == "Humidity" then 
        return "Humidity"
    end
    if self.config:getDeviceType() == "Pressure" then
        return "Pressure"
    end
    if self.config:getDeviceType() == "Noise" then
        return "Noise"
    end
    if self.config:getDeviceType() == "CO2" then
        return "CO2"
    end
end
