
<cfif url.col eq "depth">
	<cfquery name="qStats" datasource="plss">
    	select
        	round(min(depth_of_completed_well)) as min,
            round(max(depth_of_completed_well)) as max,
            round(avg(depth_of_completed_well)) as mean,
            round(stddev(depth_of_completed_well)) as stddev
        from
        	wwc5.wwc5_99_wells
        where
        	longitude > #url.xmin# and longitude < #url.xmax# and latitude > #url.ymin# and latitude < #url.ymax#
    </cfquery>
    
    <cfoutput>
    	#qStats.min#,#qStats.max#,#qStats.mean#,#qStats.stddev#
    </cfoutput>
</cfif>

<cfif url.col eq "statlevel">
	<cfquery name="qStats" datasource="plss">
    	select
        	round(min(static_water_level)) as min,
            round(max(static_water_level)) as max,
            round(avg(static_water_level)) as mean,
            round(stddev(static_water_level)) as stddev
        from
        	wwc5.wwc5_99_wells
        where
        	longitude > #url.xmin# and longitude < #url.xmax# and latitude > #url.ymin# and latitude < #url.ymax#
    </cfquery>
    
    <cfoutput>
    	#qStats.min#,#qStats.max#,#qStats.mean#,#qStats.stddev#
    </cfoutput>
</cfif>
