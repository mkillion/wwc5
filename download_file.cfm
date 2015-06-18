
<cfsetting requestTimeOut = "600" showDebugOutput = "yes">

<!--- WWC5 Wells: --->
<cfquery name="qWWC5" datasource="gis_webinfo">
	select
    	w.input_seq_number,
        g.name as county,
        w.township,
        w.township_direction,
        w.range,
        w.range_direction,
        w.section,
        w.quarter_call_3||' '||w.quarter_call_2||' '||w.quarter_call_1_largest as spot,
        w.nad27_longitude,
        w.nad27_latitude,
        w.gps_longitude,
        w.owner_name,
        u.use_description as use,
        w.completion_date,
        s.typewell as status,
        w.monitoring_number as otherid,
        w.dwr_appropriation_number,
        trim(w.location_directions) as directions,
        w.depth_of_completed_well,
        w.elevation_of_well,
        w.static_water_level,
        w.estimeted_yield,
        w.contractor_name as w_contractor,
        c.contractor_name as c_contractor
    from
    	#application.wellsTable# w,
        global.counties g,
        wwc5.well_status_type_rf7 s,
        wwc5.welluse_type u,
        wwc5.contractors c
    where
    	w.county_code = g.code
        and
        w.water_use_code = u.water_use_code(+)
        and
        w.type_of_action_code = s.wltwel(+)
        and
        w.contractors_license_number = c.contractors_license(+)
    	and
        w.nad27_longitude > #url.xmin# and w.nad27_longitude < #url.xmax# and w.nad27_latitude > #url.ymin# and w.nad27_latitude < #url.ymax#
        <cfswitch expression="#url.filter#">
            <cfcase value="remove_monitoring">
                and w.water_use_code not in (8,10,11,122,240,242,245)
            </cfcase>
        </cfswitch>
</cfquery>

<cfset TimeStamp = "#hour(now())##minute(now())##second(now())#">
<cfset WWC5FileName = "WWC5_#TimeStamp#.txt">
<cfset WWC5OutputFile = "\\vmpyrite\d$\webware\Apache\Apache2\htdocs\kgsmaps\oilgas\output\#WWC5FileName#">

<cfset Columns = "WELL_ID,COUNTY,TONWSHIP,TWN_DIR,RANGE,RANGE_DIR,SECTION,SPOT,LONGITUDE,LATITUDE,LONG_LAT_TYPE,OWNER,WELL_USE,COMPLE_DATE,STATUS,OTHER_ID,DWR_NUMBER,DIRECTIONS,WELL_DEPTH,ELEV,STATIC_DEPTH,EST_YIELD,DRILLER">
<cffile action="write" file="#WWC5OutputFile#" output="#Columns#" addnewline="yes">


<cfloop query="qWWC5">
	<!--- Format contractor: --->
	<cfset Contractor = "">
    <cfif c_contractor neq "">
        <cfset Contractor = c_contractor>
    <cfelseif w_contractor neq "">
        <cfset Contractor = w_contractor>
    </cfif>
    
    <!--- Format long_lat_type: --->
    <cfset LongLatType = "">
    <cfif gps_longitude eq "">
    	<cfset LongLatType = "From PLSS">
    <cfelse>
    	<cfset LongLatType = "GPS">
    </cfif>
    
    <!--- Write record: --->
    <cfset Record = '"#input_seq_number#","#county#","#township#","#township_direction#","#range#","#range_direction#","#section#","#spot#","#nad27_longitude#","#nad27_latitude#","#LongLatType#","#owner_name#","#use#","#DateFormat(completion_date,'mmm-dd-yyyy')#","#status#","#otherid#","#dwr_appropriation_number#","#directions#","#depth_of_completed_well#","#elevation_of_well#","#static_water_level#","#estimeted_yield#","#Contractor#"'>
	<cffile action="append" file="#WWC5OutputFile#" output="#Record#" addnewline="yes">
</cfloop>


<!--- Create temporary table of KIDs for use in subsequent queries: --->
<cfquery name="qIDView" datasource="gis_webinfo">
    create table wwc5#TimeStamp#(input_seq_number number)
</cfquery>

<cfloop query="qWWC5">
	<cfquery name="qInsertID" datasource="gis_webinfo">
		insert into wwc5#TimeStamp#
    	values(#input_seq_number#)
    </cfquery>
</cfloop>


<!--- Lithologic log file: --->
<cfquery name="qLitho" datasource="gis_webinfo">
	select
    	l.wlid as well_id,
      	w.nad27_longitude as longitude,
      	w.nad27_latitude as latitude,
    	l.wlfeet as feet,
    	trim(r.wllogt) as log
    from
    	wwc5.wwc5_99_reflog r,
      	wwc5.wwc5_99_logfile l,
      	<!---wwc5_wells_fc w--->
        #application.wellsTable# w
    where
    	l.wllog = r.wllog
      	and
      	l.wlid = w.input_seq_number
      	and
    	l.wlid in (select input_seq_number from wwc5#TimeStamp#)
	order by
    	well_id, feet
</cfquery>

<cfif qLitho.recordcount gt 0>
	<cfset LithoFileName = "wwc5log_#TimeStamp#.txt">
	<cfset LithoOutputFile = "\\vmpyrite\d$\webware\Apache\Apache2\htdocs\kgsmaps\oilgas\output\#LithoFileName#">

	<cfset Columns = "WELL_ID,LONGITUDE,LATITUDE,FEET,LOG">
	<cffile action="write" file="#LithoOutputFile#" output="#Columns#" addnewline="yes">
    
    <cfloop query="qLitho">
    	<cfset Record = '"#well_id#","#longitude#","#latitude#","#feet#","#log#"'>
        <cffile action="append" file="#LithoOutputFile#" output="#Record#" addnewline="yes">
    </cfloop>
</cfif>


<!--- Create disclaimer file: --->
<cfset DisclaimerFile = "READ_ME_#TimeStamp#.txt">
<cfset DisclaimerOutputFile = "\\vmpyrite\d$\webware\Apache\Apache2\htdocs\kgsmaps\oilgas\output\#DisclaimerFile#">

<cfset Disclaimer = "Lithologic log data was not entered by the Kansas Geological Survey nor does the Survey check its accuracy.">

<cffile action="write" file="#DisclaimerOutputFile#" output="#Disclaimer#" addnewline="no">


<!--- Create zip file: --->
<cfzip action="zip"
	source="\\vmpyrite\d$\webware\Apache\Apache2\htdocs\kgsmaps\oilgas\output"
    file="\\vmpyrite\d$\webware\Apache\Apache2\htdocs\kgsmaps\oilgas\output\wwc5_#TimeStamp#.zip"
    filter="*#TimeStamp#*"
    overwrite="yes" >
    
    
<!--- Delete temporary KID table: --->
<cfquery name="qDeleteTmp" datasource="gis_webinfo">
	drop table wwc5#TimeStamp#
</cfquery>


<!--- xhr response text: --->
<cfoutput>
<cfif FileExists(#WWC5OutputFile#)>
    <div style="font:normal normal normal 12px arial; text-align:left">
    	<ul>
        	<li>Right-click on the link below and select <em>Save Target As</em> or <em>Save Link As</em> to save the file.</li>
            <li>See the 'Download Wells' section of the Help page for information on opening these files in Excel.</li>
        </ul>
        <ul>
            <li><a href="#application.outputDir#/wwc5_#TimeStamp#.zip">wwc5_#TimeStamp#.zip</a></li>
        </ul>
    </div>
<cfelse>
	<span style="font:normal normal normal 12px arial">An error has occurred - file was not created.</span>
</cfif>
</cfoutput>