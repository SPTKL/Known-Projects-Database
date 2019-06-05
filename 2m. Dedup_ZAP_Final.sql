/************************************************************************************************************************************************************************************
AUTHOR: Mark Shapiro
SCRIPT: Create a final deduped ZAP dataset
*************************************************************************************************************************************************************************************/

/************************************************************************************************************************************************************************************
METHODOLOGY: 
1. Aggregate ZAP matches to DOB, HPD Projected Closings, HPD RFP, and EDC data.
2. Calculate ZAP increment
************************************************************************************************************************************************************************************/
/*************************RUN IN CARTO BATCH********************/

/*Remember to change the column ordering here to align with what you saw in the relevant projects list sent to SCA and DOE*/

select
	*
into
	zap_deduped
from
(
	select
		a.cartodb_id,
		a.the_geom,
		a.the_geom_webmercator,
		'DCP Applications' as Source,
		a.project_id,
		a.project_name,
		a.dcp_edit_project_status as status,
		a.borough, 
		a.project_description,
		a.project_brief,
		a.total_units,
		greatest
				(
					0,
					a.total_units 										-
					coalesce(b.dob_units_net,0) 						-
					coalesce(c.hpd_project_incremental_units,0)			-
					coalesce(d.hpd_rfp_incremental_units,0)				-
					coalesce(e.edc_incremental_units,0)
				) as zap_incremental_units,
		a.applicant_type,
		a.dcp_target_certification_date,
		a.certified_referred,
		a.project_completed,
		a.ulurp,
		a.Anticipated_year_built as applicant_projected_build_year,
		a.early_stage_flag,
		a.si_seat_cert,
		a.NYCHA_Flag,
		a.gq_flag,
		a.Assisted_Living_Flag,
		case when a.Senior_Housing_Flag = 1 then 1 else 0 end as Senior_Housing_Flag,
		a.portion_built_2025,
		a.portion_built_2035,
		a.portion_built_2055,
		a.planner_input,
		b.dob_job_numbers,
		b.dob_units_net,
		c.hpd_project_ids as hpd_projected_closings_ids,
		c.hpd_project_incremental_units as hpd_projected_closings_incremental_units,
		d.hpd_rfp_ids,
		d.hpd_rfp_incremental_units,
		e.edc_project_ids,
		e.edc_incremental_units
	from
		capitalplanning.relevant_dcp_projects_housing_pipeline_ms_v5 a
	left join
		capitalplanning.zap_dob_final b
	on 
		a.project_id = b.project_id 
	left join
		capitalplanning.zap_hpd_projected_closings_final c 
	on
		a.project_id = c.project_id 
	left join
		capitalplanning.zap_hpd_rfps_final d
	on
		a.project_id = d.project_id 
	left join
		capitalplanning.zap_edc_final e
	on
		a.project_id = e.project_id
) zap_deduped


/*Adding in additional build year assumptions. Next step is to fix for active per-certs where applicant_build_year is null*/

select
	*
into
	zap_deduped_1_test
from
(
	select
		a.the_geom,
		a.the_geom_webmercator,
		a.Source,
		a.project_id,
		a.project_name,
		a.status,
		a.borough, 
		a.project_description,
		a.project_brief,
		a.total_units,
		a.zap_incremental_units,
		a.applicant_type,
		a.dcp_target_certification_date,
		a.certified_referred,
		a.project_completed,
		a.ulurp,
		a.applicant_projected_build_year,
		case
			when coalesce(a.portion_built_2025,0)+coalesce(a.portion_built_2035,0)+coalesce(a.portion_built_2055,0) > 0
																												 	then
																													coalesce(a.portion_built_2025,0)

			when (a.total_units > 10 and a.total_units::float*.2 > a.zap_incremental_units::float)
																													then 
																													1
			when (a.total_units <= 10 and a.total_units - a.zap_incremental_units > 3)
																													then 
																													1
			/*Adding in HY Phasing, taken from 2018 planner input*/
			when a.project_id = 'P2005M0053'																		then
																													.2
			/*Adding in WRY Phasing, taken from 2018 planner input*/
			when a.project_id = 'P2009M0294'																		then
																													.2
			/*Adding in Pfizer Sites Phasing. STILL TO DO.*/
			when a.project_id = 'P2013K0309'																		then
																													.5
			/*Adding in Peninsula phasing, taken from Peninsula EIS documents.*/
			when a.project_id = 'P2016Q0306'																		then
																													862::float/2200::float

			when c.remaining_likely_to_be_built = 'No'
																													then 
																													0
			when 
				a.status = 'Complete'				and
				(a.applicant_projected_build_year is null or a.applicant_projected_build_year <=2025)				then  
																													1
			when 
				a.status = 'Complete'				and
				a.applicant_projected_build_year between 2025 and 2035												then  
																													0
			when 
				a.status = 'Complete'				and
				a.applicant_projected_build_year > 2035																then  
																													0

			when a.status in ('Active, Initiation','Active, Pre-PAS')												then
																													0
			when 
				a.status = 'Active, Pre-Cert'			and 
				a.dcp_target_certification_date is not null 	and
				(a.applicant_projected_build_year <=2025 or a.applicant_projected_build_year is null)				then
																													1
			when 
				a.status = 'Active, Pre-Cert'			and 
				a.dcp_target_certification_date is not null 	and
				a.applicant_projected_build_year between 2025 and 2035												then
																													0
			when 
				a.status = 'Active, Pre-Cert'			and 
				a.dcp_target_certification_date is not null 	and
				a.applicant_projected_build_year > 2035																then
																													0	
			when 
				a.status = 'Active, Pre-Cert'			and 	
				a.dcp_target_certification_date is null 		and
				(a.applicant_projected_build_year	<=2035 or a.applicant_projected_build_year is null)				then
																													0
			when 
				a.status = 'Active, Pre-Cert'			and 	
				a.dcp_target_certification_date is null 		and
				a.applicant_projected_build_year	>2035															then
																													0
			when 
				a.status like '%On-Hold%'				and
				(a.applicant_projected_build_year is null or a.applicant_projected_build_year <=2035)				then  
																													0
			when 
				a.status like '%On-Hold%'				and
				a.applicant_projected_build_year > 2035																then  
																													0
			else
																													null
			END 																									as portion_built_2025,
		a.early_stage_flag,
		a.si_seat_cert,
		a.NYCHA_Flag,
		a.gq_flag,
		a.Assisted_Living_Flag,
		a.Senior_Housing_Flag,
		a.planner_input,
		a.dob_job_numbers,
		a.dob_units_net,
		a.hpd_projected_closings_ids,
		a.hpd_projected_closings_incremental_units,
		a.hpd_rfp_ids,
		a.hpd_rfp_incremental_units,
		a.edc_project_ids,
		a.edc_incremental_units
	from
		zap_deduped a
	left join
		dcp_2018_sca_inputs_share c
	on
		a.project_id = c.project_id 	and
		a.portion_built_2055 is null 	and
		a.portion_built_2035 is null 	and
		a.portion_built_2025 is null 
	left join
		dcp_project_flags_v2 b
	on
		a.project_id = b.project_id 	and
		a.portion_built_2055 is null 	and
		a.portion_built_2035 is null 	and
		a.portion_built_2025 is null 	and
		a.ulurp = 'Non-ULURP' 
	order by 
		a.project_id asc
) zap_deduped_1_test



/*RUN IN REGULAR CARTO*/

select cdb_cartodbfytable('capitalplanning','zap_deduped')





		case
			when coalesce(portion_built_2025,0)+coalesce(portion_built_2035,0)+coalesce(portion_built_2055,0) > 0 	then
																													coalesce(portion_built_2025,0) 	as portion_built_2025,
																													coalesce(portion_built_2035,0) 	as portion_built_2035,
																													coalesce(portion_built_2055,0) 	as portion_built_2055,

			when (total_units > 10 and total_units::float*.2 > zap_incremental_units::float)
																													then 
																													1 								as portion_built_2025,
																													0 								as portion_built_2035,
																													0 								as portion_built_2055,
			when (total_units <= 10 and total_units - zap_incremental_units > 3)
																													then 
																													1 								as portion_built_2025,
																													0 								as portion_built_2035,
																													0 								as portion_built_2055,
			/*Adding in HY Phasing, taken from 2018 planner input*/
			when project_id = 'P2005M0053'																			then
																													.2 								as portion_built_2025,
																													.8 								as portion_built_2035,
																													0 								as portion_built_2055,
			/*Adding in WRY Phasing, taken from 2018 planner input*/
			when project_id = 'P2009M0294'																			then
																													.2 								as portion_built_2025,
																													.8 								as portion_built_2035,
																													0 								as portion_built_2055,
			/*Adding in Pfizer Sites Phasing. STILL TO DO.*/
			when project_id = 'P2013K0309'																			then
																													.5 								as portion_built_2025,
																													.5 								as portion_built_2035,
																													0 								as portion_built_2055,
			/*Adding in Peninsula phasing, taken from Peninsula EIS documents.*/
			when project_id = 'P2016Q0306'																			then
																													862::float/2200::float			as portion_built_2025,
																													1338::float/2200::float			as portion_built_2035,
																													0 								as portion_built_2055,

			when c.remaining_likely_to_be_built = 'No'
																													then 
																													0 								as portion_built_2025,
																													0 								as portion_built_2035,
																													1 								as portion_built_2055,
			when 
				project_status = 'Complete'				and
				(applicant_projected_build_year is null or applicant_projected_build_year <=2025)					then  
																													1 								as portion_built_2025,
																													0 								as portion_built_2035,
																													0 								as portion_built_2055,
			when 
				project_status = 'Complete'				and
				applicant_projected_build_year between 2025 and 2035												then  
																													0 								as portion_built_2025,
																													1 								as portion_built_2035,
																													0 								as portion_built_2055,
			when 
				project_status = 'Complete'				and
				applicant_projected_build_year > 2035																then  
																													0 								as portion_built_2025,
																													0 								as portion_built_2035,
																													1 								as portion_built_2055,

			when project_status in ('Active, Initiation','Active, Pre-PAS')											then
																													0 								as portion_built_2025,
																													1 								as portion_built_2035,
																													0 								as portion_built_2055,
			when 
				project_status = 'Active, Pre-Cert'			and 
				dcp_target_certification_date is not null 	and
				applicant_projected_build_year <=2025																then
																													1 								as portion_built_2025,
																													0 								as portion_built_2035,
																													0 								as portion_built_2055,
			when 
				project_status = 'Active, Pre-Cert'			and 
				dcp_target_certification_date is not null 	and
				applicant_projected_build_year between 2025 and 2035												then
																													0 								as portion_built_2025,
																													1 								as portion_built_2035,
																													0 								as portion_built_2055,
			when 
				project_status = 'Active, Pre-Cert'			and 
				dcp_target_certification_date is not null 	and
				applicant_projected_build_year between > 2035														then
																													0 								as portion_built_2025,
																													0 								as portion_built_2035,	
																													1 								as portion_built_2055,	
			when 
				project_status = 'Active, Pre-Cert'			and 	
				dcp_target_certification_date is null 		and
				applicant_projected_build_year	<=2035																then
																													0 								as portion_built_2025,
																													1 								as portion_built_2035,
																													0 								as portion_built_2055,
			when 
				project_status = 'Active, Pre-Cert'			and 	
				dcp_target_certification_date is null 		and
				applicant_projected_build_year	>2035																then
																													0 								as portion_built_2025,
																													0 								as portion_built_2035,
																													1 								as portion_built_2055,
			when 
				project_status like '%On-Hold%'				and
				(applicant_projected_build_year is null or applicant_projected_build_year <=2035)					then  
																													0 								as portion_built_2025,
																													1 								as portion_built_2035,
																													0 								as portion_built_2055,
			when 
				project_status like '%On-Hold%'				and
				applicant_projected_build_year > 2035																then  
																													0 								as portion_built_2025,
																													0 								as portion_built_2035,
																													1 								as portion_built_2055,
			else
																													null							as portion_built_2025,
																													null							as portion_built_2035,
																													null							as portion_built_2055,
			END
