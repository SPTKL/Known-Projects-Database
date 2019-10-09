/*Aggregating deduplicated data*/

drop table if exists known_projects_db_20190917_v6;

create table
	known_projects_db_20190917_v6
as
(
	select
		the_geom,
		the_geom_webmercator,
		'DOB' as source,
		concat(job_number) 			as project_id,
		address						as project_name_address,
		job_type					as dob_job_type,
		case
			when inactive_job is true then 1
			else 0 	end 			as dob_inactive_job,
		status						as status,
		borough,
		units_net_incomplete		as total_units,
		units_net_incomplete		as deduplicated_units,
		units_net_incomplete		as counted_units,
		portion_built_2025,
		portion_built_2035,
		portion_built_2055,
		''							as planner_input,
		'' 							as dob_matches,
		null::numeric				as dob_matched_units,
		''							as hpd_projected_closing_matches,
		null::numeric				as hpd_projected_closing_matched_units,
		''							as hpd_rfp_matches,
		null::numeric				as hpd_rfp_matched_units,
		''							as edc_matches,
		null::numeric				as edc_matched_units,
		'' 							as dcp_application_matches,
		null::numeric				as dcp_application_matched_units,
		''							as state_project_matches,
		null::numeric				as state_project_matched_units,
		''							as neighborhood_study_matches,
		null::numeric				as neighborhood_study_units,
		''							as public_sites_matches,
		null::numeric				as public_sites_units,
		''							as planner_projects_matches,
		null::numeric				as planner_projects_units,
		'' 							as matches_to_nstudy_projected,
		null::numeric				as units_matched_to_nstudy_projected,
		nycha_flag,
		gq_flag,
		senior_housing_flag,
		assisted_living_flag
	from
		dob_2018_sca_inputs_ms_2_1
	-- where
	-- 	status not in('Complete','Complete (demolition)')
	union all
	select
		the_geom,
		the_geom_webmercator,
		'HPD Projected Closings' 	as source,
		project_id 					as project_id,
		address						as project_name_address,
		''							as dob_job_type,
		null 						as dob_inactive_job,
		'Projected'					as status,
		borough,
		total_units,
		hpd_incremental_units 		as deduplicated_units,
		counted_units,
		portion_built_2025,
		portion_built_2035,
		portion_built_2055,
		''							as planner_input,
		dob_job_numbers				as dob_matches,
		dob_units_net				as dob_matched_units,
		''							as hpd_projected_closing_matches,
		null::numeric				as hpd_projected_closing_matched_units,
		''							as hpd_rfp_matches,
		null::numeric				as hpd_rfp_matched_units,
		''							as edc_matches,
		null::numeric				as edc_matched_units,
		'' 							as dcp_application_matches,
		null::numeric				as dcp_application_matched_units,
		''							as state_project_matches,
		null::numeric				as state_project_matched_units,
		''							as neighborhood_study_matches,
		null::numeric				as neighborhood_study_units,
		''							as public_sites_matches,
		null::numeric				as public_sites_units,
		''							as planner_projects_matches,
		null::numeric				as planner_projects_units,
		'' 							as matches_to_nstudy_projected,
		null::numeric				as units_matched_to_nstudy_projected,
		nycha_flag,
		gq_flag,
		senior_housing_flag,
		assisted_living_flag
	from
		hpd_deduped


	union all
	select
		the_geom,
		the_geom_webmercator,
		'HPD RFPs' 												as source,
		concat(project_id) 										as project_id,
		project_name											as project_name_address,
		''														as dob_job_type,
		null 													as dob_inactive_job,
		status,
		borough,
		total_units,
		hpd_rfp_incremental_units								as deduplicated_units,
		counted_units,
		portion_built_2025,
		portion_built_2035,
		portion_built_2055,
		''														as planner_input,
		dob_job_numbers											as dob_matches,
		dob_units_net											as dob_matched_units,
		hpd_projected_closings_ids								as hpd_projected_closing_matches,
		hpd_projected_closings_incremental_units				as hpd_projected_closing_matched_units,
		''														as hpd_rfp_matches,
		null::numeric											as hpd_rfp_matched_units,
		''														as edc_matches,
		null::numeric											as edc_matched_units,
		'' 														as dcp_application_matches,
		null::numeric											as dcp_application_matched_units,
		''														as state_project_matches,
		null::numeric											as state_project_matched_units,
		''														as neighborhood_study_matches,
		null::numeric											as neighborhood_study_units,
		''														as public_sites_matches,
		null::numeric											as public_sites_units,
		''														as planner_projects_matches,
		null::numeric											as planner_projects_units,
		'' 														as matches_to_nstudy_projected,
		null::numeric											as units_matched_to_nstudy_projected,
		nycha_flag,
		gq_flag,
		senior_housing_flag,
		assisted_living_flag
	from
		hpd_rfp_deduped
	union all
	select
		the_geom,
		the_geom_webmercator,
		'EDC Projected Projects'								as source,
		concat(project_id) 										as project_id,
		project_name											as project_name_address,
		''														as dob_job_type,
		null 													as dob_inactive_job,
		'Projected'												as status,
		borough,
		total_units,
		edc_incremental_units									as deduplicated_units,
		counted_units,
		portion_built_2025,
		portion_built_2035,
		portion_built_2055,
		''														as planner_input,
		dob_job_numbers											as dob_matches,
		dob_units_net											as dob_matched_units,
		hpd_projected_closings_ids								as hpd_projected_closing_matches,
		hpd_projected_closings_incremental_units				as hpd_projected_closing_matched_units,
		hpd_rfp_ids												as hpd_rfp_matches,
		hpd_rfp_incremental_units								as hpd_rfp_matched_units,
		''														as edc_matches,
		null::numeric											as edc_matched_units,
		'' 														as dcp_application_matches,
		null::numeric											as dcp_application_matched_units,
		''														as state_project_matches,
		null::numeric											as state_project_matched_units,
		''														as neighborhood_study_matches,
		null::numeric											as neighborhood_study_units,
		''														as public_sites_matches,
		null::numeric											as public_sites_units,
		''														as planner_projects_matches,
		null::numeric											as planner_projects_units,
		'' 														as matches_to_nstudy_projected,
		null::numeric											as units_matched_to_nstudy_projected,
		nycha_flag,
		gq_flag,
		senior_housing_flag,
		assisted_living_flag
	from
		edc_deduped
	union all
	select
		the_geom,
		the_geom_webmercator,
		'DCP Applications'										as source,
		project_id 												as project_id,
		project_name											as project_name_address,
		''														as dob_job_type,
		null 													as dob_inactive_job,
		status													as status,
		borough,
		total_units,
		zap_incremental_units									as deduplicated_units,
		counted_units,
		portion_built_2025::numeric								as portion_built_2025,
		portion_built_2035::numeric								as portion_built_2035,
		portion_built_2055::numeric								as portion_built_2055,
		planner_input											as planner_input,
		dob_job_numbers											as dob_matches,
		dob_units_net											as dob_matched_units,
		hpd_projected_closings_ids								as hpd_projected_closing_matches,
		hpd_projected_closings_incremental_units				as hpd_projected_closing_matched_units,
		hpd_rfp_ids												as hpd_rfp_matches,
		hpd_rfp_incremental_units								as hpd_rfp_matched_units,
		edc_project_ids											as edc_matches,
		edc_incremental_units									as edc_matched_units,
		'' 														as dcp_application_matches,
		null::numeric											as dcp_application_matched_units,
		''														as state_project_matches,
		null::numeric											as state_project_matched_units,
		''														as neighborhood_study_matches,
		null::numeric											as neighborhood_study_units,
		''														as public_sites_matches,
		null::numeric											as public_sites_units,
		''														as planner_projects_matches,
		null::numeric											as planner_projects_units,
		'' 														as matches_to_nstudy_projected,
		null::numeric											as units_matched_to_nstudy_projected,
		nycha_flag,
		gq_flag,
		senior_housing_flag,
		assisted_living_flag
	from
		zap_deduped_build_year
	where
		project_id not like '%[ESD%'
	union all
	select
		the_geom,
		the_geom_webmercator,
		'Empire State Development Projected Projects'			as source,
		project_id 												as project_id,
		project_name											as project_name_address,
		''														as dob_job_type,
		null 													as dob_inactive_job,
		'Projected'												as status,
		borough,
		total_units,
		zap_incremental_units									as deduplicated_units,
		counted_units,
		portion_built_2025::numeric								as portion_built_2025,
		portion_built_2035::numeric								as portion_built_2035,
		portion_built_2055::numeric								as portion_built_2055,
		planner_input											as planner_input,
		dob_job_numbers											as dob_matches,
		dob_units_net											as dob_matched_units,
		hpd_projected_closings_ids								as hpd_projected_closing_matches,
		hpd_projected_closings_incremental_units				as hpd_projected_closing_matched_units,
		hpd_rfp_ids												as hpd_rfp_matches,
		hpd_rfp_incremental_units								as hpd_rfp_matched_units,
		edc_project_ids											as edc_matches,
		edc_incremental_units									as edc_matched_units,
		'' 														as dcp_application_matches,
		null::numeric											as dcp_application_matched_units,
		''														as state_project_matches,
		null::numeric											as state_project_matched_units,
		''														as neighborhood_study_matches,
		null::numeric											as neighborhood_study_units,
		''														as public_sites_matches,
		null::numeric											as public_sites_units,
		''														as planner_projects_matches,
		null::numeric											as planner_projects_units,
		'' 														as matches_to_nstudy_projected,
		null::numeric											as units_matched_to_nstudy_projected,
		nycha_flag,
		gq_flag,
		senior_housing_flag,
		assisted_living_flag
	from
		zap_deduped_build_year
	where
		project_id like '%[ESD%'
	union all
	select
		the_geom,
		the_geom_webmercator,
		'Neighborhood Study Rezoning Commitments'				as source,
		project_id 												as project_id,
		project_name											as project_name_address,
		''														as dob_job_type,
		null 													as dob_inactive_job,
		status													as status,
		borough,
		total_units,
		nstudy_incremental_units								as deduplicated_units,
		counted_units,
		portion_built_2025::numeric								as portion_built_2025,
		portion_built_2035::numeric								as portion_built_2035,
		portion_built_2055::numeric								as portion_built_2055,
		planner_input											as planner_input,
		dob_job_numbers											as dob_matches,
		dob_units_net											as dob_matched_units,
		hpd_projected_closings_ids								as hpd_projected_closing_matches,
		hpd_projected_closings_incremental_units				as hpd_projected_closing_matched_units,
		hpd_rfp_ids												as hpd_rfp_matches,
		hpd_rfp_incremental_units								as hpd_rfp_matched_units,
		edc_project_ids											as edc_matches,
		edc_incremental_units									as edc_matched_units,
		zap_project_ids 										as dcp_application_matches,
		zap_incremental_units									as dcp_application_matched_units,
		''														as state_project_matches,
		null::numeric											as state_project_matched_units,
		''														as neighborhood_study_matches,
		null::numeric											as neighborhood_study_units,
		''														as public_sites_matches,
		null::numeric											as public_sites_units,
		''														as planner_projects_matches,
		null::numeric											as planner_projects_units,
		'' 														as matches_to_nstudy_projected,
		null::numeric											as units_matched_to_nstudy_projected,
		nycha_flag,
		gq_flag,
		senior_housing_flag,
		assisted_living_flag
	from
		nstudy_deduped
	union all
	select
		the_geom,
		the_geom_webmercator,
		source,
		project_id 													as project_id,
		project_name												as project_name_address,
		''															as dob_job_type,
		null 														as dob_inactive_job,
		'Projected'													as status,
		borough,
		total_units,
		public_sites_incremental_units								as deduplicated_units,
		counted_units,
		portion_built_2025::numeric									as portion_built_2025,
		portion_built_2035::numeric									as portion_built_2035,
		portion_built_2055::numeric									as portion_built_2055,
		planner_input												as planner_input,
		dob_job_numbers												as dob_matches,
		dob_units_net												as dob_matched_units,
		hpd_projected_closings_ids									as hpd_projected_closing_matches,
		hpd_projected_closings_incremental_units					as hpd_projected_closing_matched_units,
		hpd_rfp_ids													as hpd_rfp_matches,
		hpd_rfp_incremental_units									as hpd_rfp_matched_units,
		edc_project_ids												as edc_matches,
		edc_incremental_units										as edc_matched_units,
		zap_project_ids 											as dcp_application_matches,
		zap_incremental_units										as dcp_application_matched_units,
		''															as state_project_matches,
		null::numeric												as state_project_matched_units,
		nstudy_project_ids											as neighborhood_study_matches,
		nstudy_incremental_units									as neighborhood_study_units,
		''															as public_sites_matches,
		null::numeric												as public_sites_units,
		''															as planner_projects_matches,
		null::numeric												as planner_projects_units,
		'' 															as matches_to_nstudy_projected,
		null::numeric												as units_matched_to_nstudy_projected,
		nycha_flag,
		gq_flag,
		senior_housing_flag,
		assisted_living_flag
	from
		public_sites_deduped
	union all
	select
		the_geom,
		the_geom_webmercator,
		'DCP Planner-Added Projects'								as source,
		concat(project_id)											as project_id,
		project_name												as project_name_address,
		''															as dob_job_type,
		null 														as dob_inactive_job,
		'Potential'													as status,
		borough,
		total_units,
		planner_projects_incremental_units							as deduplicated_units,
		counted_units,
		portion_built_2025::numeric									as portion_built_2025,
		portion_built_2035::numeric									as portion_built_2035,
		portion_built_2055::numeric									as portion_built_2055,
		planner_input												as planner_input,
		dob_job_numbers												as dob_matches,
		dob_units_net												as dob_matched_units,
		hpd_projected_closings_ids									as hpd_projected_closing_matches,
		hpd_projected_closings_incremental_units					as hpd_projected_closing_matched_units,
		hpd_rfp_ids													as hpd_rfp_matches,
		hpd_rfp_incremental_units									as hpd_rfp_matched_units,
		edc_project_ids												as edc_matches,
		edc_incremental_units										as edc_matched_units,
		zap_project_ids 											as dcp_application_matches,
		zap_incremental_units										as dcp_application_matched_units,
		''															as state_project_matches,
		null::numeric												as state_project_matched_units,
		nstudy_project_ids											as neighborhood_study_matches,
		nstudy_incremental_units									as neighborhood_study_units,
		public_sites_project_ids									as public_sites_matches,
		public_sites_incremental_units								as public_sites_units,
		''															as planner_projects_matches,
		null::numeric												as planner_projects_units,
		'' 															as matches_to_nstudy_projected,
		null::numeric												as units_matched_to_nstudy_projected,
		nycha_flag,
		gq_flag,
		senior_housing_flag,
		assisted_living_flag
	from
		planner_projects_deduped
	union all
	select
		the_geom,
		the_geom_webmercator,
		source,
		project_id,
		neighborhood 												as project_name_address,
		''															as dob_job_type,
		null 														as dob_inactive_job,
		status,
		borough,
		total_units,
		nstudy_projected_potential_incremental_units 				as deduplicated_units,
		nstudy_projected_potential_incremental_units 				as counted_units,
		portion_built_2025,
		portion_built_2035,
		portion_built_2055,
		''															as planner_input,
		''															as dob_matches,
		null														as dob_matched_units,
		''															as hpd_projected_closing_matches,
		null														as hpd_projected_closing_matched_units,
		''															as hpd_rfp_matches,
		null														as hpd_rfp_matched_units,
		''															as edc_matches,
		null														as edc_matched_units,
		''				 											as dcp_application_matches,
		null														as dcp_application_matched_units,
		''															as state_project_matches,
		null::numeric												as state_project_matched_units,
		''															as neighborhood_study_matches,
		null														as neighborhood_study_units,
		''															as public_sites_matches,
		null														as public_sites_units,
		''															as planner_projects_matches,
		null::numeric												as planner_projects_units,
		'' 															as matches_to_nstudy_projected,
		null::numeric												as units_matched_to_nstudy_projected,
		null	 													as nycha_flag,
		null	 													as gq_flag,
		null	 													as senior_housing_flag,
		null	 													as assisted_living_flag
	from
		nstudy_projected_potential_areawide_deduped_final
	union all
	select
		the_geom,
		the_geom_webmercator,
		source,
		project_id,
		neighborhood 												as project_name_address,
		''															as dob_job_type,
		null 														as dob_inactive_job,
		status,
		borough,
		incremental_units_with_certainty_factor,
		incremental_units_with_certainty_factor 					as deduplicated_units,
		incremental_units_with_certainty_factor 					as counted_units,
		portion_built_2025,
		portion_built_2035,
		portion_built_2055,
		''															as planner_input,
		''															as dob_matches,
		null														as dob_matched_units,
		''															as hpd_projected_closing_matches,
		null														as hpd_projected_closing_matched_units,
		''															as hpd_rfp_matches,
		null														as hpd_rfp_matched_units,
		''															as edc_matches,
		null														as edc_matched_units,
		''				 											as dcp_application_matches,
		null														as dcp_application_matched_units,
		''															as state_project_matches,
		null::numeric												as state_project_matched_units,
		''															as neighborhood_study_matches,
		null														as neighborhood_study_units,
		''															as public_sites_matches,
		null														as public_sites_units,
		''															as planner_projects_matches,
		null::numeric												as planner_projects_units,
		'' 															as matches_to_nstudy_projected,
		null::numeric												as units_matched_to_nstudy_projected,
		null	 													as nycha_flag,
		null	 													as gq_flag,
		null	 													as senior_housing_flag,
		null	 													as assisted_living_flag
	from
		nstudy_future
)
order by 
	source asc,
	project_id asc,
	project_name_address asc,
	status asc;


select cdb_cartodbfytable('capitalplanning','known_projects_db_20190917_v6') ;