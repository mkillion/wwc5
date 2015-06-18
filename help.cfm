<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<cfoutput>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>#application.title# Map Viewer Help</title>
<style type="text/css">
	fieldset, td {
		font:normal normal normal 12px arial;
		}

	legend {
		font:normal normal bold 12px arial;
		}
</style>
</head>

<body>
<div id="help">
<table width="100%">
<tr>
	<td align="left" width="50%" style="font-weight:bold">#application.title# Map Viewer Help</td>
    <td align="right" width="50%">
    	For questions about WWC5 data contact the <a href="mailto:datares@kgs.ku.edu">Data Resources Library</a> (785-864-2161).<br />
    	For questions or problems regarding the map viewer contact <a href="mailto:killion@kgs.ku.edu?subject=KGS oil and gas map viewer">GIS Services</a> (785-864-2131).
    </td>
</tr>
</table>
<p>
<fieldset>
<legend>Supported Browsers</legend>
	The following web browsers are supported:
	<ol>
    	<li>Chrome</li>
    	<li>Safari</li>
        <li>Firefox</li>
        <li>Internet Explorer</li>
    </ol>
</fieldset>
<p>
<fieldset>
<legend>Navigation</legend>
	ZOOM IN / ZOOM OUT
	<ul>
        <li>Use the slider on the left side of the map to change zoom level</li>
        <li>SHIFT and drag to select an area and zoom in</li>
        <li>SHIFT and CTRL and drag to select an area and zoom out</li>
        <li>Mouse scroll backward to zoom out</li>
        <li>Mouse scroll forward to zoom in</li>
        <li>Minus (-) key to zoom out a level</li>
        <li>Plus (+) key to zoom in a level</li> 
    </ul>
    PAN
    <ul>
        <li>Use arrows on sides of map to pan</li>
        <li>Click and drag map to pan</li>
        <li>Use arrow keys to pan</li>

	</ul>
    ZOOM TO LOCATION
    <ul>
    	<li>Select the area to zoom to from the drop-down lists, then click the appropriate Go button.</li>
        <li>To return to the well originally selected when entering the map, click the Go button next to Return to Original Location.</li>
    </ul>

</fieldset>
<p>
<fieldset>
<legend>Tabs</legend>
	LAYERS
	<ul>
    	<li>Controls which features are visible and their transparency.</li>
		<li>Layers can be turned on and off by checking and unchecking the box next to the layer name.</li>
    	<li>Some layers are only visible when zoomed in to a certain level. If the layer is not visible at the current scale, the layer name will be grayed out and an asterisk will appear after the name. To make the layer visible, zoom in and make certain the checkbox is checked.</li>
    	<li>Layer transparency can be controlled with the slider to the right of the layer name. Move the slider to the right to make a layer more transparent.</li>
	</ul>
    <p>

    INFO
    <ul>
    	<li>Displays information about selected map features.</li>
		<li>Single click on a well on the map to display information about that feature in the Info tab. If more than one feature is found, select the desired feature from the pop-up box.</li>
        <li>Click on the "Full KGS Database Entry" link at the bottom to view additional information from the Kansas Geological Survey about a well.</li>
	</ul>
</fieldset>
<p>
<fieldset>
<legend>Tools</legend>
	STATEWIDE VIEW
    <ul><li>Click on this link to zoom out to the full extent of the state.</li></ul>
    ZOOM TO LOCATION
    <ul>
    	<li>Select the area to zoom to from the drop-down lists, then click the appropriate Go button.</li>
        <li>To return to the well originally selected when entering the map, click the Go button next to Return to Original Location.</li>
    </ul>
    FILTER WELLS
    <ul>
    	<li>Restrict which water wells are displayed on the map by selecting from the menu.</li>
        <li>To turn the filter off and display all wells, either click the 'Show All Wells' button at the bottom of the map, or select 'Show All Wells' from the menu.</li>
    </ul>
	LABEL WELLS
    <ul><li>Select labels wells from the menu.</li></ul>
    CLASSIFY WELLS
    <ul>
    	<li>Wells can be color coded by estimated yield, completed well depth, or static water level.</li>
        <li>To removed the classification, select 'No Classification' from the menu or click the 'Remove Classification' button at the bottom of the map.</li>
    </ul>
    DOWNLOAD WELLS
	<ul>
        <li>Creates a zip file containing comma-delimited text files well and lithologic log information for wells visible in the current map extent.</li>
        <li>If a filter is in effect, the download will also be filtered.</li>
        <li>The dialog box will close and another will open when your files are ready (usually about 1 minute).</li>
        <li>You may continue to use the map while the progress indicator is displayed.</li>
        <li>To open the files in Excel:</li>
    	<ul>
        	<li>Unzip the download file.</li>
        	<li>Open Excel.</li>
        	<li>Choose Open from the File menu.</li>
        	<li>Change 'Files of Type' to 'All Files'.</li>
			<li>Find your file and open.</li>
			<li>When the Text Import Wizard opens check Delimited in step 1, then click on Next.</li>
			<li>In step 2 check Comma, then click Finish (or Next if you want to format your fields before opening).</li>
        </ul>
        <li>
        	Other options to download well data are provided through the <a href="http://www.kgs.ku.edu/Magellan/WaterWell/index.html">WWC5 database</a>.
        </li>
    </ul>
    CLEAR HIGHLIGHT
    <ul><li>Click this link to remove the yellow outline around selected features.</li></ul>
    PRINT TO PDF
    <ul>
    	<li>Creates a PDF of the map (including layer transparencies and highlights) in a new browser window.</li>
        <li>The PDF can be printed or saved to disk when the PDF window opens.</li>
        <li>Choosing the "map only" option creates a jpeg image of the map without any surrounding text or map elements.</li>
        <li>NOTE: To display the PDF, pop-up blockers must be turned off or set to allow pop-ups from 'maps.kgs.ku.edu'</li>
    </ul>
</fieldset>
<!---<p>
<fieldset>
<legend>Printing</legend>
	A "Print Map" function will be added in a future version of the map viewer. In the meantime, there are two methods for printing or capturing the map image.
    <p>
    First, a screen capture program can be used to clip out the map and save it as a jpeg image that can be pasted into other documents. There are a variety of free and fee-based screen capture tools available on the Internet, and Windows Vista includes a Snipping Tool.
    <p>
	Second, the map can be printed from the File/Print menu of the browser. This option will also print all of the surrounding frames, including the right-side panels. To print the legend, make sure the legend tab is open. For best results, enable printing of background colors and images (see instructions for specific browsers below).
	<p>
	IE6 and IE7
    <ul>
    	<li>Go to menu Tools > Internet Options</li>
        <li>Select Advanced tab</li>
        <li>Scroll down to Printing</li>
        <li>Check 'Print background colors and images'</li>
    </ul>
    FIREFOX (Windows)
    <ul>
    	<li>Go to menu File > Page Setup</li>
        <li>Select Format & Options tab</li>
        <li>Check 'Print background colors and images'</li>
        <li>Firefox version 3+ may be required</li>
    </ul>
    FIREFOX (Mac)
    <ul>
    	<li>Go to menu File > Print</li>
        <li>Check 'Print background colors' and 'Print background images'</li>
    </ul>
    SAFARI (Mac)
    <ul>
    	<li>Go to menu File > Print</li>
        <li>Check 'Print backgrounds'</li>
    </ul>
</fieldset>--->
</div>
</body>
</html>
</cfoutput>