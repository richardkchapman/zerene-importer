
local LrApplication   = import( "LrApplication" )
local LrErrors        = import( "LrErrors" )
local LrFileUtils     = import( "LrFileUtils" )
local LrTasks         = import( "LrTasks" )
local LrShell         = import( "LrShell" )
local LrExportSession = import( "LrExportSession" )
local prefs           = import("LrPrefs").prefsForPlugin()
local LrLogger        = import("LrLogger")
local zsLogger        = LrLogger("ZSLogger")

zsLogger:enable("logfile")

ExportToZereneStacker = {}

ExportToZereneStacker.outputToLog = function(param)
  zsLogger:trace(param)
end

LrTasks.startAsyncTask( function()
	--- ExportToZereneStacker.outputToLog("Entering outer LrTasks.startAsyncTask function")
	local activeCatalog = LrApplication.activeCatalog()
	local sourceFrames = activeCatalog.targetPhotos
	local exportSession = LrExportSession( {
		exportSettings = {
			LR_exportServiceProvider       = "com.zerenesystems.zsloader",
			LR_exportServiceProviderTitle  = "Zerene Stacker",
			LR_format                      = "TIFF",
			LR_tiff_compressionMethod      = "compressionMethod_None",
			LR_export_bitDepth             = 16,
			LR_export_colorSpace           = "AdobeRGB",
			LR_minimizeEmbeddedMetadata    = false,
			LR_metadata_keywordOptions     = "lightroomHierarchical",
			LR_removeLocationMetadata      = false
			},
		photosToExport = sourceFrames,
		} )
	--- ExportToZereneStacker.outputToLog("Before doExportOnCurrentTask()")
	exportSession:doExportOnCurrentTask()		
	--- ExportToZereneStacker.outputToLog("After doExportOnCurrentTask()")
	--- ExportToZereneStacker.outputToLog("Exiting outer LrTasks.startAsyncTask function")
end )
