--[[
Internationalization tool
@author ikubicki
]]
class 'i18n'

function i18n:new(langCode)
    self.phrases = phrases[langCode]
    return self
end

function i18n:get(key)
    if self.phrases[key] then
        return self.phrases[key]
    end
    return key
end

phrases = {
    pl = {
        ['search-devices'] = 'Szukaj urządzeń',
        ['searching-devices'] = 'Szukam...',
        ['refresh'] = 'Odśwież dane',
        ['refreshing'] = 'Odświeżam...',
        ['last-update'] = 'Ostatnia aktualizacja: %s',
        ['check-logs'] = 'Zakończono wyszukiwanie. Sprawdź logi tego urządzenia: %s',
        ['search-row-station'] = '__ STACJA POGODOWA %s',
        ['search-row-station-modules'] = '__ Wykryto %d modułów',
        ['search-row-module'] = '____ MODUŁ %s (ID: %s, typ: %s)',
        ['search-row-module_types'] = '____ Typy danych: %s',
        ['error-updates'] = '[%d] Nie można pobrać aktualizacji: %s',
        ['error-search'] = '[%d] Nie można wyszukać urządzeń: %s',
    },
    en = {
        ['search-devices'] = 'Search devices',
        ['searching-devices'] = 'Searching...',
        ['refresh'] = 'Update data',
        ['refreshing'] = 'Updating...',
        ['last-update'] = 'Last update at %s',
        ['check-logs'] = 'Check device logs (%s) for search results',
        ['search-row-station'] = '__ WEATHER STATION %s',
        ['search-row-station-modules'] = '__ %d modules detected',
        ['search-row-module'] = '____ MODULE %s (ID: %s, type: %s)',
        ['search-row-module_types'] = '____ Data types: %s',
        ['error-updates'] = '[%d] Failed to fetch updates: %s',
        ['error-search'] = '[%d] Failed to search for devices: %s',
    },
    de = {
        ['search-devices'] = 'Geräte suchen',
        ['searching-devices'] = 'Suchen...',
        ['refresh'] = 'Aktualisieren',
        ['refreshing'] = 'Aktualisieren...',
        ['last-update'] = 'Letztes update: %s',
        ['check-logs'] = 'Überprüfen Sie die Geräteprotokolle (%s) auf Suchergebnisse',
        ['search-row-station'] = '__ WETTERSTATION %s',
        ['search-row-station-modules'] = '__ %d module erkannt',
        ['search-row-module'] = '____ MODULE %s (ID: %s, typ: %s)',
        ['search-row-module_types'] = '____ Datentypen: %s',
        ['error-updates'] = '[%d] Updates konnten nicht abgerufen werden: %s',
        ['error-search'] = '[%d] Geräte konnten nicht gesucht werden: %s',
    }
}
