
local prefs = import( "LrPrefs" ).prefsForPlugin()
ZereneStackerApp = {}

ZereneStackerApp.getPath = function() 
	local path = "/Applications/ZereneStacker.app"
	prefs.zsPath = path
	return path
end
