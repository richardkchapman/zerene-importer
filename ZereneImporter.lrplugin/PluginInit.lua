-- Lightroom SDK
local LrLogger 		= import "LrLogger"
local LrDialogs		= import "LrDialogs"
local LrFileUtils	= import "LrFileUtils"
local LrApplication	= import "LrApplication"
local LrTasks		= import 'LrTasks'
local LrPathUtils	= import 'LrPathUtils'
local LrStringUtils	= import 'LrStringUtils'
local LrDate		= import 'LrDate'

require 'PluginData'

local pathToPhotoMap

function auxImportFile(catalog, fileToImport, fileToStackWith)
  local photoAdded = nil
  local photoToStackWith = nil
  if nil ~= fileToImport then
    fileToImport = LrStringUtils.trimWhitespace(fileToImport)
    logger:trace("fileToImport: " .. "'"..fileToImport.."'")
    if(LrFileUtils.exists(fileToImport)) then 
      photoAdded = catalog:findPhotoByPath(fileToImport)
      if nil == photoAdded then
        if nil ~= fileToStackWith then
          photoToStackWith = catalog:findPhotoByPath(fileToStackWith)
        end
        catalog:withWriteAccessDo("Import from Application",
          function(context)
            if nil ~= fileToStackWith then
              photoAdded = catalog:addPhoto(fileToImport, photoToStackWith)
              if nil ~= photoAdded then
                logger:trace("Photo added: " .. fileToImport .. ", fileToStackWith: " .. fileToStackWith)
              else
                logger:trace("Photo not added: " .. fileToImport .. ", fileToStackWith: " .. fileToStackWith)
              end
            else
              photoAdded = catalog:addPhoto(fileToImport)
              if nil ~= photoAdded then
                logger:trace("Photo added without stacking: " .. fileToImport)
              else
                logger:trace("Photo not added without stacking: " .. fileToImport)
              end
            end
          end
        )
      else
        logger:trace("last fileToImport has been imported before")
      end
    -- else
      -- logger:trace("last fileToImport does not exist")
    end
  else
    logger:trace("trying to import nil fileToImport in auxImportFile")
  end
  return photoAdded
end

function tryToImportFromFile(fileName)
  logger:trace("Test import started for file: " .. fileName)
  if LrFileUtils.exists(fileName) then
    local importedPhotos = {}
    local fileData = LrFileUtils.readFile(fileName)
    local stackWith = nil
    local catalog = LrApplication.activeCatalog()
    for s in fileData:gmatch("[^\r\n]+") do
      if stackWith == nil then
        stackWith = s
        -- logger:trace("Stack with file "..s)
      else
        local photoImported = auxImportFile(catalog, s, stackWith)
        if nil ~= photoImported then
          table.insert(importedPhotos, photoImported)
        end
      end
    end
    if #importedPhotos > 0 then
      catalog:setSelectedPhotos(importedPhotos[1], importedPhotos)
    end
    LrFileUtils.delete(fileName)
  end
end

function isZereneRunning()
  local a = LrTasks.execute( _PLUGIN.path .. "/isZereneRunning.sh" )
  return a == 0
end

logger = LrLogger(PluginData.ziLoggerFileName)
if PluginData.ziUseLogging then
  logger:enable("logfile")
end

logger:trace("======= PluginInit Loaded " .. os.date() .. " =======")

local standardTempDirPath = LrPathUtils.getStandardFilePath('temp')
local triggerFileName = LrPathUtils.child(standardTempDirPath, PluginData.ziTriggerFileName)
local triggerDirectoryName = LrPathUtils.child(standardTempDirPath, PluginData.ziProjectDirectoryName)

--g_isPluginRunning is used since async task can be running even after plug-in shutdown
g_isPluginRunning = 1

LrTasks.startAsyncTask( function()
  while g_isPluginRunning == 1 do
    if LrFileUtils.exists(triggerFileName) then
      -- logger:trace(""..triggerFileName.." exists")
      if not isZereneRunning() then
        -- logger:trace("Zerene is not running")
        tryToImportFromFile(triggerFileName)
      end
    end
    --sleep for 1 second
    LrTasks.sleep(1)
  end
end)
