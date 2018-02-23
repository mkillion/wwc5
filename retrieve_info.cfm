<cfsetting requestTimeOut = "3600" showDebugOutput = "yes">

<cfprocessingdirective suppresswhitespace="yes">
<cfif url.get eq "well">
	<!--- Get well info: --->
    <cfquery name="qWell_Headers" datasource="plss">
        select
        	api_number,
            lease_name,
            well_name,
            operator_name,
            field_name,
            township,
            township_direction,
            range,
            range_direction,
            section,
            subdivision_4_smallest,
            subdivision_3,
            subdivision_2,
            subdivision_1_largest,
            operator_kid,
            feet_north_from_reference,
            feet_east_from_reference,
            reference_corner,
            spot,
            longitude,
            latitude,
            county_code,
            permit_date,
            spud_date,
            completion_date,
            plug_date,
            status,
            well_class,
            rotary_total_depth,
            elevation,
            elevation_kb,
            elevation_df,
            elevation_gl,
            producing_formation,
            initial_production_oil,
            initial_production_water,
            initial_production_gas
        from
        	qualified.well_headers
        where
        	kid = #url.kid#
    </cfquery>

    <!--- Get current operator: --->
    <cfif qWell_Headers.operator_kid neq "">
        <cfquery name="qOperators" datasource="plss">
            select operator_name
            from nomenclature.operators
            where kid = #qWell_Headers.operator_kid#
        </cfquery>
        <cfset CurrOperator = qOperators.operator_name>
    <cfelse>
        <cfset CurrOperator = "">
    </cfif>

    <!--- Lookup county name: --->
    <cfquery name="qCounty" datasource="plss">
        select name
        from global.counties
        where code = #qWell_Headers.county_code#
    </cfquery>
    <cfset CountyName = qCounty.name>

    <!--- Format location: --->
    <cfoutput query="qWell_Headers">
        <cfset Location = "T" & #township# & #township_direction# & " R" & #range# & #range_direction# & " Sec. " & #section#>
        <cfset Quarters = #spot# & " " & #subdivision_4_smallest# & " " & #subdivision_3# & " " & #subdivision_2# & " " & #subdivision_1_largest#>

        <cfif #feet_north_from_reference# lt 0>
            <cfset NS_Dir = "South">
        <cfelse>
            <cfset NS_Dir = "North">
        </cfif>

        <cfif #feet_east_from_reference# lt 0>
            <cfset EW_Dir = "West">
        <cfelse>
            <cfset EW_Dir = "East">
        </cfif>

        <cfif #feet_north_from_reference# neq "" and #feet_east_from_reference# neq "">
            <cfset Footage_1 = Abs(#feet_north_from_reference#) & " " & NS_Dir & ", " & Abs(#feet_east_from_reference#) & " " & EW_Dir>
            <cfset Footage_2 = " from " & #reference_corner# & " corner">
        <cfelse>
            <cfset Footage_1 = "">
            <cfset Footage_2 = "">
        </cfif>
    </cfoutput>

    <!--- Format elevation value: --->
    <cfif qWell_Headers.elevation_kb neq "">
        <cfset Elev = qWell_Headers.elevation_kb & " KB">
    <cfelseif qWell_Headers.elevation_df neq "">
        <cfset Elev = qWell_Headers.elevation_df & " DF">
    <cfelseif qWell_Headers.elevation_gl neq "">
        <cfset Elev = qWell_Headers.elevation_gl & " GL">
    <cfelseif qWell_Headers.elevation neq "">
        <cfset Elev = qWell_Headers.elevation & " est.">
    <cfelse>
        <cfset Elev = "">
    </cfif>

    <!--- Check for LAS file: --->
    <cfquery name="qCheckLAS" datasource="plss">
    	select
        	kid,
            rownum
        from
        	las.well_headers
        where
    		well_header_kid = #url.kid#
            and
            proprietary = 0
    </cfquery>

    <!--- Format response text: --->
    <cfoutput query="qWell_Headers">
        <span class='layer_name'>&nbsp;<strong>OIL or GAS WELL</strong></span><br />
        <table cellspacing='0' width='100%'>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>API:</td><td style='font:normal normal normal 11px Arial''>#api_number#</td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>Lease:</td><td style='font:normal normal normal 11px Arial''>#lease_name#</td></tr>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>Well:</td><td style='font:normal normal normal 11px Arial''>#well_name#</td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>Original Operator:</td><td style='font:normal normal normal 11px Arial''>#operator_name#</td></tr>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>Current Operator:</td><td style='font:normal normal normal 11px Arial''>#CurrOperator#</td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>Field:</td><td style='font:normal normal normal 11px Arial''>#field_name#</td></tr>
            <tr style='background-color:##D9E6FB'>
                <td style='font:normal normal normal 11px Arial;color:##CC0000'>Location:</td>
                <td style='font:normal normal normal 11px Arial''>#Location#<br />#Quarters#<br />#Footage_1#<br />#Footage_2#</td>
            </tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>Longitude <span class="note">(NAD27)</span>:</td><td style='font:normal normal normal 11px Arial''>#longitude#</td></tr>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>Latitude <span class="note">(NAD27)</span>:</td><td style='font:normal normal normal 11px Arial''>#latitude#</td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>County:</td><td style='font:normal normal normal 11px Arial''>#CountyName#</td></tr>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>Permit Date:</td><td style='font:normal normal normal 11px Arial''>#DateFormat(permit_date,'mmm-dd-yyyy')#</td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>Spud Date:</td><td style='font:normal normal normal 11px Arial''>#DateFormat(spud_date,'mmm-dd-yyyy')#</td></tr>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>Completion Date:</td><td style='font:normal normal normal 11px Arial''>#DateFormat(completion_date,'mmm-dd-yyyy')#</td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>Plugging Date:</td><td style='font:normal normal normal 11px Arial''>#DateFormat(plug_date,'mmm-dd-yyyy')#</td></tr>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>Well Type:</td><td style='font:normal normal normal 11px Arial''>#status#</td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>Status:</td><td style='font:normal normal normal 11px Arial''>#well_class#</td></tr>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>Total Depth:</td><td style='font:normal normal normal 11px Arial''>#rotary_total_depth#</td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>Elevation:</td><td style='font:normal normal normal 11px Arial''>#Elev#</td></tr>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>Producing Formation:</td><td style='font:normal normal normal 11px Arial''>#producing_formation#</td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>IP Oil (bbl):</td><td style='font:normal normal normal 11px Arial''>#initial_production_oil#</td></tr>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>IP Water (bbl):</td><td style='font:normal normal normal 11px Arial''>#initial_production_water#</td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>IP Gas (mcf):</td><td style='font:normal normal normal 11px Arial''>#initial_production_gas#</td></tr>
            </table>
            <p>
            <b>Links:</b>
            <ul>
                <li><a href="http://chasm.kgs.ku.edu/apex/qualified.well_page.DisplayWell?f_kid=#url.kid#" target="_blank">Full KGS Database Entry</a></li>
            </ul>

			<cfif qCheckLAS.recordcount gt 0>
                <cfif qCheckLAS.recordcount eq 1>
                    <b>#qCheckLAS.recordcount# LAS file found:</b>
                <cfelse>
                    <b>#qCheckLAS.recordcount# LAS files found:</b>
                </cfif>
            </cfif>

            <ul>
                <cfloop query="qCheckLAS">
                	<li><a href="http://www.kgs.ku.edu/Gemini/LAS.html?sAPI=#url.api#&sKID=#kid#" target="_blank">View LAS File #rownum#</a></li>
                </cfloop>
            </ul>
    </cfoutput>
</cfif>


<cfif url.get eq "field">
	<!--- Get field info from fields and reservoir tables: --->
    <cfquery name="qFields" datasource="plss">
        select
        	field_name,
            status,
            decode(type_of_field,
            	'OIL', 'Oil',
            	'GAS', 'Gas',
                'O&G', 'Oil and Gas') as type_of_field,
            produces_gas,
            produces_oil
        from
        	nomenclature.fields
        where
        	kid = #url.kid#
    </cfquery>

    <cfquery name="qFormations" datasource="plss">
        select formation_name
        from nomenclature.fields_reservoirs
        where field_kid = #url.kid#
    </cfquery>

    <!--- Lookup counties field occupies: --->
    <!---<cfquery name="qCounties" datasource="plss">
        select name
        from global.counties
        where code in
            (select county_code
            from nomenclature.fields_counties
            where field_kid = #url.kid#)
    </cfquery>--->

    <!--- Format response text: --->
    <cfoutput query="qFields">
        <span class='layer_name'>&nbsp;<strong>FIELD</strong></span><br />
        <table cellspacing='0' width='100%'>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>Name:</td><td style='font:normal normal normal 11px Arial''>#field_name#</td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>Status:</td><td style='font:normal normal normal 11px Arial''>#status#</td></tr>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>Type of Field:</td><td style='font:normal normal normal 11px Arial''>#type_of_field#</td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>Produces Oil:</td><td style='font:normal normal normal 11px Arial''>#produces_oil#</td></tr>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>Produces Gas:</td><td style='font:normal normal normal 11px Arial''>#produces_gas#</td></tr>
            <tr>
                <td style='font:normal normal normal 11px Arial;color:##CC0000'>Producing Formations:</td>
                <td style='font:normal normal normal 11px Arial''>
                    <cfloop query="qFormations">
                        #formation_name#<br />
                    </cfloop>
                </td>
            </tr>
            <!---<tr>
                <td style='font:normal normal normal 11px Arial;color:##CC0000'>Counties:</td>
                <td style='font:normal normal normal 11px Arial''>
                    <cfloop query="qCounties">
                        #name#<br />
                    </cfloop>
                </td>
            </tr>--->
        </table>
        <p>
        <b>Links:</b>
        <ul>
            <li><a href="http://chasm.kgs.ku.edu/apex/oil.ogf4.IDProdQuery?FieldNumber=#url.kid#" target="_blank">Full KGS Database Entry</a></li>
        </ul>

    </cfoutput>
</cfif>

<cfif url.get eq "wwc5">
	<cfif url.getlatlon eq "y">
    	<cfquery name="qLatLon" datasource="plss">
        	select
            	latitude,
                longitude
            from
            	wwc5.wwc5_99_wells
            where
            	input_seq_number = #url.seq#
        </cfquery>

        <cfoutput query="qLatLon">
        	#latitude#,#longitude#
        </cfoutput>
    <cfelse>
    <cfquery name="qWWC5" datasource="plss">
        select
            w.input_seq_number,
            g.name as county,
            w.owner_name as owner_name,
            w.depth_of_completed_well,
            w.static_water_level,
            w.estimeted_yield,
            w.township,
            w.township_direction,
            w.range,
            w.range_direction,
            w.section,
            w.quarter_call_1_largest,
            w.quarter_call_2,
            w.quarter_call_3,
            initcap(s.typewell) as status,
            w.elevation_of_well,
            initcap(u.use_desc) as use,
            w.completion_date,
            w.contractor_name as w_contractor,
            c.contractor_name as c_contractor,
            w.dwr_appropriation_number,
            w.monitoring_number
        from
            wwc5.wwc5_99_wells w,
            global.counties g,
            wwc5.well_status_type_rf7 s,
            gis_webinfo.wwc5_wells u,
            wwc5.wwc5_contractors c
        where
            w.input_seq_number = #url.seq#
            and
            u.input_seq_number = #url.seq#
            and
            w.county_code = g.code(+)
            and
            w.type_of_action_code = s.wltwel(+)
            and
            w.contractors_license_number = c.contractors_license(+)
    </cfquery>

    <!--- Format location and contractor name: --->
    <cfoutput query="qWWC5">
        <cfset Location = "T" & #township# & #township_direction# & " R" & #range# & #range_direction# & " Sec. " & #section#>
        <cfset Quarters = #quarter_call_3# & " " & #quarter_call_2# & " " & #quarter_call_1_largest#>

        <cfset Contractor = "">
        <cfif c_contractor neq "">
        	<cfset Contractor = c_contractor>
        <cfelseif w_contractor neq "">
        	<cfset Contractor = w_contractor>
        </cfif>
    </cfoutput>

    <!--- Format response text: --->
    <cfoutput query="qWWC5">
        <span class='layer_name'>&nbsp;<strong>WATER WELL (WWC5)</strong></span><br />
        <table cellspacing='0' width='100%'>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>County:</td><td style='font:normal normal normal 11px Arial''>#county#</td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>Section:</td><td style='font:normal normal normal 11px Arial''>#Location#</td></tr>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>Quarter Section:</td><td style='font:normal normal normal 11px Arial''>#Quarters#</td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>Owner:</td><td style='font:normal normal normal 11px Arial''>#owner_name#</td></tr>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>Status:</td><td style='font:normal normal normal 11px Arial''>#status#</td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>Depth:</td><td style='font:normal normal normal 11px Arial''>#depth_of_completed_well# <cfif #depth_of_completed_well# neq "">ft</cfif></td></tr>
           	<tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>Elevation:</td><td style='font:normal normal normal 11px Arial''>#elevation_of_well# <cfif #elevation_of_well# neq "">ft</cfif></td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>Static Water Level:</td><td style='font:normal normal normal 11px Arial''>#static_water_level# <cfif #static_water_level# neq "">ft</cfif></td></tr>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>Estimated Yield:</td><td style='font:normal normal normal 11px Arial''>#estimeted_yield# <cfif #estimeted_yield# neq "">gpm</cfif></td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>Well Use:</td><td style='font:normal normal normal 11px Arial''>#use#</td></tr>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>Other ID:</td><td style='font:normal normal normal 11px Arial'>#monitoring_number#</td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>Completion Date:</td><td style='font:normal normal normal 11px Arial''>#DateFormat(completion_date,'mmm-dd-yyyy')#</td></tr>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>Driller:</td><td style='font:normal normal normal 11px Arial''>#Contractor#</td></tr>
            <tr><td style='font:normal normal normal 11px Arial;color:##CC0000'>DWR Application Number:</td><td style='font:normal normal normal 11px Arial'>#dwr_appropriation_number#</td></tr>
            <tr style='background-color:##D9E6FB'><td style='font:normal normal normal 11px Arial;color:##CC0000'>KGS Record Number:</td><td style='font:normal normal normal 11px Arial'>#input_seq_number#</td></tr>
        </table>
        <p>
        <b>Links:</b>
        <ul>
            <li><a href="http://chasm.kgs.ku.edu/apex/wwc5.wwc5d2.well_details?well_id=#url.seq#" target="_blank">Full KGS Database Entry</a></li>
        </ul>

    </cfoutput>
    </cfif>
</cfif>

<cfif url.get eq "welluse">
	<cfquery name="qWellUse" datasource="plss">
    	select
        	initcap(use_description) as use
        from
        	wwc5.welluse_type
        where
        	water_use_code = #url.usecode#
    </cfquery>

    <cfoutput query="qWellUse">
    	#use#
    </cfoutput>
</cfif>
</cfprocessingdirective>
