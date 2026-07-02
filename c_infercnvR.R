# important files for InferCNV: https://github.com/broadinstitute/inferCNV/wiki/File-Definitions
library(InferCNV)


r_run_infercnv <- function(path_file,
                           sample_tag,
                           annotations_file,
                           gene_order_file_path,
                           ref_group_names,
                           cutoff,
                           denoise,
                           hmm,
                           out_dir) {

    infercnv_obj = CreateInfercnvObject(raw_counts_matrix=path_file,
                                        annotations_file=annotations_file,
                                        delim=", ",
                                        gene_order_file=gene_order_file_path,
                                        ref_group_names=ref_group_names)

    infercnv_obj = infercnv::run(infercnv_obj,
                                 cutoff=cutoff, # cutoff=1 works well for Smart-seq2, and cutoff=0.1 works well for 10x Genomics
                                 cluster_by_groups=TRUE,
                                 denoise=denoise,
                                 HMM=hmm,
                                 out_dir=out_dir)

    write.csv(infercnv_obj@expr.data, glue("{sample_tag}__results.csv"))
}