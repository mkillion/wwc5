
<!---
*	Adding new layers or moving code to a new app:
*	Add a <cfif Find("water",VisibleLayers)> <cfimage... block for each new layer.
*	The layer designator (e.g. "water") must match the table of contents checkbox id name in index.cfm.
--->

<cfsetting requestTimeOut = "300" showDebugOutput = "yes">

<cfset PdfFile = "wwc5_#hour(now())##minute(now())##second(now())#.pdf">

<cfdocument format="pdf" pagetype="letter" orientation="#url.orientation#" overwrite="yes" filename="\\vmpyrite\d$\webware\Apache\Apache2\htdocs\kgsmaps\oilgas\output\#PdfFile#">

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>#application.title# Image</title>
</head>

<body>
<cfoutput>

<!--- Set output size: --->
<cfset Aspect = #url.width# / #url.height#>

<cfswitch expression="#url.size#">
	<cfcase value="small">
    	<cfif Aspect gt 1.25>
        	<cfset ImgWidth = 500>
        <cfelse>
    		<cfset ImgWidth = 400>
        </cfif>
    </cfcase>
    <cfcase value="medium">
    	<cfif Aspect gt 1.25>
        	<cfset ImgWidth = 700>
        <cfelse>
    		<cfset ImgWidth = 600>
        </cfif>
    </cfcase>
    <!---<cfcase value="large">
    	<cfif Aspect gt 1.25>
        	<cfset ImgWidth = 900>
        <cfelse>
       		<cfset ImgWidth = 800>
        </cfif>
    </cfcase>--->
    <cfcase value="map">
    	<cfset ImgWidth = #url.width#>
		<cfset ImgHeight = #url.height#>
        <!---<cfimage name="scalebar" source="images/scalebars/#url.level#.gif">--->
    </cfcase>
    <cfcase value="fixed">
    	<cfset ImgWidth = 775>
        <cfset ImgHeight = 575>
    </cfcase>
</cfswitch>

<!--- Resize scalebar image: --->
<!---<cfimage name="scalebar" source="images/scalebars/#url.level#.gif">
<cfset WidthRatio = (ImgWidth/#url.width#) * 100>
<cfset ImageResize(scalebar, "#WidthRatio#%", "")>--->

<!---<cfif url.size neq "map">
	<cfset ImgHeight = Int(ImgWidth / Aspect)>
</cfif>--->

<!--- Reverse order of visible layers so bottom layer is first in list: --->
<cfset VisibleLayers = "">
<cfloop list="#url.vislyrs#" index="i">
	<cfset VisibleLayers = ListPrepend(VisibleLayers,#i#)>
</cfloop>

<!--- Create a blank image. Solves problem that occurred when trying to print just 2 layers. Prepend to visible layers list so it gets placed on bottom: --->
<cfset Blank = ImageNew("", #ImgWidth#, #ImgHeight#, "argb")>
<cfset VisibleLayers = ListPrepend(VisibleLayers, "Blank")>

<cfset ImageSetAntialiasing(Blank)>

<!--- Create cfimages for each visible layer: --->
<cfif Find("fields",VisibleLayers)>
	<cfimage
    	name="fields"
        source="http://mapserver1.kansasgis.org/arcgis/rest/services/oilgas/oilgas_fields_sort_102100/MapServer/export?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true"
    />
</cfif>

<cfif Find("wells",VisibleLayers)>
	<!--- Create layer definition for each well filter type: --->
    <cfset LayerDef = "">
    <cfswitch expression="#url.filter#">
    	<cfcase value="selected_field">
        	<cfset LayerDef = "FIELD_KID=" & #url.currfield#>
        </cfcase>
        <cfcase value="scanned">
        	<cfset LayerDef = URLEncodedFormat("KID IN (SELECT WELL_HEADER_KID FROM ELOG.SCAN_URLS)")>
        </cfcase>
        <cfcase value="paper">
        	<cfset LayerDef = URLEncodedFormat("KID IN (SELECT WELL_HEADER_KID FROM ELOG.LOG_HEADERS)")>
        </cfcase>
        <cfcase value="cuttings">
        	<cfset LayerDef = URLEncodedFormat("KID IN (SELECT WELL_HEADER_KID FROM CUTTINGS.BOXES)")>
        </cfcase>
        <cfcase value="cores">
        	<cfset LayerDef = URLEncodedFormat("KID IN (SELECT WELL_HEADER_KID FROM CORE.CORE_HEADERS)")>
        </cfcase>
        <cfcase value="active_well">
        	<cfset LayerDef = URLEncodedFormat("STATUS NOT LIKE '%&A'")>
        </cfcase>
        <cfcase value="las">
        	<cfset LayerDef = URLEncodedFormat("KID IN (SELECT WELL_HEADER_KID FROM LAS.WELL_HEADERS WHERE PROPRIETARY = 0)")>
        </cfcase>
        <cfcase value="regional">
        	<cfset LayerDef = URLEncodedFormat("KID IN (SELECT KID FROM DOE_CO2.ALL_PROJECT_WELLS_KID)")>
        </cfcase>
        <cfcase value="precamb">
        	<cfset LayerDef = URLEncodedFormat("KID IN (SELECT KID FROM DOE_CO2.PRE_CAMB_WELL_KID)")>
        </cfcase>
        <cfcase value="supertype">
        	<cfset LayerDef = URLEncodedFormat("kid in (select kid from doe_co2.super_type_well_kid)")>
        </cfcase>
        <cfcase value="typewell">
        	<cfset LayerDef = URLEncodedFormat("kid in (select kid from doe_co2.type_well_global_kid)")>
        </cfcase>
    </cfswitch>

	<cfif url.filter eq "none">
        <cfimage
        	name="wells"
            source="http://mapserver1.kansasgis.org/arcgis/rest/services/oilgas/oilgas_102100/MapServer/export?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:#url.wellid#&transparent=true"
    	/>
    <cfelse>
    	<cfimage
        	name="wells"
            source="http://mapserver1.kansasgis.org/arcgis/rest/services/oilgas/oilgas_102100/MapServer/export?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:#url.wellid#&transparent=true&layerDefs=#url.wellid#:#LayerDef#"
    	/>
    </cfif>
</cfif>

<cfif Find("wwc5",VisibleLayers)>
	<cfset wwc5LayerDef = "">
	<cfif #url.filter# eq "remove_monitoring">
    	<cfset wwc5LayerDef = URLEncodedFormat("water_use_code not in (8,10,11,122,240,242,245)")>
    </cfif>

	<cfimage
        name="wwc5"
        source="http://mapserver1.kansasgis.org/arcgis/rest/services/wwc5/wwc5_102100/MapServer/export?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:#url.wellid#&layerDefs=#url.wellid#:#wwc5LayerDef#"
    />
    <!---<cfoutput>
    	http://emerald.kgs.ku.edu/arcgis/rest/services/co2/co2_102100/MapServer/export?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:#url.wellid#&layerDefs=#url.wellid#:#wwc5LayerDef#
    </cfoutput>
    <cfabort>--->
</cfif>

<cfif Find("plss",VisibleLayers)>
	<cfimage
    	name="plss"
        source="http://emerald.kgs.ku.edu/arcgis/rest/services/plss_tsqq_102100/MapServer/export?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true"
    />
</cfif>

<!---<cfif Find("water",VisibleLayers)>
	<cfimage
        name="water"
        source="http://giselle.kgs.ku.edu:80/arcgis/rest/services/water_features/MapServer/export?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true"
    />
</cfif>--->

<cfif Find("drg",VisibleLayers)>
	<cfimage
    	name="drg"
        source="http://imageserver.kansasgis.org/arcgis/rest/services/Statewide/DRG/ImageServer/exportImage?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&imagesr=102100&bboxsr=102100&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:2&transparent=true"
    />
</cfif>

<cfif Find("naip08",VisibleLayers)>
	<cfimage
    	name="naip08"
        source="http://imageserver.kansasgis.org/arcgis/rest/services/Statewide/2008_NAIP_1m_Color/ImageServer/exportImage?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&imagesr=102100&bboxsr=102100&size=#ImgWidth#,#ImgHeight#&format=jpg&f=image&layers=show:1"
    />
</cfif>

<cfif Find("doqq02",VisibleLayers)>
	<cfimage
    	name="doqq02"
        source="http://imageserver.kansasgis.org/arcgis/rest/services/Statewide/2008_NAIP_1m_Color/ImageServer/exportImage?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&imagesr=102100&bboxsr=102100&size=#ImgWidth#,#ImgHeight#&format=jpg&f=image"
    />
</cfif>

<cfif Find("base",VisibleLayers)>
	<cfimage
    	name="base"
        source="http://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/export?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image"
    />
</cfif>

<cfif Find("locallinears",VisibleLayers)>
	<cfimage
    	name="locallinears"
        source="http://emerald.kgs.ku.edu/arcgis/rest/services/co2/remote_sensing_features/MapServer/export?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:0&transparent=true"
    />
</cfif>

<cfif Find("localovals",VisibleLayers)>
	<cfimage
    	name="localovals"
        source="http://emerald.kgs.ku.edu/arcgis/rest/services/co2/remote_sensing_features/MapServer/export?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:1&transparent=true"
    />
</cfif>

<cfif Find("localtonals",VisibleLayers)>
	<cfimage
    	name="localtonals"
        source="http://emerald.kgs.ku.edu/arcgis/rest/services/co2/remote_sensing_features/MapServer/export?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:2&transparent=true"
    />
</cfif>

<cfif Find("mediumkarst",VisibleLayers)>
	<cfimage
    	name="mediumkarst"
        source="http://emerald.kgs.ku.edu/arcgis/rest/services/co2/remote_sensing_features/MapServer/export?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:3&transparent=true"
    />
</cfif>

<cfif Find("mediumlinears",VisibleLayers)>
	<cfimage
    	name="mediumlinears"
        source="http://emerald.kgs.ku.edu/arcgis/rest/services/co2/remote_sensing_features/MapServer/export?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:4&transparent=true"
    />
</cfif>

<cfif Find("regionallinears",VisibleLayers)>
	<cfimage
    	name="regionallinears"
        source="http://emerald.kgs.ku.edu/arcgis/rest/services/co2/remote_sensing_features/MapServer/export?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:5&transparent=true"
    />
</cfif>

<cfif Find("regionalkarst",VisibleLayers)>
	<cfimage
    	name="regionalkarst"
        source="http://emerald.kgs.ku.edu/arcgis/rest/services/co2/remote_sensing_features/MapServer/export?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:6&transparent=true"
    />
</cfif>


<!--- Remove group layer headings from visible layers list: --->
<cfif FindNoCase('locals', VisibleLayers)>
	<cfset VisibleLayers = Replace(VisibleLayers, 'locals', '')>
</cfif>

<cfif FindNoCase('mediums', VisibleLayers)>
	<cfset VisibleLayers = Replace(VisibleLayers, 'mediums', '')>
</cfif>

<cfif FindNoCase('regionals', VisibleLayers)>
	<cfset VisibleLayers = Replace(VisibleLayers, 'regionals', '')>
</cfif>

<cfif Find(',,', VisibleLayers)>
	<cfset VisibleLayers = Replace(VisibleLayers, ',,', ',')>
</cfif>


<cfif ListLen(VisibleLayers) eq 0>
	<!--- Warn user: --->
	Error: At least one layer must be visible to print an image.
</cfif>

<cfif ListLen(VisibleLayers) gt 1>
	<!--- Stack the bottom 2 image: --->
    <!--- ListGetAt function was used because any layer could be the bottom layer. Now code has been changed so "Blank" is always the bottom layer, but left ListGetAt in anyway. --->
	<cfset ImagePaste(#Evaluate(ListGetAt(VisibleLayers,1))#, #Evaluate(ListGetAt(VisibleLayers,2))#, 0, 0)>
    <cfif ListLen(VisibleLayers) gt 2>
    	<!--- Stack additional images. Target image is always the first (bottom) one: --->
    	<cfloop index="i" from="3" to="#ListLen(VisibleLayers)#">
    		<cfset ImagePaste(#Evaluate(ListGetAt(VisibleLayers,1))#, #Evaluate(ListGetAt(VisibleLayers,i))#, 0, 0)>
    	</cfloop>
    </cfif>
</cfif>

<!--- Add KGS and date text to image: --->
<cfset Today = DateFormat(Now(),"mm/dd/yyyy")>

<cfset attr.font = "arial">
<cfset attr.size = 10>
<cfset attr.style = "bold">

<cfset ImageSetDrawingColor(#Evaluate(ListGetAt(VisibleLayers,1))#, "##000000")>
<cfset ImageDrawText(#Evaluate(ListGetAt(VisibleLayers,1))#, "Kansas Geological Survey - #Today#", #ImgWidth# - 200, #ImgHeight# - 5, attr)>

<!--- Add scalebar: --->
<!---<cfif url.size eq "small">
	<cfset ImagePaste(#Evaluate(ListGetAt(VisibleLayers,1))#, #scalebar#, #ImgWidth# - (#ImgWidth# - 5), #ImgHeight# - 21)>
<cfelseif url.size eq "medium">
	<cfset ImagePaste(#Evaluate(ListGetAt(VisibleLayers,1))#, #scalebar#, #ImgWidth# - (#ImgWidth# - 5), #ImgHeight# - 25)>
<cfelse>
	<cfset ImagePaste(#Evaluate(ListGetAt(VisibleLayers,1))#, #scalebar#, #ImgWidth# - (#ImgWidth# - 5), #ImgHeight# - 35)>
</cfif>--->

<!--- Add border: --->
<!--- ImageAddBorder function and <cfimage action="border"> produced Band Count error, so am creating border by drawing a rectangle on the image: --->
<cfset strokeAttr.width= 4>
<cfset ImageSetDrawingStroke(#Evaluate(ListGetAt(VisibleLayers,1))#,strokeAttr)>
<cfset ImageDrawRect(#Evaluate(ListGetAt(VisibleLayers,1))#, 0, 0, #ImgWidth#, #ImgHeight#, "no")>

<!--- Display the final image: --->
<!---<span style="font:normal normal bold 12px Arial">To save the image to your computer, right-click on the image and select <em>Save Picture As</em> or <em>Save Image As</em>.<br />--->
<p>
<!---<cfimage action="writeToBrowser" source="#Evaluate(ListGetAt(VisibleLayers,1))#">--->
<cfset TimeStamp = "#hour(now())##minute(now())##second(now())#">
<cfimage
       action="write"
       source="#Evaluate(ListGetAt(VisibleLayers,1))#"
       overwrite="true"
       destination="\\vmpyrite\d$\webware\Apache\Apache2\htdocs\kgsmaps\oilgas\output\wwc5_#TimeStamp#.png">

<div align="center">
	<table border="0">
    	<tr><td style="font-weight:bold; font-size:24px; text-align:center">#url.pdftitle#</td></tr>
        <tr>
        	<td align="center"><img src="#application.outputDir#/wwc5_#TimeStamp#.png"></td>
        </tr>
        <tr><td align="left" width="#ImgWidth#px">#url.pdfnotes#</td></tr>
    </table>
</div>

</cfoutput>

</body>
</html>
</cfdocument>


<cfoutput>
<script type="text/javascript">
	window.location = '#application.outputDir#/#PdfFile#';
</script>
</cfoutput>

