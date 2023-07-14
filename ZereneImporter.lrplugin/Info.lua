return
{
	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 3.0,

	LrPluginName = "Zerene Importer",
	LrToolkitIdentifier = "zerenesystems.zsimporter",
	
	LrInitPlugin = "PluginInit.lua",
	LrShutdownPlugin = "PluginShutdown.lua",
	LrExportServiceProvider =
	{
		title = "Zerene Importer",
		file = "PluginService.lua",
	},

	VERSION = { display="0.1", },
}
