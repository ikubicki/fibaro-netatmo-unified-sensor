# Netatmo unified sensor
This quick application creates single climate sensor from Netatmo Weather Station or its modules.

Quick application detects all sensors for specified type and lists all detected sensors into logs when using Search devices button.

Data updates every 5 minutes by default.

## Configuration

`ClientID` - Netatmo client ID

`ClientSecret` - Netatmo client secret

`Username` - Netatmo username

`Password` - Netatmo password

### Optional values

`Type` - Allows to change the type of the module. Changing type requires to change the `DeviceID`. This is not applicable for Temperature, Humidity sensors. Rain sensor allows to set only `Rain` (default), `Rain1` or `Rain24`. Wind sensor allow to set only `Wind` (default) or `Gusts`.
Other sensors (because they are using generic type - Multilevel sensor type) allow to specify all of following types: `Temperature`, `Humidity`, `Rain`, `Rain1`, `Rain24`, `Wind`, `Gusts`, `Pressure`, `Noise` and `CO2`.

`DeviceID` - identifier of Netatmo Weather Station from which values should be taken. This value will be automatically populated on first successful connection to weather station.

`ModuleID` - Identifier of Netatmo Weather Station module for given DeviceID. This value will be automatically populated from first module listed for the device.

`Interval` - number of minutes defining how often data should be refreshed. This value will be automatically populated on initialization of quick application.

`AccessToken` - Allows to set own access token and bypass credentials authentication.

## Integration

This quick application integrates with other Netatmo dedicated quick apps for devices. It will automatically populate configuration to new virtual Netatmo devices.