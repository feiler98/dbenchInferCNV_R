# running scevan
# contains EnsDb.Hsapiens.v86 which correlates to hg 38

# imports
# ----------------------------------------------------------------------------------------------------------------------
import rpy2.robjects as robjects
from pathlib import Path
import pandas as pd
from utility import benchmark_method
import itertools
import random
import string
# ----------------------------------------------------------------------------------------------------------------------

def convert_bool_to_robject(bool_val: bool) -> robjects.vectors.BoolVector:
    return robjects.vectors.BoolVector([bool_val])

def random_sequence(len_seq: int) -> str:
    list_signs = []
    list_signs.extend(list(string.ascii_lowercase))
    list_signs.extend(list(string.ascii_uppercase))
    list_signs.extend(list(range(0, 10, 1)))
    random.shuffle(list_signs)
    i = 1
    rand_seq = []
    while i <= len_seq:
        rand_seq.append(str(list_signs[random.randint(0, len(list_signs)-1)]))
        i+=1
    return "".join(rand_seq)

def grid_by_dict(pars_dict: dict) -> list:
    keys=pars_dict.keys()
    combinations = itertools.product(*pars_dict.values())
    list_of_kwargs = [dict(zip(keys, cc)) for cc in combinations]
    return list_of_kwargs


def val_build_project() -> (Path, Path):
    cwd_path = Path.cwd()
    print(f"Current working directory of running script {Path(__file__).name}: {cwd_path}")
    path_out = cwd_path / "app" / "out"
    path_in = cwd_path / "data_input"

    if not path_in.exists():
        raise ValueError(f"Data dir '{str(path_in)}' does not exist!")

    if not path_out.exists():
        path_out.mkdir(parents=True, exist_ok=True)
        print(f"Data out-dir '{str(path_out)}' has been created...")

    return path_in, path_out


def get_hg_38_desc_paths(target_path: Path) -> dict:
    """
    These fetched .txt files correlate to .csv RCM files --> describe normal cells within the datasets.
    """
    return {p.stem: p for p in target_path.rglob("*__hg_38__describe.csv")}


def gen_data_dict(target_path: Path, precise_annotation: bool = False) -> dict:
    """
    Generates a dictionary with adata and their respective reference catalogue of normal cells (cell_names).
    """
    dict_hg38_desc = get_hg_38_desc_paths(target_path)
    dict_accepted_files = {}
    for k, path_desc in dict_hg38_desc.items():
        path_rcm = Path(target_path) / f"{k.replace('__describe', '')}__RCM.csv"
        if path_rcm.exists():
            obs_desc_df = pd.read_csv(path_desc, index_col="cell_id")
            if precise_annotation:
                list_cell_type = list(obs_desc_df["cell_type"].unique())
                list_cell_type.remove("Tumor")
                r_list_cell_type = robjects.StrVector(list_cell_type)
                dict_accepted_files[k.replace("__describe", "")] = {"path_file": path_rcm,
                                          "annotation_df": path_desc,
                                          "annotation_df_target_col": "cell_type",
                                          "ref_group_names":r_list_cell_type}
            else:
                dict_accepted_files[k.replace("__describe", "")] = {"path_file": path_rcm,
                                          "annotation_df": path_desc,
                                          "annotation_df_target_col": "cell_category",
                                          "ref_group_names":robjects.StrVector(["Normal"])}
    return dict_accepted_files


def run_r_infercnv(path_target: Path, path_out_data: Path, kwargs: dict) -> None:
    """
    Main function for running infercnvpy for benchmarking.

    Parameters
    ----------
    path_target: Path
        Directory with all datasets for benchmarking.
    path_out_data: Path
        Directory where to save the results for benchmarking.
    kwargs: dict
        Key-word-arguments (= kwargs) for infercnvpy.tl.infercnv() function.

    Returns
    -------
    pd.DataFrame
        Returns inferred copy number variations as table.
    """
    kwargs_infercnvpy = kwargs.copy()
    if not "precise_annotation" in kwargs:
        precise_annotation = False
    else:
        precise_annotation = kwargs["precise_annotation"]
        del kwargs_infercnvpy["precise_annotation"]
    dict_files = gen_data_dict(path_target, precise_annotation)
    for tag_dataset, dict_data in dict_files.items():
        str_kwargs = random_sequence(len_seq=8)
        file_name = f"{tag_dataset}__{str_kwargs}__infercnvr"
        data_save_path = path_out_data / file_name
        data_save_path.mkdir(exist_ok=True)
        p_annot_file = data_save_path / f"{file_name}__annot.txt"
        pd.read_csv(dict_data["annotation_df"], index_col="cell_id")[dict_data["annotation_df_target_col"]].to_csv(p_annot_file, header=False)

        @benchmark_method(str(data_save_path))
        def run_rscript(path_file,
                        out_dir,
                        sample_tag,
                        annotations_file,
                        gene_order_file_path,
                        ref_group_names,
                        kwargs):
            r = robjects.r
            r.source(str(Path(__file__).parent / "c_infercnvR.R"))
            # reformat here to avoid datatype issues with benchmark summary
            kwargs_reformat = {x: convert_bool_to_robject(y) if isinstance(y, bool) else y for x, y in kwargs.items()}
            r.r_run_infercnv(path_file,
                             out_dir,
                             sample_tag,
                             annotations_file,
                             gene_order_file_path,
                             ref_group_names,
                             **kwargs_reformat)
        try:
            run_rscript(path_file=str(dict_data["path_file"]),
                        out_dir=str(data_save_path),
                        sample_tag=file_name,
                        annotations_file=str(p_annot_file),
                        gene_order_file_path=str(Path(__file__).parent / "genome_data" / "hg38_gencode_v27.txt"),
                        ref_group_names=dict_data["ref_group_names"],
                        kwargs=kwargs_infercnvpy)
        except:
            pass


if __name__ == "__main__":
    #robjects.vectors.BoolVector([True])
    # matrix of possible infercnvR hyperparameter kwargs
    kwargs_gridsearch = {"cutoff":[0.1, 0.5, 1.0],
                         "min_cells_per_gene":[3, 10, 25],
                         "window_length":[10, 25, 101, 200],
                         "smooth_method":["pyramidinal", "runmeans", "coordinates"],
                         "ref_subtract_use_mean_bounds":[True],
                         "cluster_by_groups":[True, False],
                         "cluster_references":[True],
                         "k_obs_groups":[1],
                         "max_centered_threshold":[3],
                         "HMM":[True, False],
                         "HMM_report_by":["subcluster", "consensus"],
                         "HMM_type":["i6", "i3"],
                         "BayesMaxPNormal":[0.3, 0.5, 0.7],
                         "sim_method":["meanvar"],
                         "sim_foreground":[True, False],
                         "reassignCNVs":[True],
                         "analysis_mode":["samples", "subclusters"],
                         "tumor_subcluster_partition_method":["random_trees","qnorm"],
                         "tumor_subcluster_pval":[0.05],
                         "denoise": [True, False],
                         "sd_amplifier":[1.5],
                         "noise_logistic":[True, False],
                         "num_threads":[50],
                         "plot_steps":[True, False],
                         "hspike_aggregate_normals":[True, False],
                         "up_to_step":[100],
                         "precise_annotation":[True, False]}

    path_in, path_out = val_build_project()
    list_kwargs = grid_by_dict(kwargs_gridsearch)
    list_kwargs = random.sample(list_kwargs, 1500)
    for kwarg_opt in list_kwargs:
        print(f"InferCNV (R) running with hyperparameters: {kwarg_opt}")
        run_r_infercnv(path_in, path_out, kwargs=kwarg_opt)