# important files for InferCNV: https://github.com/broadinstitute/inferCNV/wiki/File-Definitions
library(infercnv)
library(glue)


r_run_infercnv <- function(path_file,
                           out_dir,
                           sample_tag,
                           annotations_file,
                           gene_order_file_path,
                           ref_group_names,
                           cutoff = 1,
                           min_cells_per_gene = 3,
                           window_length = 101,
                           smooth_method = "pyramidinal",
                           ref_subtract_use_mean_bounds = TRUE,
                           cluster_by_groups = FALSE,
                           cluster_references = TRUE,
                           k_obs_groups = 1,
                           max_centered_threshold = 3,
                           HMM = FALSE,
                           HMM_report_by = "subcluster",
                           HMM_type = "i6",
                           BayesMaxPNormal = 0.5,
                           sim_method = "meanvar",
                           sim_foreground = FALSE,
                           reassignCNVs = TRUE,
                           analysis_mode = "samples",
                           tumor_subcluster_partition_method = "random_trees",
                           tumor_subcluster_pval = 0.1,
                           denoise = FALSE,
                           sd_amplifier = 1.5,
                           noise_logistic = FALSE,
                           num_threads = 4,
                           plot_steps = FALSE,
                           hspike_aggregate_normals = FALSE,
                           up_to_step = 100) {

    infercnv_obj = CreateInfercnvObject(raw_counts_matrix=path_file,
                                        annotations_file=annotations_file,
                                        delim=",",
                                        gene_order_file=gene_order_file_path,
                                        ref_group_names=ref_group_names)

    infercnv_obj = infercnv::run(infercnv_obj,
                                 cutoff=cutoff, # cutoff=1 works well for Smart-seq2, and cutoff=0.1 works well for 10x Genomics
                                 min_cells_per_gene = min_cells_per_gene,
                                 window_length = window_length,
                                 smooth_method = smooth_method,
                                 ref_subtract_use_mean_bounds = ref_subtract_use_mean_bounds,
                                 cluster_by_groups = cluster_by_groups,
                                 cluster_references = cluster_references,
                                 k_obs_groups = k_obs_groups,
                                 max_centered_threshold = max_centered_threshold,
                                 HMM = HMM,
                                 HMM_report_by = HMM_report_by,
                                 HMM_type = HMM_type,
                                 BayesMaxPNormal = BayesMaxPNormal,
                                 sim_method = sim_method,
                                 sim_foreground = sim_foreground,
                                 reassignCNVs = reassignCNVs,
                                 analysis_mode = analysis_mode,
                                 tumor_subcluster_partition_method = tumor_subcluster_partition_method,
                                 tumor_subcluster_pval = tumor_subcluster_pval,
                                 denoise = denoise,
                                 sd_amplifier = sd_amplifier,
                                 noise_logistic = noise_logistic,
                                 num_threads = num_threads,
                                 plot_steps = plot_steps,
                                 hspike_aggregate_normals = hspike_aggregate_normals,
                                 up_to_step = up_to_step,
                                 out_dir=out_dir)

    write.csv(infercnv_obj@expr.data, glue("{out_dir}/{sample_tag}__cnv.csv"))
    write.csv(infercnv_obj@gene_order, glue("{out_dir}/{sample_tag}__gene.csv"))
}