/**********************************************************************************************************************************************************************************
AUTHOR: Mark Shapiro
SCRIPT: Adding Census District boundaries to aggregated pipeline
START DATE: 9/5/2019
COMPLETION DATE: 
Sources: 
*************************************************************************************************************************************************************************************/


drop table if exists aggregated_cd;
drop table if exists ungeocoded_PROJECTs_cd;
drop table if exists aggregated_cd_longform;
drop table if exists aggregated_cd_PROJECT_level;

select
	*
into
	aggregated_cd
from
(
	with aggregated_boundaries_cd as
(
	select
		a.*,
		b.the_geom as cd_geom,
		b.borocd,
		st_distance(a.the_geom::geography,b.the_geom::geography) as cd_distance
	from
		capitalplanning.known_projects_db_20190712_v5_cp_assumptions a
	left join
		capitalplanning.ny_community_districts b
	on 
	case
		/*Treating large developments as polygons*/
		when (st_area(a.the_geom::geography)>10000 or total_units > 500) and a.source in('EDC Projected Projects','DCP Applications','DCP Planner-Added PROJECTs')	then
			st_intersects(a.the_geom,b.the_geom) and 
			(
				CAST(ST_Area(ST_Intersection(a.the_geom,b.the_geom))/ST_Area(a.the_geom) AS DECIMAL) >= .1 or
				CAST(ST_Area(ST_Intersection(a.the_geom,b.the_geom))/ST_Area(b.the_geom) AS DECIMAL) >=.5
			)

		/*Treating subdivisions in SI across many lots as polygons*/
		when a.project_id in(select project_id from zap_projects_many_bbls) and a.project_name_address like '%SD %'								then
			st_intersects(a.the_geom,b.the_geom) and 
			(
				CAST(ST_Area(ST_Intersection(a.the_geom,b.the_geom))/ST_Area(a.the_geom) AS DECIMAL) >= .1 or
				CAST(ST_Area(ST_Intersection(a.the_geom,b.the_geom))/ST_Area(b.the_geom) AS DECIMAL) >=.5
			)

		/*Treating Resilient Housing Sandy Recovery PROJECTs, across many DISTINCT lots as polygons. These are three PROJECTs*/ 
		when a.PROJECT_name_address like '%Resilient Housing%' and a.source in('DCP Applications','DCP Planner-Added PROJECTs')									then
			st_INTERSECTs(a.the_geom,b.the_geom) and 
			(
				CAST(ST_Area(ST_Intersection(a.the_geom,b.the_geom))/ST_Area(a.the_geom) AS DECIMAL) >= .1 or
				CAST(ST_Area(ST_Intersection(a.the_geom,b.the_geom))/ST_Area(b.the_geom) AS DECIMAL) >=.5
			)
		/*Treating NCP and NIHOP projects, which are usually noncontiguous clusters, as polygons*/ 
		when (a.PROJECT_name_address like '%NIHOP%' or a.PROJECT_name_address like '%NCP%' )and a.source in('DCP Applications','DCP Planner-Added PROJECTs')	then
			st_INTERSECTs(a.the_geom,b.the_geom) and 
			(
				CAST(ST_Area(ST_Intersection(a.the_geom,b.the_geom))/ST_Area(a.the_geom) AS DECIMAL) >= .1 or
				CAST(ST_Area(ST_Intersection(a.the_geom,b.the_geom))/ST_Area(b.the_geom) AS DECIMAL) >=.5
			)
	/*Treating neighborhood study projected sites, and future neighborhood studies as polygons*/
		when a.source in('Future Neighborhood Studies','Neighborhood Study Projected Development Sites') 														then
			st_INTERSECTs(a.the_geom,b.the_geom) and 
			(
				CAST(ST_Area(ST_Intersection(a.the_geom,b.the_geom))/ST_Area(a.the_geom) AS DECIMAL) >= .1 or
				CAST(ST_Area(ST_Intersection(a.the_geom,b.the_geom))/ST_Area(b.the_geom) AS DECIMAL) >=.5
			)
		/*Treating other polygons as points, using their centroid*/
		when st_area(a.the_geom) > 0 																															then
			 st_INTERSECTs(st_centroid(a.the_geom),b.the_geom) 

		/*Treating points as points*/
		else
			st_intersects(a.the_geom,b.the_geom) 																								end
																									/*Only matching if at least 10% of the polygon
		                           																	is in the boundary. Otherwise, the polygon will be
		                           																	apportioned to its other boundaries only*/
),

	multi_geocoded_projects as
(
	select
		source,
		project_id
	from
		aggregated_boundaries_cd
	group by
		source,
		project_id
	having
		count(*)>1
),

	aggregated_boundaries_cd_2 as
(
	SELECT
		a.*,
		case when 	concat(a.source,a.project_id) in(select concat(source,project_id) from multi_geocoded_projects) and st_area(a.the_geom) > 0	then 
					CAST(ST_Area(ST_Intersection(a.the_geom,a.cd_geom))/ST_Area(a.the_geom) AS DECIMAL) 										else
					1 end																														as proportion_in_cd
	from
		aggregated_boundaries_cd a
),

	aggregated_boundaries_cd_3 as
(
	SELECT
		source,
		project_id,
		sum(proportion_in_cd) as total_proportion
	from
		aggregated_boundaries_cd_2
	group by
		source,
		project_id
),

	aggregated_boundaries_cd_4 as
(
	SELECT
		a.*,
		case when b.total_proportion is not null then cast(a.proportion_in_cd/b.total_proportion as decimal)
			 else 1 			  end as proportion_in_cd_1,
		case when b.total_proportion is not null then round(a.counted_units * cast(a.proportion_in_cd/b.total_proportion as decimal)) 
			 else a.counted_units end as counted_units_1
	from
		aggregated_boundaries_cd_2 a
	left join
		aggregated_boundaries_cd_3 b
	on
		a.project_id = b.project_id and a.source = b.source
)

	select * from aggregated_boundaries_cd_4

) as _1;

select
	*
into
	ungeocoded_projects_cd
from
(
	with ungeocoded_projects_cd as
(
	select
		a.*,
		coalesce(a.borocd,b.borocd) as borocd_1,
		coalesce(
					a.cd_distance,
					st_distance(
								b.the_geom::geography,
								case
									when (st_area(a.the_geom::geography)>10000 or total_units > 500) and a.source in('DCP Applications','DCP Planner-Added Projects') 	then a.the_geom::geography
									when st_area(a.the_geom) > 0 																										then st_centroid(a.the_geom)::geography
									else a.the_geom::geography 																											end
								)
				) as cd_distance1
	from
		aggregated_cd a 
	left join
		capitalplanning.ny_community_districts b
	on 
		a.cd_distance is null and
		case
			when (st_area(a.the_geom::geography)>10000 or total_units > 500) and a.source in('DCP Applications','DCP Planner-Added Projects') 		then
				st_dwithin(a.the_geom::geography,b.the_geom::geography,500)
			when st_area(a.the_geom) > 0 																											then
				st_dwithin(st_centroid(a.the_geom)::geography,b.the_geom::geography,500)
			else
				st_dwithin(a.the_geom::geography,b.the_geom::geography,500)																			end
)
	select * from ungeocoded_projects_cd
) as _2;


select
	*
into
	aggregated_cd_longform
from
(
	with	min_distances as
(
	select
		project_id,
		min(cd_distance1) as min_distance
	from
		ungeocoded_projects_cd
	group by 
		project_id
),

	all_projects_cd as
(
	select
		a.*
	from
		ungeocoded_projects_cd a 
	inner join
		min_distances b
	on
		a.project_id = b.project_id and
		a.cd_distance1=b.min_distance
)

	select 
		a.*, 
		b.borocd_1 as cd, 
		b.proportion_in_cd_1 as proportion_in_cd,
		round(a.counted_units * b.proportion_in_cd_1) as counted_units_in_cd 
	from 
		known_projects_db_20190712_v5_cp_assumptions a 
	left join 
		all_projects_cd b 
	on 
		a.source = b.source and 
		a.project_id = b.project_id 
	order by 
		source asc,
		project_id asc,
		project_name_address asc,
		status asc,
		b.borocd_1 asc
) as _3
;

select
	*
into
	aggregated_cd_project_level
from
(
	SELECT
		the_geom,
		the_geom_webmercator,
		source,
		project_id,
		project_name_address,
		dob_job_type,
		status,
		borough,
		total_units,
		deduplicated_units,
		counted_units,
		portion_built_2025,
		portion_built_2035,
		portion_built_2055,
		planner_input,
		dob_matches,
		dob_matched_units,
		hpd_projected_closing_matches,
		hpd_projected_closing_matched_units,
		hpd_rfp_matches,
		hpd_rfp_matched_units,
		edc_matches,
		edc_matched_units,
		dcp_application_matches,
		dcp_application_matched_units,
		state_project_matches,
		state_project_matched_units,
		neighborhood_study_matches,
		neighborhood_study_units,
		public_sites_matches,
		public_sites_units,
		planner_projects_matches,
		planner_projects_units,
		nycha_flag,
		gq_flag,
		senior_housing_flag,
		assisted_living_flag,
		array_to_string(
			array_agg(
				nullif(
					concat_ws
					(
						': ',
						cd,
						concat(round(100*proportion_in_cd,0),'%')
					),
				'')),
		' | ') 	as Community_District 
	from
		aggregated_cd_longform
	group by
		the_geom,
		the_geom_webmercator,
		source,
		project_id,
		project_name_address,
		dob_job_type,
		status,
		borough,
		total_units,
		deduplicated_units,
		counted_units,
		portion_built_2025,
		portion_built_2035,
		portion_built_2055,
		planner_input,
		dob_matches,
		dob_matched_units,
		hpd_projected_closing_matches,
		hpd_projected_closing_matched_units,
		hpd_rfp_matches,
		hpd_rfp_matched_units,
		edc_matches,
		edc_matched_units,
		dcp_application_matches,
		dcp_application_matched_units,
		state_project_matches,
		state_project_matched_units,
		neighborhood_study_matches,
		neighborhood_study_units,
		public_sites_matches,
		public_sites_units,
		planner_projects_matches,
		planner_projects_units,
		nycha_flag,
		gq_flag,
		senior_housing_flag,
		assisted_living_flag
) x
;


drop table if exists longform_cd_output;
SELECT
	*
into
	longform_cd_output
from
(
	SELECT 
		*  
	FROM 
		capitalplanning.aggregated_cd_longform 
	where 
		not (source = 'DOB' and status in('Complete','Complete (demolition)')) and
		source not in('Future Neighborhood Studies','Neighborhood Study Projected Development Sites')
) x;


select cdb_cartodbfytable('capitalplanning','longform_cd_output') ;