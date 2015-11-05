<cfquery name="qCounties" datasource="plss">
	select name from global.counties
    order by name asc
</cfquery>

<cfoutput>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="X-UA-Compatible" content="IE=7" />
<meta name="description" content="Interactive map of Kansas water wells." />
<meta name="author" content="Mike Killion">
<meta name="copyright" content="&copy; Kansas Geological Survey">
<meta name="Keywords" content="Kansas, water, wells, wwc5, groundwater" />

<title>Map of #application.title#</title>

<link rel="stylesheet" type="text/css" href="style.css">

<link rel="stylesheet" href="http://js.arcgis.com/3.13/dijit/themes/soria/soria.css">
<link rel="stylesheet" href="http://js.arcgis.com/3.13/esri/css/esri.css">

<script>var dojoConfig = { parseOnLoad: true };</script>
<script src="http://js.arcgis.com/3.13/"></script>

<script type="text/javascript">
	dojo.require("esri.map");
	dojo.require("esri.tasks.identify");
	dojo.require("esri.toolbars.draw");
	dojo.require("esri.tasks.find");
	dojo.require("esri.tasks.geometry");
	dojo.require("esri.tasks.query");
	dojo.require("esri.dijit.Scalebar");
	dojo.require("esri.tasks.PrintTask");
    dojo.require("esri.tasks.PrintParameters");
    dojo.require("esri.tasks.PrintTemplate");
    dojo.require("esri.SpatialReference");
    dojo.require("esri.geometry.Extent");
    dojo.require("esri.layers.agsdynamic");
    dojo.require("esri.layers.agstiled");
    dojo.require("esri.layers.ImageServiceParameters");
    dojo.require("esri.layers.ArcGISImageServiceLayer");
    dojo.require("esri.tasks.FindParameters");
    dojo.require("esri.symbols.SimpleFillSymbol");
    dojo.require("esri.symbols.SimpleLineSymbol");
    dojo.require("esri.symbols.SimpleMarkerSymbol");
    dojo.require("esri.geometry.Polygon");
    dojo.require("esri.geometry.Point");
    dojo.require("esri.graphic");
    dojo.require("esri.tasks.IdentifyParameters");

	dojo.require("dijit.layout.ContentPane");
	dojo.require("dijit.layout.TabContainer");
	dojo.require("dojo.data.ItemFileReadStore");
	dojo.require("dijit.form.FilteringSelect");
	dojo.require("dijit.form.Slider");
	dojo.require("dijit.Dialog");
	dojo.require("dijit.Menu");
	dojo.require("dijit.layout.BorderContainer");

	var map, ovmap, lod;
	var resizeTimer;
	var identify, identifyParams;
	var currField = "";
	var filter, wwc5_filter;
	var label = 'nolabel';
	var classification = 'noclass';
	var visibleWellLyr, visibleWellLyrID;
	var lastLocType, lastLocValue;
	var currentKID;
	var sr, initExtent;

	dojo.addOnLoad(init);

	function init(){
		esri.config.defaults.io.proxyUrl = 'http://maps.kgs.ku.edu/proxy.jsp';

		sr = new esri.SpatialReference({ wkid:102100 });
		initExtent = new esri.geometry.Extent(-11365872, 4434335, -10517316, 4882857, sr);

		map = new esri.Map("map_div", { nav:true, logo:false });

		// Create event listeners:
		dojo.connect(map, 'onLoad', function(){
			dojo.connect(dijit.byId('map_div'), 'resize', function(){
				resizeMap();
			});

			dojo.connect(map, "onClick", executeIdTask);
			//dojo.connect(map, "onExtentChange", setScaleDependentTOC);
			dojo.connect(map, "onExtentChange", changeOvExtent);

			var scalebar = new esri.dijit.Scalebar({
				map: map,
			    scalebarUnit:'english'
          	});

            parseURL();
		});

		// Define layers:
		baseLayer = new esri.layers.ArcGISTiledMapServiceLayer("http://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer");

		countyLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer");
		countyLayer.setVisibleLayers([2]);


		wwc5_NoLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer");
		wwc5_NoLabel_Layer.setVisibleLayers([8]);

		wwc5_DepthYieldLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5_DepthYieldLabel_Layer.setVisibleLayers([9]);

		wwc5_OwnerLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5_OwnerLabel_Layer.setVisibleLayers([10]);

		wwc5_LevelLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5_LevelLabel_Layer.setVisibleLayers([11]);

		wwc5_DepthLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5_DepthLabel_Layer.setVisibleLayers([30]);

		wwc5_YieldLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5_YieldLabel_Layer.setVisibleLayers([31]);



		wwc5Yield_NoLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5Yield_NoLabel_Layer.setVisibleLayers([12]);

		wwc5Yield_DepthYieldLabe_lLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5Yield_DepthYieldLabe_lLayer.setVisibleLayers([13]);

		wwc5Yield_OwnerLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5Yield_OwnerLabel_Layer.setVisibleLayers([14]);

		wwc5Yield_LevelLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5Yield_LevelLabel_Layer.setVisibleLayers([15]);

		wwc5Yield_DepthLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5Yield_DepthLabel_Layer.setVisibleLayers([16]);

		wwc5Yield_YieldLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5Yield_YieldLabel_Layer.setVisibleLayers([17]);



		wwc5Depth_NoLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5Depth_NoLabel_Layer.setVisibleLayers([18]);

		wwc5Depth_DepthYieldLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5Depth_DepthYieldLabel_Layer.setVisibleLayers([19]);

		wwc5Depth_OwnerLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5Depth_OwnerLabel_Layer.setVisibleLayers([20]);

		wwc5Depth_StaticLevelLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5Depth_StaticLevelLabel_Layer.setVisibleLayers([21]);

		wwc5Depth_DepthLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5Depth_DepthLabel_Layer.setVisibleLayers([22]);

		wwc5Depth_YieldLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5Depth_YieldLabel_Layer.setVisibleLayers([23]);



		wwc5Level_NoLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5Level_NoLabel_Layer.setVisibleLayers([24]);

		wwc5Level_DepthYieldLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5Level_DepthYieldLabel_Layer.setVisibleLayers([25]);

		wwc5Level_OwnerLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5Level_OwnerLabel_Layer.setVisibleLayers([26]);

		wwc5Level_StaticLevelLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5Level_StaticLevelLabel_Layer.setVisibleLayers([27]);

		wwc5Level_DepthLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5Level_DepthLabel_Layer.setVisibleLayers([28]);

		wwc5Level_YieldLabel_Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer", { visible:false });
		wwc5Level_YieldLabel_Layer.setVisibleLayers([29]);


		plssLayer = new esri.layers.ArcGISTiledMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/plss/plss/MapServer");


		var imageServiceParameters = new esri.layers.ImageServiceParameters();
        imageServiceParameters.format = "jpg";

		drgLayer = new esri.layers.ArcGISImageServiceLayer("http://imageserver.kansasgis.org/arcgis/rest/services/Statewide/DRG/ImageServer", { visible:false, imageServiceParameters:imageServiceParameters });

		naipLayer = new esri.layers.ArcGISImageServiceLayer("http://services.kansasgis.org/arcgis/rest/services/IMAGERY_STATEWIDE/2014_NAIP_1m_Color/ImageServer", { visible:false, imageServiceParameters:imageServiceParameters });

		doqq02Layer = new esri.layers.ArcGISImageServiceLayer("http://imageserver.kansasgis.org/arcgis/rest/services/Statewide/2002_DOQQ_1m_bw/ImageServer", { visible:false, imageServiceParameters:imageServiceParameters });

		// Add layers (first layer added displays on the bottom):
		map.addLayer(baseLayer);
		map.addLayer(doqq02Layer);
		map.addLayer(naipLayer);
		map.addLayer(drgLayer);
		//map.addLayer(fieldsLayer);
		map.addLayer(countyLayer);
		map.addLayer(plssLayer);

		map.addLayer(wwc5_NoLabel_Layer);
		map.addLayer(wwc5_DepthYieldLabel_Layer);
		map.addLayer(wwc5_OwnerLabel_Layer);
		map.addLayer(wwc5_LevelLabel_Layer);
		map.addLayer(wwc5_DepthLabel_Layer);
		map.addLayer(wwc5_YieldLabel_Layer);

		map.addLayer(wwc5Yield_NoLabel_Layer);
		map.addLayer(wwc5Yield_DepthYieldLabe_lLayer);
		map.addLayer(wwc5Yield_OwnerLabel_Layer);
		map.addLayer(wwc5Yield_LevelLabel_Layer);
		map.addLayer(wwc5Yield_DepthLabel_Layer);
		map.addLayer(wwc5Yield_YieldLabel_Layer);

		map.addLayer(wwc5Depth_NoLabel_Layer);
		map.addLayer(wwc5Depth_DepthYieldLabel_Layer);
		map.addLayer(wwc5Depth_OwnerLabel_Layer);
		map.addLayer(wwc5Depth_StaticLevelLabel_Layer);
		map.addLayer(wwc5Depth_DepthLabel_Layer);
		map.addLayer(wwc5Depth_YieldLabel_Layer);

		map.addLayer(wwc5Level_NoLabel_Layer);
		map.addLayer(wwc5Level_DepthYieldLabel_Layer);
		map.addLayer(wwc5Level_OwnerLabel_Layer);
		map.addLayer(wwc5Level_StaticLevelLabel_Layer);
		map.addLayer(wwc5Level_DepthLabel_Layer);
		map.addLayer(wwc5Level_YieldLabel_Layer);


		visibleWellLyr = wwc5_NoLabel_Layer;
		visibleWellLyrID = 8;


		// Set up overview map and disable its navigation:
		ovMap = new esri.Map("ovmap_div", { slider:false, nav:false, logo:false });
		ovLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/ov_counties/MapServer");
		ovMap.addLayer(ovLayer);

		dojo.connect(ovMap, "onLoad", function() {
  			ovMap.disableMapNavigation();
		});

		map.setExtent(initExtent, true);

		setScaleDependentTOC();
	}


    function parseURL() {
        var queryParams = location.search.substr(1);
        var pairs = queryParams.split("&");
        if (pairs.length > 1) {
            var extType = pairs[0].substring(11);
            var extValue = pairs[1].substring(12);

            var findTask = new esri.tasks.FindTask("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer");
			var findParams = new esri.tasks.FindParameters();
			findParams.returnGeometry = true;
			findParams.contains = false;

            switch (extType) {
                case "well":
                    findParams.layerIds = [0];
					findParams.searchFields = ["kid"];
                    break;
                case "field":
                    findParams.layerIds = [1];
					findParams.searchFields = ["field_kid"];
					fieldsLayer.show();
					dojo.byId('fields').checked = 'checked';
                    break;
                case "county":
                    findParams.layerIds = [2];
          			findParams.searchFields = ["county"];
                    break;
                case "plss":
                    findParams.layerIds = [3];
					findParams.searchFields = ["s_r_t"];
                    break;
                case "wwc5":
                    findParams.layerIds = [8];
					findParams.searchFields = ["input_seq_number"];
                    break;
            }

            lastLocType = extType;
			lastLocValue = extValue;
            findParams.searchText = extValue;
            findTask.execute(findParams,zoomToResults);
        }
    }


	function resizeMap() {
		clearTimeout(resizeTimer);
		resizeTimer = setTimeout(function(){
			map.resize();
			map.reposition();
		}, 500);
	}



	function changeOvExtent(ext) {
		padding = 12000;
		ovMapExtent = new esri.geometry.Extent(ext.xmin - padding, ext.ymin - padding, ext.xmax + padding, ext.ymax + padding, sr);

		ovMap.setExtent(ovMapExtent);

		symbol = new esri.symbol.SimpleFillSymbol(esri.symbol.SimpleFillSymbol.STYLE_SOLID, new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([255,0,0]), 2), new dojo.Color([255,0,0,0.2]));
		boxPts = new Array();
		box = new esri.geometry.Polygon(sr);

		boxNW = new esri.geometry.Point(ext.xmin, ext.ymax);
		boxSW = new esri.geometry.Point(ext.xmin, ext.ymin);
		boxSE = new esri.geometry.Point(ext.xmax, ext.ymin);
		boxNE = new esri.geometry.Point(ext.xmax, ext.ymax);

		boxPts.push(boxNW, boxSW, boxSE, boxNE, boxNW);

		box.addRing(boxPts);

		if (ovMap.graphics) {
			ovMap.graphics.clear();
			ovMap.graphics.add(new esri.Graphic(box, symbol));
		}

		// Give map time to load then toggle scale-dependent layers in table of contents:
		setTimeout(setScaleDependentTOC, 1000);

		// If filter is on, re-apply with new extent:
		if (filter != 'off') {
			filterWells(filter);
		}
	}

	function setScaleDependentTOC() {
		// On extent change, check level of detail and change styling on scale-dependent layer names:
		lod = map.getLevel();

		// PLSS:
		if (lod >= 11) {
			dojo.byId('plss_txt').innerHTML = 'Sec-Twp-Rng';
			dojo.byId('plss_txt').style.color = '##000000';
			dojo.byId('vis_msg').innerHTML = '';
		}
		else {
			dojo.byId('plss_txt').innerHTML = 'Sec-Twp-Rng*';
			dojo.byId('plss_txt').style.color = '##999999';
			dojo.byId('vis_msg').innerHTML = '* Zoom in to view layer';
		}

		// Oil & Gas Wells, WWC5:
		if (lod >= 13) {
			//dojo.byId('ogwells_txt').innerHTML = 'Oil & Gas Wells';
			//dojo.byId('ogwells_txt').style.color = '##000000';
			dojo.byId('vis_msg').innerHTML = '';
			dojo.byId('wwc5_txt').innerHTML = 'WWC5 Water Wells';
			dojo.byId('wwc5_txt').style.color = '##000000';
			dojo.byId('vis_msg').innerHTML = '';
		}
		else {
			//dojo.byId('ogwells_txt').innerHTML = 'Oil & Gas Wells*';
			//dojo.byId('ogwells_txt').style.color = '##999999';
			dojo.byId('vis_msg').innerHTML = '* Zoom in to view layer';
			dojo.byId('wwc5_txt').innerHTML = 'WWC5 Water Wells*';
			dojo.byId('wwc5_txt').style.color = '##999999';
			dojo.byId('vis_msg').innerHTML = '* Zoom in to view layer';
		}

		// Set scalebar image for current map level:
		//dojo.byId('scalebarimage').src='images/scalebars/' + lod + '.gif';

		//dojo.byId('junk').innerHTML = lod;
	}


	function executeIdTask(evt) {
		identify = new esri.tasks.IdentifyTask("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer");
		// Set task parameters:
        identifyParams = new esri.tasks.IdentifyParameters();
        identifyParams.tolerance = 3;
        identifyParams.returnGeometry = true;
		identifyParams.mapExtent = map.extent;
		identifyParams.geometry = evt.mapPoint;
		identifyParams.layerIds = [8];
		//identifyParams.layerOption = "LAYER_OPTION_TOP"

        //Execute task:
		identify.execute(identifyParams, function(fset) {
			addToMap(fset,evt);
		});
	}


	function sortAPI(a, b) {
        var numA = a.feature.attributes["api_numbeR"];
        var numB = b.feature.attributes["api_number"];
        if (numA < numB) { return -1 }
        if (numA > numB) { return 1 }
        return 0;
    }


	function sortOwner(a, b) {
        var A = a.feature.attributes["owner_name"];
        var B = b.feature.attributes["owner_name"];
        if (A < B) { return -1 }
        if (A > B) { return 1 }
        return 0;
    }


	function addToMap(results,evt) {
		featureset = results;

		if (featureset.length > 1) {
			var content = "";
			var selectionType = "";
		}
		else {
			var title = results.length + " features were selected:";
			var content = "Please zoom in further to select a well.";
			var isSelection = false;
		}

		if (results.length == 1) {
			if (featureset[0].layerId == 0 || featureset[0].layerId == 8) {
				showPoint(featureset[0].feature, featureset[0].layerId);
			}
			else {
				//fieldsLayer.show();
				//dojo.byId('fields').checked = 'checked';
				if (dojo.byId('fields').checked) {
					showPoly(featureset[0].feature);
				}

				//showPoly(featureset[0].feature);
			}
		}
		else {
			results.sort(sortAPI);

			for (var i = 0, il = results.length; i < il; i++) {
				var graphic = results[i].feature;

			  	switch (graphic.geometry.type) {
					case "point":
				  		var symbol = new esri.symbol.SimpleMarkerSymbol(esri.symbol.SimpleMarkerSymbol.STYLE_CIRCLE, 20, new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([255,255,0]), 1), new dojo.Color([255,255,0,0.25]));
						break;
					case "polyline":
				  		var symbol = new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_DASH, new dojo.Color([0,255,0]), 1);
				  		break;
					case "polygon":
				  		var symbol = new esri.symbol.SimpleFillSymbol(esri.symbol.SimpleFillSymbol.STYLE_NULL, new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([255,255,0]), 3), new dojo.Color([0,255,0,0.25]));
				 		break;
					case "multipoint":
				  		var symbol = new esri.symbol.SimpleMarkerSymbol(esri.symbol.SimpleMarkerSymbol.STYLE_DIAMOND, 20, new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([0,0,0]), 1), new dojo.Color([0,255,0,0.5]));
				  		break;
			  	}

			  	graphic.setSymbol(symbol);

				switch (featureset[0].layerId) {
					case 0:
						selectionType = "well";
						var title = results.length + " oil or gas wells were selected:";
						content += "<tr><td width='*'>" + results[i].feature.attributes["lease_name"] + " " + results[i].feature.attributes["well_name"] + "</td><td width='15%'>" + results[i].feature.attributes["api_number"] + "</td><td width='10%'>" + results[i].feature.attributes["status"] + "</td><td width='10%' align='center'><A style='text-decoration:underline;color:blue;cursor:pointer' onclick='showPoint(featureset[" + i + "].feature,0);'>display</A></td></tr>";
						break;
					case 1:
						selectionType = "field";
						var title = results.length + " fields were selected:";
						content += "<tr><td>" + results[i].feature.attributes["field_name"] + "</td><td><A style='text-decoration:underline;color:blue;cursor:pointer;' onclick='showPoly(featureset[" + i + "].feature,1);'>display</A></td></tr>";
						break;
					case 8:
						results.sort(sortOwner);

						selectionType = "wwc5";
						var title = results.length + " water wells were selected:";

						var status = "";
						if (results[i].feature.attributes["TYPE_OF_ACTION_CODE"] == 1) {
							status = "Constructed";
						}

						if (results[i].feature.attributes["TYPE_OF_ACTION_CODE"] == 2) {
							status = "Reconstructed";
						}

						if (results[i].feature.attributes["TYPE_OF_ACTION_CODE"] == 3) {
							status = "Plugged";
						}

						var useCodeAtt = results[i].feature.attributes["WATER_USE_CODE"];
						switch (useCodeAtt) {
							case '1':
								useCode = "Domestic";
								break;
							case '2':
								useCode = "Irrigation";
								break;
							case '4':
								useCode = "Industrial";
								break;
							case '5':
								useCode = "Public Water Supply";
								break;
							case '6':
								useCode = "Oil Field Water Supply";
								break;
							case '7':
								useCode = "Lawn and Garden - domestic only";
								break;
							case '8':
								useCode = "Air Conditioning";
								break;
							case '9':
								useCode = "Dewatering";
								break;
							case '10':
								useCode = "Monitoring well/observation/piezometer";
								break;
							case '11':
								useCode = "Injection well/air sparge (AS)/shallow";
								break;
							case '12':
								useCode = "Other";
								break;
							case '107':
								useCode = "Test hole/well";
								break;
							case '116':
								useCode = "Feedlot/Livestock/Windmill";
								break;
							case '122':
								useCode = "Recovery/Soil Vapor Extraction/Soil Vent";
								break;
							case '183':
								useCode = "(unstated)/abandoned";
								break;
							case '189':
								useCode = "Road Construction";
								break;
							case '237':
								useCode = "Pond/Swimming Pool/Recreation";
								break;
							case '240':
								useCode = "Cathodic Protection Borehole";
								break;
							case '242':
								useCode = "Recharge Well";
								break;
							case '245':
								useCode = "Heat Pump (Closed Loop/Disposal), Geothermal";
								break;
							case '260':
								useCode = "Domestic, changed from Irrigation";
								break;
							case '270':
								useCode = "Domestic, changed from Oil Field Water Supply";
								break;
							default:
								useCode = "";
						}

						if (classification == 'noclass') {
							content += "<tr><td width='*'>" + results[i].feature.attributes["OWNER_NAME"] + "</td><td width='25%'>" + useCode + "</td><td width='10%'>" + results[i].feature.attributes["MONITORING_NUMBER"] + "<td width='15%'>" + status + "</td><td width='15%' align='center'><A style='text-decoration:underline;color:blue;cursor:pointer' onclick='showPoint(featureset[" + i + "].feature,8);'>display</A><br/>";
						}
						if (classification == 'yieldclass') {
							content += "<tr><td width='*'>" + results[i].feature.attributes["OWNER_NAME"] + "</td><td width='25%'>" + useCode + "</td><td width='10%'>" + results[i].feature.attributes["MONITORING_NUMBER"] + "<td width='15%'>" + status + "</td><td width='5%'>" + results[i].feature.attributes["ESTIMETED_YIELD"] + "<td width='15%' align='center'><A style='text-decoration:underline;color:blue;cursor:pointer' onclick='showPoint(featureset[" + i + "].feature,8);'>display</A><br/>";
						}
						if (classification == 'depthclass') {
							content += "<tr><td width='*'>" + results[i].feature.attributes["OWNER_NAME"] + "</td><td width='25%'>" + useCode + "</td><td width='10%'>" + results[i].feature.attributes["MONITORING_NUMBER"] + "<td width='15%'>" + status + "</td><td width='5%'>" + results[i].feature.attributes["DEPTH_OF_COMPLETED_WELL"] + "<td width='15%' align='center'><A style='text-decoration:underline;color:blue;cursor:pointer' onclick='showPoint(featureset[" + i + "].feature,8);'>display</A><br/>";
						}
						if (classification == 'levelclass') {
							content += "<tr><td width='*'>" + results[i].feature.attributes["OWNER_NAME"] + "</td><td width='25%'>" + useCode + "</td><td width='10%'>" + results[i].feature.attributes["MONITORING_NUMBER"] + "<td width='15%'>" + status + "</td><td width='5%'>" + results[i].feature.attributes["STATIC_WATER_LEVEL"] + "<td width='15%' align='center'><A style='text-decoration:underline;color:blue;cursor:pointer' onclick='showPoint(featureset[" + i + "].feature,8);'>display</A><br/>";
						}
				}

				/*map.graphics.clear();
				map.graphics.add(graphic);*/
			}

			if (selectionType == "well") {
				content = "<table border='1' cellpadding='3'><tr><th>LEASE/WELL</th><th>API NUMBER</th><th>WELL TYPE</th><th>INFO</th></tr>" + content + "</table><p><input type='button' value='Close' onClick='map.infoWindow.hide();' />";
			}

			if (selectionType == "field") {
				content = "<table border='1' cellpadding='3'<tr><th>FIELD NAME</th><th>INFO</th></tr>" + content + "</table><p><input type='button' value='Close' onClick='map.infoWindow.hide();' />";
			}

			if (selectionType == "wwc5") {
				if (classification == 'noclass') {
					content = "<table border='1' cellpadding='3'><tr><th>OWNER</th><th>WELL USE</th><th>OTHER ID</th><th>STATUS</th><th>INFO</th></tr>" + content + "</table><p><input type='button' value='Close' onClick='map.infoWindow.hide();' />";
				}
				if (classification == 'yieldclass') {
					content = "<table border='1' cellpadding='3'><tr><th>OWNER</th><th>WELL USE</th><th>OTHER ID</th><th>STATUS</th><th>YIELD</th><th>INFO</th></tr>" + content + "</table><p><input type='button' value='Close' onClick='map.infoWindow.hide();' />";
				}
				if (classification == 'depthclass') {
					content = "<table border='1' cellpadding='3'><tr><th>OWNER</th><th>WELL USE</th><th>OTHER ID</th><th>STATUS</th><th>DEPTH</th><th>INFO</th></tr>" + content + "</table><p><input type='button' value='Close' onClick='map.infoWindow.hide();' />";
				}
				if (classification == 'levelclass') {
					content = "<table border='1' cellpadding='3'><tr><th>OWNER</th><th>WELL USE</th><th>OTHER ID</th><th>STATUS</th><th>STATIC LEVEL</th><th>INFO</th></tr>" + content + "</table><p><input type='button' value='Close' onClick='map.infoWindow.hide();' />";
				}
			}

			map.infoWindow.resize(550, 400);
			map.infoWindow.setTitle(title);
			map.infoWindow.setContent(content);
			map.infoWindow.show(evt.screenPoint,map.getInfoWindowAnchor(evt.screenPoint));
		}
	}


	function showPoint(feature, lyrId) {
		map.graphics.clear();
		map.infoWindow.hide();

		// Highlight selected feature:
		if (lyrId == 32)
		{
			var ptSymbol = new esri.symbol.SimpleMarkerSymbol();
			ptSymbol.setStyle(esri.symbol.SimpleMarkerSymbol.STYLE_X);
			ptSymbol.setOutline(new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([255,255,0]), 3));
			ptSymbol.size = 20;
			feature.setSymbol(ptSymbol);
		}
		else
		{
			/*var ptSymbol = new esri.symbol.SimpleMarkerSymbol();
			ptSymbol.setOutline(new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([255,255,0]), 3));
			ptSymbol.size = 20;*/

			var ptSymbol = new esri.symbol.SimpleMarkerSymbol(esri.symbol.SimpleMarkerSymbol.STYLE_CIRCLE, 20, new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([255,255,0],1), 4), new dojo.Color([255,255,0,0.5]));

			feature.setSymbol(ptSymbol);
		}

		map.graphics.add(feature);

		if (lyrId == 0) {
			// oil or gas well.
			var idURL = "retrieve_info.cfm?get=well&kid=" + feature.attributes.KID + "&api=" + feature.attributes.api_number;
		}
		else if (lyrId == 8) {
			// wwc5 well.
			var idURL = "retrieve_info.cfm?get=wwc5&getlatlon=n&seq=" + feature.attributes.INPUT_SEQ_NUMBER;
		}

		if (lyrId != 32)
		{
			// Make an ajax request to retrieve well info (content is formatted in retrieve_info.cfm):
			dojo.xhrGet( {
				url: idURL,
				handleAs: "text",
				load: function(response, ioArgs) {
					dojo.byId('infoTab').innerHTML = response;
					return response;
				},
				/*error: function(err) {
					alert(err);
				},*/
				timeout: 180000
			});
		}

		// Make Info tab active:
		tabContainer = dijit.byId('mainTabContainer');
		tabContainer.selectChild('infoTab');
	}


	function showPoly(feature) {
        map.graphics.clear();
		map.infoWindow.hide();

		// Highlight selected feature:
        var symbol = new esri.symbol.SimpleFillSymbol(esri.symbol.SimpleFillSymbol.STYLE_NULL, new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([255,255,0]), 4), new dojo.Color([255,0,0,0.25]));
		feature.setSymbol(symbol);

		map.graphics.add(feature);

		var kid = feature.attributes.field_kid;

		// Make an ajax request to retrieve field info (content is formatted in retrieve_info.cfm):
		dojo.xhrGet( {
			url: "retrieve_info.cfm?get=field&kid=" + kid,
			handleAs: "text",
			load: function(response, ioArgs) {
				dojo.byId('infoTab').innerHTML = response;
				return response;
			},
			/*error: function(err) {
				alert(err);
			},*/
			timeout: 180000
		});

		// Make Info tab active:
		tabContainer = dijit.byId('mainTabContainer');
		tabContainer.selectChild('infoTab');

		currField = kid;

		if (filter == "selected_field") {
			filterWells('selected_field');
		}
	}


	function createDownloadFile() {
		// Reproject extent to NAD27, then request well records inside new extent:
		//var inCoords = new esri.Graphic();
		//inCoords.setGeometry(map.extent);

		var outSR = new esri.SpatialReference({ wkid: 4267});

		var gsvc = new esri.tasks.GeometryService("http://services.kgs.ku.edu/arcgis2/rest/services/Utilities/Geometry/GeometryServer");
		gsvc.project([ map.extent ], outSR, function(features) {
			//var outCoords = features[0].geometry;
			var xMin = features[0].xmin;
			var xMax = features[0].xmax;
			var yMin = features[0].ymin;
			var yMax = features[0].ymax;

			dojo.byId('loading_div').style.top = "-" + (map.height / 2 + 50) + "px";
			dojo.byId('loading_div').style.left = map.width / 2 + "px";
			dojo.byId('loading_div').style.display = "block";

			dojo.xhrGet( {
				url: 'download_file.cfm?xmin=' + xMin + '&xmax=' + xMax + '&ymin=' + yMin + '&ymax=' + yMax + '&filter=' + filter,
				handleAs: "text",
				load: function(response) {
					dojo.byId('loading_div').style.display = "none";
					dijit.byId('download_results').show();
					dojo.byId('download_msg').innerHTML = response;
				},
				error: function(err) {
					alert(err);
				},
				timeout: 600000
			});
		});
	}


	function checkDownload() {
		lod = map.getLevel();

		if (lod >= 13) { // Prevent user from downloading all wells.
			dijit.byId('download').show();
		}
		else {
			// Show warning dialog box:
			dojo.byId('warning_msg').innerHTML = "Please zoom in to limit the number of wells.";
			dijit.byId('warning_box').show();
		}
	}


	function zoomToResults(results) {
		if (results.length == 0) {
			// Show warning dialog box:
			dojo.byId('warning_msg').innerHTML = "This search did not return any features.<br>Please check your entries and try again.";
			dijit.byId('warning_box').show();
		}

		var feature = results[0].feature;

		switch (feature.geometry.type) {
			case "point":
				// Set extent around well (slightly offset so well isn't behind field label), and draw a highlight circle around it:
				var x = feature.geometry.x;
				var y = feature.geometry.y;

				ext = new esri.geometry.Extent(x - 1200, y - 1200, x + 1000, y + 1000, sr);
				map.setExtent(ext);

				var lyrId = results[0].layerId;
				showPoint(feature,lyrId);
				break;
			case "polygon":
				var ext = feature.geometry.getExtent();

				// Pad extent so entire feature is visible when zoomed to:
				var padding = 1000;
				ext.xmax += padding;
				ext.xmin -= padding;
				ext.ymax += padding;
				ext.ymin -= padding;

				map.setExtent(ext);

				var lyrId = results[0].layerId;
				showPoly(feature,lyrId);
				break;
		}
	}


	function changeMap(layer, chkObj) {
		if (layer == 'wells')
		{
			layer = visibleWellLyr;
		}

		if (chkObj.checked) {
			layer.show();
		}
		else {
			layer.hide();
		}
	}


	function changeOpacity(layers, opa) {
		trans = (10 - opa)/10;
		layers.setOpacity(trans);
	}


	function quickZoom(type, value, button) {
		findTask = new esri.tasks.FindTask("http://services.kgs.ku.edu/arcgis2/rest/services/wwc5/wwc5_general/MapServer");

		findParams = new esri.tasks.FindParameters();
		findParams.returnGeometry = true;
		findParams.contains = false;

		switch (type) {
			case 'county':
				findParams.layerIds = [2];
				findParams.searchFields = ["county"];
				findParams.searchText = value;
				break;

			case 'field':
				findParams.layerIds = [1];

				if (button == 'return') {
					findParams.searchFields = ["field_kid"];
					findParams.searchText = value;
				}
				else {
					findParams.searchFields = ["field_name"];
					findParams.searchText = value;
				}

				fieldsLayer.show();
				dojo.byId('fields').checked = 'checked';
				break;

			case 'well':
				findParams.layerIds = [0];

				if (button == 'return') {
					findParams.searchFields = ["kid"];
					findParams.searchText = value;
				}
				else {
					var apiText = dojo.byId('api_state').value + "-" + dojo.byId('api_county').value + "-" + dojo.byId('api_number').value;

					if (dojo.byId('api_extension').value != "") {
						apiText = apiText + "-" + dojo.byId('api_extension').value;
					}

					findParams.searchFields = ["api_number"];
					findParams.searchText = apiText;
				}
				break;

			case 'plss':
				var plssText;

				if (button == 'return') {
					findParams.layerIds = [3];
					findParams.searchFields = ["s_r_t"];
					findParams.searchText = value;
				}
				else {
					// Format search string - if section is not specified search for township/range only (in different layer):
					if (dojo.byId('rng_dir_e').checked == true) {
						var rngDir = 'E';
					}
					else {
						var rngDir = 'W';
					}

					if (dojo.byId('sec').value != "") {
						plssText = 'S' + dojo.byId('sec').value + '-T' + dojo.byId('twn').value + 'S-R' + dojo.byId('rng').value + rngDir;
						findParams.layerIds = [3];
						findParams.searchFields = ["s_r_t"];
					}
					else {
						plssText = 'T' + dojo.byId('twn').value + 'S-R' + dojo.byId('rng').value + rngDir;
						findParams.layerIds = [4];
						findParams.searchFields = ["t_r"];
					}

					findParams.searchText = plssText;
				}
				break;
			case 'wwc5':
				findParams.layerIds = [8];
				findParams.searchFields = ["input_seq_number"];
				findParams.searchText = value;
				break;
			case 'town':
				findParams.layerIds = [32];
				findParams.searchFields = ["feature_na"];
				findParams.searchText = value;
				break;
		}

		// Hide dialog box:
		dijit.byId('quickzoom').hide();

		// Execute task and zoom to feature:
		findTask.execute(findParams, function(fset) {
		zoomToResults(fset);
		});
	}


	function fullExtent() {
		map.setExtent(initExtent);
	}


	function jumpFocus(nextField,chars,currField) {
		if (dojo.byId(currField).value.length == chars) {
			dojo.byId(nextField).focus();
		}
	}


	function filterWells(method) {
		var layerDef = [];
		var mExt = map.extent;

		/*switch (label)
		{
			case 'none':
				lyrID = 8;
				break;
			case 'depth':
				lyrID = 9;
				break;
			case 'owner':
				lyrID = 10;
				break;
			case 'level':
				lyrID = 11;
				break;
			case 'coloryield':

				break;
			case 'nocolor':

				break;
		}*/

		switch (method) {
			/*case 'off':
				layerDef[visibleWellLyrID] = "";
				visibleWellLyr.setLayerDefinitions(layerDef);
				dojo.byId('filter_on').style.display = "none";
				filter = "off";
				break;*/
			case 'show_monitoring':
				map.graphics.clear();
				layerDef[visibleWellLyrID] = "";
				visibleWellLyr.setLayerDefinitions(layerDef);
				dojo.byId('wwc5_filter_on').style.display = "none";
				filter = "show_monitoring";
				break;
			case 'remove_monitoring':
				map.graphics.clear();
				layerDef[visibleWellLyrID] = "water_use_code not in (8,10,11,122,240,242,245)";
				visibleWellLyr.setLayerDefinitions(layerDef);
				dojo.byId('wwc5_filter_on').style.display = "block";
				filter = "remove_monitoring";
				dojo.byId('wwc5_filter_msg').innerHTML = "Mon./Eng. Wells Excluded";
				break;
		}
	}


	function switchLabelLayers(selLabel)
	{
		visibleWellLyr.hide();

		switch (selLabel)
		{
			case "nolabel":
				if (classification == 'noclass') {
					visibleWellLyr = wwc5_NoLabel_Layer;
					visibleWellLyrID = 8;
				}
				if (classification == 'yieldclass') {
					visibleWellLyr = wwc5Yield_NoLabel_Layer;
					visibleWellLyrID = 12;
				}
				if (classification == 'depthclass') {
					visibleWellLyr = wwc5Depth_NoLabel_Layer;
					visibleWellLyrID = 18;
				}
				if (classification == 'levelclass') {
					visibleWellLyr = wwc5Level_NoLabel_Layer;
					visibleWellLyrID = 24;
				}

				label = 'nolabel';

				dojo.byId('wwc5_labels_on').style.display = 'none';
				dojo.byId('label_msg').innerHTML = '';
				break;
			case "depth":
				if (classification == 'noclass') {
					visibleWellLyr = wwc5_DepthLabel_Layer;
					visibleWellLyrID = 30;
				}
				if (classification == 'yieldclass') {
					visibleWellLyr = wwc5Yield_DepthLabel_Layer;
					visibleWellLyrID = 16;
				}
				if (classification == 'depthclass') {
					visibleWellLyr = wwc5Depth_DepthLabel_Layer;
					visibleWellLyrID = 22;
				}
				if (classification == 'levelclass') {
					visibleWellLyr = wwc5Level_DepthLabel_Layer;
					visibleWellLyrID = 28;
				}

				label = 'depth';

				dojo.byId('wwc5_labels_on').style.display = 'block';
				dojo.byId('label_msg').innerHTML = 'Labels = Completed Well Depth (ft)';
				break;
			case "yield":
				if (classification == 'noclass') {
					visibleWellLyr = wwc5_YieldLabel_Layer;
					visibleWellLyrID = 31;
				}
				if (classification == 'yieldclass') {
					visibleWellLyr = wwc5Yield_YieldLabel_Layer;
					visibleWellLyrID = 17;
				}
				if (classification == 'depthclass') {
					visibleWellLyr = wwc5Depth_YieldLabel_Layer;
					visibleWellLyrID = 23;
				}
				if (classification == 'levelclass') {
					visibleWellLyr = wwc5Level_YieldLabel_Layer;
					visibleWellLyrID = 29;
				}

				label = 'yield';

				dojo.byId('wwc5_labels_on').style.display = 'block';
				dojo.byId('label_msg').innerHTML = 'Labels = Estimated Yield (gpm)';
				break;
			case "depthyield":
				if (classification == 'noclass') {
					visibleWellLyr = wwc5_DepthYieldLabel_Layer;
					visibleWellLyrID = 9;
				}
				if (classification == 'yieldclass') {
					visibleWellLyr = wwc5Yield_DepthYieldLabe_lLayer;
					visibleWellLyrID = 13;
				}
				if (classification == 'depthclass') {
					visibleWellLyr = wwc5Depth_DepthYieldLabel_Layer;
					visibleWellLyrID = 19;
				}
				if (classification == 'levelclass') {
					visibleWellLyr = wwc5Level_DepthYieldLabel_Layer;
					visibleWellLyrID = 25;
				}

				label = 'depthyield';

				dojo.byId('wwc5_labels_on').style.display = 'block';
				dojo.byId('label_msg').innerHTML = 'Labels = Depth (ft) / Yield (gpm)';
				break;
			case "owner":
				if (classification == 'noclass') {
					visibleWellLyr = wwc5_OwnerLabel_Layer;
					visibleWellLyrID = 10;
				}
				if (classification == 'yieldclass') {
					visibleWellLyr = wwc5Yield_OwnerLabel_Layer;
					visibleWellLyrID = 14;
				}
				if (classification == 'depthclass') {
					visibleWellLyr = wwc5Depth_OwnerLabel_Layer;
					visibleWellLyrID = 20;
				}
				if (classification == 'levelclass') {
					visibleWellLyr = wwc5Level_OwnerLabel_Layer;
					visibleWellLyrID = 26;
				}

				label = 'owner';

				dojo.byId('wwc5_labels_on').style.display = 'block';
				dojo.byId('label_msg').innerHTML = 'Labels = Owner';
				break;
			case "level":
				if (classification == 'noclass') {
					visibleWellLyr = wwc5_LevelLabel_Layer;
					visibleWellLyrID = 11;
				}
				if (classification == 'yieldclass') {
					visibleWellLyr = wwc5Yield_LevelLabel_Layer;
					visibleWellLyrID = 15;
				}
				if (classification == 'depthclass') {
					visibleWellLyr = wwc5Depth_StaticLevelLabel_Layer;
					visibleWellLyrID = 21;
				}
				if (classification == 'levelclass') {
					visibleWellLyr = wwc5Level_StaticLevelLabel_Layer;
					visibleWellLyrID = 27;
				}

				label = 'level';

				dojo.byId('wwc5_labels_on').style.display = 'block';
				dojo.byId('label_msg').innerHTML = 'Labels = Static Water Level (ft)';
				break;
		}

		filterWells(filter);
		visibleWellLyr.show();
	}


	function switchClassificationLayers(selClassification)
	{
		visibleWellLyr.hide();

		switch (selClassification)
		{
			case "noclass":
				if (label == 'nolabel') {
					visibleWellLyr = wwc5_NoLabel_Layer;
					visibleWellLyrID = 8;
				}
				if (label == 'depthyield') {
					visibleWellLyr = wwc5_DepthYieldLabel_Layer;
					visibleWellLyrID = 9;
				}
				if (label == 'owner') {
					visibleWellLyr = wwc5_OwnerLabel_Layer;
					visibleWellLyrID = 10;
				}
				if (label == 'level') {
					visibleWellLyr = wwc5_LevelLabel_Layer;
					visibleWellLyrID = 11;
				}
				if (label == 'depth') {
					visibleWellLyr = wwc5_DepthLabel_Layer;
					visibleWellLyrID = 30;
				}
				if (label == 'yield') {
					visibleWellLyr = wwc5_YieldLabel_Layer;
					visibleWellLyrID = 31;
				}

				classification = 'noclass';

				dojo.byId('classification_on').style.display = 'none';
				dojo.byId('classlabel').innerHTML = '';
				dojo.byId('artesian_sym').innerHTML = '';
				dojo.byId('legendimage').innerHTML = '';
				dojo.byId('novalue_sym').innerHTML = '';
				dojo.byId('wwc5_sym').innerHTML = '<img src="images/wwc5_sym.jpg" />';
				break;
			case "yieldclass":
				if (label == 'nolabel') {
					visibleWellLyr = wwc5Yield_NoLabel_Layer;
					visibleWellLyrID = 12;
				}
				if (label == 'depthyield') {
					visibleWellLyr = wwc5Yield_DepthYieldLabel_Layer;
					visibleWellLyrID = 13;
				}
				if (label == 'owner') {
					visibleWellLyr = wwc5Yield_OwnerLabel_Layer;
					visibleWellLyrID = 14;
				}
				if (label == 'level') {
					visibleWellLyr = wwc5Yield_LevelLabel_Layer;
					visibleWellLyrID = 15;
				}
				if (label == 'depth') {
					visibleWellLyr = wwc5Yield_DepthLabel_Layer;
					visibleWellLyrID = 16;
				}
				if (label == 'yield') {
					visibleWellLyr = wwc5Yield_YieldLabel_Layer;
					visibleWellLyrID = 17;
				}

				classification = 'yieldclass';

				dojo.byId('classification_on').style.display = 'block';
				dojo.byId('classification_msg').innerHTML = 'Classification = Estimated Yield (gpm)';
				dojo.byId('classlabel').innerHTML = '<b>Estimated Yield (gpm)</b>';
				dojo.byId('artesian_sym').innerHTML = '';
				dojo.byId('legendimage').innerHTML = '<img src="images/yield_legend.jpg" />';
				dojo.byId('novalue_sym').innerHTML = '<img src="images/novalue.jpg" />';
				dojo.byId('wwc5_sym').innerHTML = '';

				tabContainer = dijit.byId('mainTabContainer');
				tabContainer.selectChild('legendTab');
				break;
			case "depthclass":
				if (label == 'nolabel') {
					visibleWellLyr = wwc5Depth_NoLabel_Layer;
					visibleWellLyrID = 18;
				}
				if (label == 'depthyield') {
					visibleWellLyr = wwc5Depth_DepthYieldLabel_Layer;
					visibleWellLyrID = 19;
				}
				if (label == 'owner') {
					visibleWellLyr = wwc5Depth_OwnerLabel_Layer;
					visibleWellLyrID = 20;
				}
				if (label == 'level') {
					visibleWellLyr = wwc5Depth_StaticLevelLabel_Layer;
					visibleWellLyrID = 21;
				}
				if (label == 'depth') {
					visibleWellLyr = wwc5Depth_DepthLabel_Layer;
					visibleWellLyrID = 22;
				}
				if (label == 'yield') {
					visibleWellLyr = wwc5Depth_YieldLabel_Layer;
					visibleWellLyrID = 23;
				}

				classification = 'depthclass';

				dojo.byId('classification_on').style.display = 'block';
				dojo.byId('classification_msg').innerHTML = 'Classification = Completed Well Depth (ft)';
				dojo.byId('classlabel').innerHTML = '<b>Completed Well Depth (ft)</b>';
				dojo.byId('artesian_sym').innerHTML = '';
				dojo.byId('legendimage').innerHTML = '<img src="images/depth_legend.jpg" />';
				dojo.byId('novalue_sym').innerHTML = '<img src="images/novalue.jpg" />';
				dojo.byId('wwc5_sym').innerHTML = '';

				tabContainer = dijit.byId('mainTabContainer');
				tabContainer.selectChild('legendTab');
				break;
			case "levelclass":
				if (label == 'nolabel') {
					visibleWellLyr = wwc5Level_NoLabel_Layer;
					visibleWellLyrID = 24;
				}
				if (label == 'depthyield') {
					visibleWellLyr = wwc5Level_DepthYieldLabel_Layer;
					visibleWellLyrID = 25;
				}
				if (label == 'owner') {
					visibleWellLyr = wwc5Level_OwnerLabel_Layer;
					visibleWellLyrID = 26;
				}
				if (label == 'level') {
					visibleWellLyr = wwc5Level_StaticLevelLabel_Layer;
					visibleWellLyrID = 27;
				}
				if (label == 'depth') {
					visibleWellLyr = wwc5Level_DepthLabel_Layer;
					visibleWellLyrID = 28;
				}
				if (label == 'yield') {
					visibleWellLyr = wwc5Level_YieldLabel_Layer;
					visibleWellLyrID = 29;
				}

				classification = 'levelclass';

				dojo.byId('classification_on').style.display = 'block';
				dojo.byId('classification_msg').innerHTML = 'Classification = Static Water Level (ft)';
				dojo.byId('classlabel').innerHTML = '<b>Static Water Level (ft)</b>';
				dojo.byId('artesian_sym').innerHTML = '<img src="images/artesian.jpg" />';
				dojo.byId('legendimage').innerHTML = '<img src="images/level_legend.jpg" />';
				dojo.byId('novalue_sym').innerHTML = '<img src="images/novalue.jpg" />';
				dojo.byId('wwc5_sym').innerHTML = '';

				tabContainer = dijit.byId('mainTabContainer');
				tabContainer.selectChild('legendTab');
				break;
		}

		filterWells(filter);
		visibleWellLyr.show();
	}

	function printPDF() {
		var printUrl = 'http://services.kgs.ku.edu/arcgis2/rest/services/Utilities/PrintingTools/GPServer/Export%20Web%20Map%20Task';
		var printTask = new esri.tasks.PrintTask(printUrl);
        var printParams = new esri.tasks.PrintParameters();
        var template = new esri.tasks.PrintTemplate();
		var w, h;
		var printOutSr = new esri.SpatialReference({ wkid:26914 }); //utm14

		title = dojo.byId("pdftitle2").value;

		if (dojo.byId('portrait2').checked) {
			var layout = "Letter ANSI A Portrait";
		} else {
			var layout = "Letter ANSI A Landscape";
		}

		dijit.byId('printdialog2').hide();
		dojo.byId('printing_div').style.display = "block";

		if (dojo.byId('maponly').checked) {
			layout = 'MAP_ONLY';
			format = 'JPG';

			if (dojo.byId('portrait2').checked) {
				w = 600;
				h = 960;
			} else {
				w = 960;
				h = 600;
			}

			template.exportOptions = {
  				width: w,
  				height: h,
  				dpi: 96
			};
		} else {
			format = 'PDF';
		}

        if (lod >= 16) {
            var units = "Feet";
        } else {
            var units = "Miles";
        }

        template.layout = layout;
		template.format = format;
        template.preserveScale = true;
		template.showAttribution = false;
		template.layoutOptions = {
			scalebarUnit: units,
			titleText: title,
			authorText: "Kansas Geological Survey",
			copyrightText: "http://maps.kgs.ku.edu/wwc5",
			legendLayers: []
		};

		printParams.map = map;
		printParams.outSpatialReference = printOutSr;
        printParams.template = template;

        printTask.execute(printParams, printResult, printError);
	}

	function printResult(result){
		dojo.byId('printing_div').style.display = "none";
		window.open(result.url);
    }

    function printError(result){
        console.log(result);
    }

    function submitComments(l, t, c, o) {
        dojo.xhrGet( {
            url: "suggestions.cfm?layers="+l+"&tools="+t+"&comments="+c+"&occ="+o
        });

        updateCommentCount();

        dijit.byId('suggestionBox').hide();
    }

    function updateCommentCount() {
        dojo.xhrGet( {
            url: "commentcount.cfm",
            handleAs: "text",
            load: function(response, ioArgs) {
                dojo.byId('commentcount').innerHTML = response;
                return response;
            }
        });
    }

</script>

<script type="text/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-1277453-14']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>

</head>

<body class="soria">
<!-- Topmost container: -->
<div id="mainWindow" dojotype="dijit.layout.BorderContainer" design="headline" gutters="false" style="width:100%; height:100%;">

	<!--Header: -->
	<div id="header" dojotype="dijit.layout.ContentPane" region="top" >
		<div style="padding:5px; font:normal normal bold 18px Arial; color:##FFFF66;">
        	#application.title#
        	<span id="kgs" style="position:fixed; right:55px; padding-top:2px;"><a style="font-weight:normal; font-size:12px; color:yellow; text-decoration:none;" href="http://www.kgs.ku.edu">Kansas Geological Survey</a></span>
        </div>
        <div id="toolbar">
        	<span class="tool_link" onclick="fullExtent();">Statewide View</span> &nbsp;|&nbsp;
            <span class="tool_link" onclick="dijit.byId('quickzoom').show();">Zoom to Location</span>&nbsp;|&nbsp;
            <span class="tool_link" id="filter">Filter Wells</span>&nbsp;|&nbsp;
            <span class="tool_link" id="label">Label Wells</span>&nbsp;|&nbsp;
            <span class="tool_link" id="color">Classify Wells</span>&nbsp;|&nbsp;
            <span class="tool_link" onclick="checkDownload();">Download Wells</span>&nbsp;|&nbsp;
            <span class="tool_link" onclick="dijit.byId('printdialog2').show();">Print to PDF</span>&nbsp;|&nbsp;
            <span class="tool_link" onclick="map.graphics.clear();">Clear Highlight</span>&nbsp;|&nbsp;
            <a class="tool_link" href="help.cfm" target="_blank">Help</a>
       	</div>
	</div>

	<!-- Center container: -->
	<div id="map_div" dojotype="dijit.layout.ContentPane" region="center" style="background-color:white;"></div>

	<!-- Right container: -->
	<div dojotype="dijit.layout.ContentPane" region="right" id="sidebar" style="width:260px;border-left: medium solid ##0013AA;">
		<div id="mainTabContainer" class="mainTab" dojoType="dijit.layout.TabContainer" >
            <div id="layersTab" dojoType="dijit.layout.ContentPane" title="Layers">
            	<!--- Adding new layers: the checkbox id name is passed on the print.cfm in the visible layers list, and must have a corresponding <cfimage> block under the same name (Find function). --->
                <table>
                <tr><td>Layer</td><td>Transparency</td></tr>
                <!---<tr>
                    <td><input type="checkbox" id="wells" onClick="changeMap('wells',this);" checked><span id="ogwells_txt"></span></td>
                    <td></td>
                </tr>--->
                <tr>
                    <td nowrap="nowrap"><input type="checkbox" id="wwc5" onClick="changeMap('wells',this);" checked><span id="wwc5_txt"></span></td>
                    <td>
                    	<div id="horizontalSlider_wwc5" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                            intermediateChanges="true" style="width:75px"
                            onChange="dojo.byId('horizontalSlider_wwc5').value = arguments[0];changeOpacity(visibleWellLyr,dojo.byId('horizontalSlider_wwc5').value);">
                        </div>
                    </td>
                </tr>
                <tr>
                    <td><input type="checkbox" id="plss" onClick="changeMap(plssLayer,this);" checked><span id="plss_txt"></span></td>
                    <td>
                        <div id="horizontalSlider_plss" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                            intermediateChanges="true" style="width:75px"
                            onChange="dojo.byId('horizontalSlider_plss').value = arguments[0];changeOpacity(plssLayer,dojo.byId('horizontalSlider_plss').value);">
                        </div>
                    </td>
                </tr>
                <!---<tr>
                    <td><input type="checkbox" id="fields" onClick="changeMap(fieldsLayer,this);">Oil & Gas Fields</td>
                    <td>
                        <div id="horizontalSlider_fields" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                            intermediateChanges="true" style="width:75px"
                            onChange="dojo.byId('horizontalSlider_fields').value = arguments[0];changeOpacity(fieldsLayer,dojo.byId('horizontalSlider_fields').value);">
                        </div>
                    </td>
                </tr>--->
                <tr>
                    <td><input type="checkbox" id="drg" onClick="changeMap(drgLayer,this);">Topographic Map</td>
                    <td>
                        <div id="horizontalSlider_drg" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                            intermediateChanges="true" style="width:75px"
                            onChange="dojo.byId('horizontalSlider_drg').value = arguments[0];changeOpacity(drgLayer,dojo.byId('horizontalSlider_drg').value);">
                        </div>
                    </td>
                </tr>
                <tr>
                    <td><input type="checkbox" id="naip12" onClick="changeMap(naipLayer,this);">2014 Aerials</td>
                    <td>
                        <div id="horizontalSlider_naip12" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                            intermediateChanges="true" style="width:75px"
                            onChange="dojo.byId('horizontalSlider_naip12').value = arguments[0];changeOpacity(naipLayer,dojo.byId('horizontalSlider_naip12').value);">
                        </div>
                    </td>
                </tr>
                <tr>
                    <td><input type="checkbox" id="doqq02" onClick="changeMap(doqq02Layer,this);">2002 B&W Aerials</td>
                    <td>
                        <div id="horizontalSlider_doqq02" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                            intermediateChanges="true" style="width:75px"
                            onChange="dojo.byId('horizontalSlider_doqq02').value = arguments[0];changeOpacity(doqq02Layer,dojo.byId('horizontalSlider_doqq02').value);">
                        </div>
                    </td>
                </tr>
                <tr>
                    <td><input type="checkbox" id="base" onClick="changeMap(baseLayer,this);" checked>Base map</td>
                    <td>
                        <div id="horizontalSlider_base" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                            intermediateChanges="true" style="width:75px"
                            onChange="dojo.byId('horizontalSlider_base').value = arguments[0];changeOpacity(baseLayer,dojo.byId('horizontalSlider_base').value);">
                        </div>
                    </td>
                </tr>
                <tr><td class="note" id="vis_msg" colspan="2">* Layer not visible at all scales</td></tr>
                </table>


                <div id="ovmap_div"></div>
            </div>

            <div class="tab" id="infoTab" dojoType="dijit.layout.ContentPane" title="Info">Click on a well to display information.</div>

            <div class="tab" id="legendTab" dojoType="dijit.layout.ContentPane" title="Legend">
            	<p>
            	<span id="wwc5_sym"><img src="images/wwc5_sym.jpg"></span>
                <span id="classlabel"></span><br />
                <span id="artesian_sym"></span><br />
                <span id="legendimage"></span><br />
                <span id="novalue_sym"></span><br />
            </div>

			<div class="tab" id="linksTab" dojoType="dijit.layout.ContentPane" title="Links">
            	<p>
				<ul>
					<li><a href="http://www.kgs.ku.edu" target="_blank">KGS Home Page</a></li>
					<p>
					<li><a href="http://www.kgs.ku.edu/Magellan/WaterWell/index.html" target="_blank">WWC5 Database Home Page</a></li>
					<p>
					<li><a href="http://www.kgs.ku.edu/Magellan/WaterLevels/index.html" target="_blank">WIZARD Database Home Page</a></li>
					<p>
					<li><a href="http://hercules.kgs.ku.edu/geohydro/wimas/index.cfm" target="_blank">WIMAS Database Home Page</a></li>
					<p>
					<li><a href="http://www.kgs.ku.edu/Hydro/hydroIndex.html" target="_blank">KGS Water Resources Home Page</a></li>
					<p>
					<li><a href="http://www.kdheks.gov/waterwell/index.html" target="_blank">KDHE Water Well Program Home Page</a></li>
                    <p>
                    <li><a href="http://permanent.access.gpo.gov/websites/ergusgsgov/erg.usgs.gov/isb/pubs/booklets/symbols/index.html" target="_blank">Topographic Map Symbols</a></li>
                    <p>
                    <li><a href="http://maps.kgs.ku.edu/oilgas" target="_blank">KGS Oil and Gas Mapper</a></li>
				</ul>
            </div>
        </div>
	</div>

	<!--- Footer: --->
	<div id="bottom" dojotype="dijit.layout.ContentPane" region="bottom" style="height:23px;">
		<div id="footer">
			<div preload="true" dojoType="dijit.layout.ContentPane" id="classification_on" style="background-color:##FF3366; display:none; text-align:left; width:33%; position:fixed; left:0px">
				<span id="classification_msg" style="color:##000000;font:normal normal bold 12px Arial;padding-left:3px"></span>
				<button class="label" onclick="switchClassificationLayers('noclass');" style="text-align:center;z-index:26">Remove Classification</button>
			</div>
            <div preload="true" dojoType="dijit.layout.ContentPane" id="wwc5_labels_on" style="background-color:##00FFCC; display:none; text-align:left; width:33%; position:fixed; left:33.5%">
				<span id="label_msg" style="color:##000000;font:normal normal bold 12px Arial;padding-left:3px"></span>
				<button class="label" onclick="switchLabelLayers('nolabel');" style="text-align:center;z-index:26">Remove Labels</button>
			</div>
            <div preload="true" dojoType="dijit.layout.ContentPane" id="wwc5_filter_on" style="background-color:##33CCFF; display:none; text-align:left; width:33%; position:fixed; right:0px">
				<span id="wwc5_filter_msg" style="color:##000000;font:normal normal bold 12px Arial;padding-left:3px">WWC5</span>
				<button class="label" onclick="filterWells('show_monitoring');" style="text-align:center;z-index:26">Show All Water Wells</button>
			</div>
            <div id="junk"></div>
		</div>
	</div>
</div>

<!--- Suggestion Box: --->
<!--<div id="sb" style="position:absolute;top:77px;left:75px;background-color:yellow;border:3px solid red;text-align:center;padding:2px;font:normal normal normal 12px arial">
    <b>All comments received to date: <span id="commentcount">0</span></b><br>
    <button onClick="dijit.byId('suggestionBox').show();" style="margin:4px;">Suggestions</button>&nbsp;&nbsp;&nbsp;<button onClick="dojo.byId('sb').style.display='none';" style="margin:4px;">Close</button><br>
    What improvements could be made in the<br>
    next version of the water well mapper?
</div>-->

<!--- Quick zoom dialog box: --->
<div class="dialog" dojoType="dijit.Dialog" id="quickzoom" title="Zoom to Location" style="text-align:center;font:normal normal bold 14px arial">
    <table>
    <tr>
        <td class="label">Township: </td>
        <td>
            <select id="twn">
                <option value=""></option>
                <cfloop index="i" from="1" to="35">
                    <option value="#i#">#i#</option>
                </cfloop>
            </select>
        </td>
        <td class="label" style="text-align:left">South</td>
    </tr>
    <tr>
        <td class="label">Range: </td>
        <td>
            <select id="rng">
                <option value=""></option>
                <cfloop index="j" from="1" to="43">
                    <option value="#j#">#j#</option>
                </cfloop>
            </select>
        </td>
        <td class="label">East:<input type="radio" name="rng_dir" id="rng_dir_e" value="E" /> or West:<input type="radio" name="rng_dir" id="rng_dir_w" value="W" checked="checked" /></td>
    </tr>
    <tr>
        <td class="label">Section: </td>
        <td>
            <select id="sec">
                <option value=""></option>
                <cfloop index="k" from="1" to="36">
                    <option value="#k#">#k#</option>
                </cfloop>
            </select>
        </td>
    </tr>
    <tr><td></td><td><button class="label" onclick="quickZoom('plss');">Go</button></td></tr>
    </table>
    <div id="or"><img src="images/or.jpg" /></div>
	<div class="input">
		<span class="label">KGS ID Number:</span>
        <input type="text" size="5" id="seqnum" />
        <button class="label" onclick="quickZoom('wwc5',dojo.byId('seqnum').value);">Go</button>
	</div>


    <div id="or"><img src="images/or.jpg" /></div>
    <div class="input">
    	<table>
        	<tr>
            	<td class="label">Town:</td>
            	<td>
        			<div dojoType="dojo.data.ItemFileReadStore" jsId="townStore" url="towns.txt"></div>
        			<input id="town" dojoType="dijit.form.FilteringSelect" store="townStore" searchAttr="name" autocomplete="false" hasDownArrow="false"/>
        			<button class="label" onclick="quickZoom('town',dojo.byId('town').value);">Go</button>
                </td>
            </tr>
        </table>
    </div>

    <div id="or"><img src="images/or.jpg" /></div>
    <div class="input">
        <span class="label">County:</span>
        <select id="county">
            <option value="">-- Select --</option>
            <cfloop query="qCounties">
                <option value="#name#">#name#</option>
            </cfloop>
        </select>
        <button class="label" onclick="quickZoom('county',dojo.byId('county').value);">Go</button>
    </div>
	<div id="or"><img src="images/or.jpg" /></div>
    <div class="input">
    	<span class="label">Return to original location </span>
    	<button class="label" onclick="quickZoom(lastLocType, lastLocValue, 'return');">Go</button>
    </div>
</div>

<!--- Filter menu: --->
<div dojoType="dijit.Menu" id="filterMenu" contextMenuForWindow="false" style="display: none;" targetNodeIds="filter" leftClicktoOpen="true">
    <div dojoType="dijit.MenuItem" onclick="filterWells('show_monitoring');">Show All Wells</div>
    <div dojoType="dijit.MenuItem" onclick="filterWells('remove_monitoring');">Remove Monitoring/Engineering Wells</div>
</div>

<!--- Label menu: --->
<div dojoType="dijit.Menu" id="labelMenu" contextMenuForWindow="false" style="display: none;" targetNodeIds="label" leftClicktoOpen="true">
	<div dojoType="dijit.MenuItem" onClick="switchLabelLayers('nolabel');">No Labels</div>
	<div dojoType="dijit.MenuSeparator"></div>
	<div dojoType="dijit.MenuItem" onclick="switchLabelLayers('depth');">Depth (ft)</div>
    <div dojoType="dijit.MenuItem" onclick="switchLabelLayers('yield');">Yield (gpm)</div>
    <div dojoType="dijit.MenuItem" onclick="switchLabelLayers('depthyield');">Depth / Yield</div>
	<div dojoType="dijit.MenuItem" onClick="switchLabelLayers('owner');">Owner</div>
    <div dojoType="dijit.MenuItem" onclick="switchLabelLayers('level');">Static Water Level (ft)</div>
</div>

<!--- Classification menu: --->
<div dojoType="dijit.Menu" id="colorMenu" contextMenuForWindow="false" style="display: none;" targetNodeIds="color" leftClicktoOpen="true">
	<div dojoType="dijit.MenuItem"><b>Color-Code Wells Based On:</b></div>
    <div dojoType="dijit.MenuItem" onClick="switchClassificationLayers('noclass');">No Classification</div>
	<div dojoType="dijit.MenuSeparator"></div>
	<div dojoType="dijit.MenuItem" onClick="switchClassificationLayers('yieldclass');">Yield (gpm)</div>
    <div dojoType="dijit.MenuItem" onclick="switchClassificationLayers('depthclass');">Completed Well Depth (ft)</div>
    <div dojoType="dijit.MenuItem" onclick="switchClassificationLayers('levelclass');">Static Water Level (ft)</div>
</div>

<!--- Warning message dialog box: --->
<div class="dialog" dojoType="dijit.Dialog" id="warning_box" title="Error" style="text-align:center;font:normal normal bold 14px arial">
	<div id="warning_msg" style="font:normal normal normal 12px Arial"></div><p>
	<button class="label" onclick="dijit.byId('warning_box').hide()">OK</button>
</div>

<!--- Download diaglog box: --->
<div class="dialog" dojoType="dijit.Dialog" id="download" title="Download WWC5 Well Data" style="text-align:center;font:normal normal bold 14px arial">
    <div style="font:normal normal normal 12px arial; text-align:left">
    	<ul>
        	<li>Creates comma-delimited text files with well and lithologic log information for wells visible in the current map extent.</li>
            <li>If a filter is in effect, the download will also be filtered.</li>
        </ul>
        <ul>
        	<li>This dialog box will close and another will open with links to your files (may take a few minutes depending on number of wells).</li>
            <li><b>You may continue to use the map while the progress indicator is displayed.</b></li>
        </ul>
        <ul>
       		<li>
        		Other options to download well data can be accessed through the <a href="http://www.kgs.ku.edu/Magellan/WaterWell/index.html" target="_blank">WWC5 database</a>.
        	</li>
        </ul>
    </div>
    <button class="label" style="text-align:center" onclick="createDownloadFile();dijit.byId('download').hide();">Download</button>
    <button class="label" style="text-align:center" onclick="dijit.byId('download').hide();">Cancel</button>
</div>

<div class="dialog" dojoType="dijit.Dialog" id="download_results" title="Download File is Ready" style="text-align:center;font:normal normal bold 14px arial">
	<span id="download_msg"></span>
</div>

<!--- Print dialog box 2 (for new print task): --->
<div dojoType="dijit.Dialog" id="printdialog2" title="Print to PDF" style="text-align:center;font:normal normal bold 14px arial">
    <div style="font:normal normal normal 12px arial;">
    	<table align="center">
        	<tr><td style="font-weight:bold" align="right">Title (optional):</td><td align="left"><input type="text" id="pdftitle2" size="50" /></td></tr>
            <tr><td style="font-weight:bold" align="right">Orientation:</td><td align="left"><input type="radio" id="landscape2" name="pdforientation2" value="landscape" checked="checked" />Landscape&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" id="portrait2" name="pdforientation2" value="portrait" />Portrait</td></tr>
            <tr><td style="font-weight:bold" align="right">Print map only (as jpg):</td><td align="left"><input type="checkbox" id="maponly"></td></tr>
        </table>
    </div>
    <p>
    <button class="label" onclick="printPDF();" style="text-align:center">Print</button>
    <button class="label" style="text-align:center" onclick="dijit.byId('printdialog2').hide();">Cancel</button>
    <p>
    <span style="font:normal normal normal 12px arial">Note: Pop-up blockers must be turned off or set to allow pop-ups from 'maps.kgs.ku.edu'</span>
</div>

<!-- Suggestion Box: -->
<div dojoType="dijit.Dialog" id="suggestionBox" title="Suggestions" style="text-align:center;font:normal normal bold 14px arial">
    <div style="text-align:left;font:normal normal normal 14px arial">
        <p>
            The KGS is beginning a long-term redesign of its web mappers to make them more accessible on mobile devices. <br>
            New features are planned as part of that redesign and we'd like your input. Please enter brief descriptions of any <br>
            new tools, features, and map layers you'd like to see in the next version.
        </p>
        <p>
            <p>
                Map Layers:<br>
                <input type="text" id="layers" name="layers" size="125">
            </p>
            <p>
                Tools and Features:<br>
                <input type="text" id="tools" name="tools" size="125">
            </p>
            <p>
                General Comments:<br>
                <textarea id="comments" name="comments" rows="4" cols="90"></textarea>
            </p>
            <p>
                Please tell us about your occupation (industry, government, general public, etc.):<br>
                <input type="text" id="occupation" name="tools" size="125">
            </p>
            <p>
            <button onclick="submitComments(dojo.byId('layers').value, dojo.byId('tools').value, dojo.byId('comments').value, dojo.byId('occupation').value);">Submit</button> - Thank you!
            </p>
        </p>
    </div>
</div>

<!--- Download loading indicator: --->
<div id="loading_div" style="display:none; position:relative; z-index:1000;">
    <img id="loading" src="images/loading.gif" />
</div>

<!--- Printing indicator: --->
<div id="printing_div" style="display:none; position:absolute; top:50px; left:600px; z-index:1000;">
    <img id="loading" src="images/ajax-loader.gif" />
</div>

</body>
</html>
</cfoutput>

