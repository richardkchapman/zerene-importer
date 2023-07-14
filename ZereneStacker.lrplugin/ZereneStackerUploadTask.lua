
local LrApplication = import( "LrApplication" )
local LrErrors      = import( "LrErrors" )
local LrFileUtils   = import( "LrFileUtils" )
local LrPathUtils   = import( "LrPathUtils" )
local LrDate        = import( "LrDate" )
local LrShell       = import( "LrShell" )
local LrTasks       = import( "LrTasks" )
local prefs         = import( "LrPrefs" ).prefsForPlugin()
local LrLogger      = import( "LrLogger" )
local zsLogger      = LrLogger( "ZSLogger" )

zsLogger:enable( "logfile" )

ZereneStackerUploadTask = {}

ZereneStackerUploadTask.outputToLog = function( msg )
	zsLogger:trace( msg )
end

ZereneStackerUploadTask.processRenderedPhotos = function( functionContext, exportContext )
	require( "ZereneStackerApp.lua" )
	ZereneStackerApp.getPath()
	ZereneStackerUploadTask.outputToLog( string.format("ZereneStackerUploadTask.processRenderedPhotos prefs.zsPath: %s", prefs.zsPath ) )
	local appPath = prefs.zsPath
	if not LrFileUtils.exists( appPath ) then
		errmsg = "Could not find path to Zerene Stacker application: "..appPath.."\n\nTo fix this problem, launch Zerene Stacker once by using its own icon, then go to Options > Plugins... > Lightroom, and re-create the Lightroom plugin."
		ZereneStackerUploadTask.outputToLog( errmsg )
		LrErrors.throwUserError( errmsg )
		return
	end
--- local parentTempPath = LrPathUtils.getStandardFilePath( "temp" )
--- or other folder as overridden by user input when the plugin is created
	local parentTempPath = LrPathUtils.getStandardFilePath( "temp" )
	local tempPath = nil
	repeat
	do
		local now = LrDate.currentTime()
		tempPath = LrPathUtils.child( parentTempPath, "Lightroom_Export_to_ZereneStacker_"..LrDate.timeToUserFormat(now, "%Y%m%d%H%M%S") )
		if LrFileUtils.exists(tempPath) then
			tempPath = nil
		else
			LrFileUtils.createAllDirectories( tempPath )
		end
	end until tempPath
	ZereneStackerUploadTask.outputToLog( string.format("tempPath: %s", tempPath) )
	
	local exportSession = exportContext.exportSession
	local exportParams  = exportSession.propertyTable
	local nPhotos       = exportSession:countRenditions()
	local firstSource   = nil
	ZereneStackerUploadTask.outputToLog( string.format("nPhotos = %d", nPhotos) )
	if nPhotos >= 1 then
		local progressScope
		progressScope = exportContext:configureProgress({
			title = LOC(string.format("$$$/Zerene Stacker/Upload/Progress=Exporting %d photos to Zerene Stacker", nPhotos))
		})

		-- NEW FEATURE - copy zerene batch file 
		if true then
			local myPath = _PLUGIN.path
			local batchFile = LrPathUtils.child( myPath, "ZereneBatch.xml")
			local destBatchFile = LrPathUtils.child( tempPath, "ZereneBatch.xml")
			local success, message = LrFileUtils.copy( batchFile, destBatchFile )
			if not success then
				if message == nil then
					message = " (reason unknown)"
				end
				ZereneStackerUploadTask.outputToLog( "Unable to copy batch file "..batchFile.." to "..destBatchFile..": "..message )
				LrErrors.throwUserError( "Unable to copy batch file "..batchFile.." to "..destBatchFile..": "..message )
				LrFileUtils.delete(tempPath)
				return
			end
		end

		for i, rendition in exportContext:renditions({stopIfCanceled = true}) do
			local success, pathOrMessage = rendition:waitForRender()
			sourcePath = rendition.photo:getRawMetadata( 'masterPhoto' ):getRawMetadata( 'path' )
			ZereneStackerUploadTask.outputToLog( "source path " .. sourcePath )
			if progressScope:isCanceled() then
				LrFileUtils.delete(tempPath)
				return
			end
			if success then
				ZereneStackerUploadTask.outputToLog( string.format("destination path: %s",
					rendition.destinationPath) )
				local copyPath = LrPathUtils.child(tempPath, LrPathUtils.leafName(rendition.destinationPath))
				local success, message
				if LrFileUtils.pathsAreOnSameVolume( rendition.destinationPath, copyPath ) then
					ZereneStackerUploadTask.outputToLog( string.format("movePath: %s", copyPath) )
					success, message = LrFileUtils.move( rendition.destinationPath, copyPath )
				else
					ZereneStackerUploadTask.outputToLog( string.format("copyPath: %s", copyPath) )
					success, message = LrFileUtils.copy( rendition.destinationPath, copyPath )
				end
				if success then
					-- After copy for ZS has been made, delete LR's temp file.  This will avoid
					-- requiring double the space for the whole set of photos.
					LrFileUtils.delete( rendition.destinationPath )
					if i == 1 then
						firstSource = sourcePath
					end
				else
					if message == nil then
						message = " (reason unknown)"
					end
					ZereneStackerUploadTask.outputToLog( "Unable to copy file "..copyPath..message )
					LrErrors.throwUserError( "Unable to copy: "..copyPath..message )
					LrFileUtils.delete(tempPath)
					return
				end
			else
				ZereneStackerUploadTask.outputToLog( "Unable to export = "..pathOrMessage )
				LrErrors.throwUserError( "Unable to export: "..pathOrMessage )
				LrFileUtils.delete(tempPath)
				return
			end
		end
	end
	if firstSource ~= nil then
		if WIN_ENV then
			--- ZereneStackerUploadTask.outputToLog( "just before LrShell.openFilesInApp" )
			LrShell.openFilesInApp( { "-lrplugin", tempPath, "-sourcePath="..sourcePath }, prefs.zsPath )
			--- ZereneStackerUploadTask.outputToLog( "just after LrShell.openFilesInApp" )
		else
			openCmd = '/usr/bin/open'
			if not LrFileUtils.exists(openCmd) then -- we have an odd situation
				openCmd = 'open'  -- which we hope is covered by finding 'open' elsewhere on the current path
			end
			osCmd = openCmd .. ' -n ' .. '"' ..prefs.zsPath.. '" --args -noSplashScreen -lrplugin "' ..tempPath.. '" "-sourcePath=' ..firstSource .. '"'
			ZereneStackerUploadTask.outputToLog( "osCmd = ["..osCmd.."]" )
			ZereneStackerUploadTask.outputToLog( "just before LrTasks.execute" )
			status = LrTasks.execute( osCmd )
			if status ~= 0 then
				LrErrors.throwUserError( 'Failed to open Zerene Stacker, error code = ' .. status )
			end
			ZereneStackerUploadTask.outputToLog( "just after LrTasks.execute, exit status = "..status )
		end
		local fileListFilePath = LrPathUtils.child(parentTempPath, "zereneexport.txt")
		local fileListFile = io.open(fileListFilePath, "w")
		if nil ~= fileListFile then
			ZereneStackerUploadTask.outputToLog("file is created for writing: " .. fileListFilePath)
			local baseName = LrPathUtils.removeExtension(firstSource).."-"..nPhotos.." ZS "
			ZereneStackerUploadTask.outputToLog("baseName is: " .. baseName)
			fileListFile:write(firstSource.."\n")
			fileListFile:write(baseName .. "PMax.tif\n")
			fileListFile:write(baseName .. "DMap.tif\n")
			fileListFile:write(baseName .. "Retouched.tif\n")
			fileListFile:flush()
 			fileListFile:close()
		end
	end

end
