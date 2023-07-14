# zerene-importer
Lightroom plugin to automatically import the resulting files after focus-stacking using Zerene

Requires use of a modified version of the Zerene exporter plugin that is
installed by Zerene (see ZereneStacker.lrdata directory)

Only tested on Mac (the isZereneRunning code will need to be fixed for Windows), and tuned to the way my workflow works. 

#How it works

The exporter plugin is modified to record information about the expected names of any resulting stacked files,
along with the name of the first input file. This is recorded in the file $TMPDIR/zereneexport.txt

Additionally, a ZereneBatch.xml file is supplied to Zerene, which (a) means that it automatically starts off
with a "Stack Both" operation, and (b) means that the name of the saved files are a little predictable.

The importer plugin checks for the existence of the zereneexport.txt file, and then waits for Zerene to exit before
searching for the expected result file names. Any that are found are stacked with the first supplied input file.
This method inspired by the way DxO's importer plugin works.


