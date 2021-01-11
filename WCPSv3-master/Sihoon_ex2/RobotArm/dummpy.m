file_name0 = 'Simul_results_Ours_broadcast_interval_3hop.mat';     % store results for a simulation
file_name1 = 'Simul_results_WH_broadcast_interval_3hop.mat';
field_name_P1 = 'Log_broad_interv_P1';  
log_name_P1 = 'broad_interv_P1.mat';

Load_result = load(file_name0);
Load_broad_interv_P1 = getfield(Load_result, field_name_P1);

Log_broad_interv_P1 = Load_broad_interv_P1(202:end)

save(save_file_name, field_name_P1);
