
require("ZereneStackerUploadTask.lua")

return {
	-- hideSections = { 'exportLocation', 'postProcessing' },
	showSections = { 'fileNaming', 'fileSettings', 'imageSettings', 'metadata', 'outputSharpening' },
	allowFileFormats = { 'TIFF', 'JPEG' },
	allowColorSpaces = { 'AdobeRGB','sRGB','ProPhotoRGB' },
	hidePrintResolution = false,
	exportPresetFields = { key = 'zsPath', default = '' },
	processRenderedPhotos = ZereneStackerUploadTask.processRenderedPhotos
}
