
return {
	
	LrSdkVersion        = 3.0,
	LrSdkMinimumVersion = 3.0,
	LrToolkitIdentifier = "com.zerenesystems.zsloader",
	LrPluginInfoUrl     = "http://zerenesystems.com/stacker",
	LrPluginName        = "Zerene Stacker Plugin",  -- in File > Plug-in Manager

	VERSION = {
		display = "0.1"
	},

	LrExportMenuItems = {
		title       = "Export to Zerene Stacker...",  -- in File > Plug-in Extras
		file        = "ExportToZereneStacker.lua",
		enabledWhen = "photosAvailable",
	},
	LrExportServiceProvider = {
		title = "Zerene Stacker", -- in File > Export...
		file  = "ZereneStackerExportServiceProvider.lua",
		builtInPresetsDir = "presets",
	},
}
