<cfquery name="qComments" datasource="gis_webinfo">
    select count(*) as the_count from wwc5_mapper_comments
</cfquery>

<cfoutput>#qComments.the_count#</cfoutput>