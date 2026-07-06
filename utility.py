# general utility functions for benchmarking x_clone_rdr

# imports
from collections.abc import Callable
from pathlib import Path
import time
import pandas as pd



def get_project_dir(cwd: Path, parent_path_str: str) -> Path:
    """
    Recursive path search until getting parent-path.

    Parameters
    ----------
    cwd: pathlib.Path
        Path that needs to be searched (named after current working directory).
    parent_path_str : str
        String which is contained in the path.

    Returns
    -------
    pathlib.Path
        Query parent-path.
    """

    if cwd.name != parent_path_str:
        parent_path = cwd.parent
        # always return the recursion, otherwise output is None
        return get_project_dir(cwd=parent_path, parent_path_str=parent_path_str)
    else:
        return cwd


# decorator for benchmarking + saving metadata of func input
# ----------------------------------------------------------
def benchmark_method(path_out: str = str(Path.cwd())) -> Callable:
    """
    Very handy DECORATOR for benchmarking different python functions + saving timing and all parameters in an
    excel-sheet.
    Must be written as '@benchmark_method()' above a function.
    Output excel sheet will have the following naming convention: benchmark__funcName__startTimestamp.xlsx

    Parameters
    ----------
    path_out: str
        Target directory absolute path as string for the excel_workbook with the summary of the benchmarking.
        If no path is supplied or the given path does not exist, the current working directory is set as standard.

    Returns
    -------
    Callable
        Returns the decorated function.

    """
    path_out = Path(str(path_out)).resolve()
    if not path_out.exists():
        print(f"\033[31mGiven path '{str(path_out)}' does not exist!\033[0m")
        path_out = Path.cwd()
    print(f"\033[31mSet output path | {str(path_out)}\033[0m")

    # time the method
    # ---------------------------------------------------------------------------
    def time_wrapper(func):
        func_name = func.__name__
        parm = func.__code__.co_varnames[0:func.__code__.co_argcount]
        def wrapper(*args, **kwargs):
            kwargs.update(dict(zip(parm, args)))
            start_time = time.time()
            target_func = func(**kwargs)
            end_time = time.time()

            # note the time ranges
            # ---------------------------------------------------------------------------
            t_diff = round(abs(start_time - end_time), 2)  # in seconds, rounded to 2 decimal places
            start_strf = time.strftime("%D %T", time.gmtime(start_time))
            end_strf = time.strftime("%D %T", time.gmtime(end_time))

            print(f"""\033[31m
------------------------------------
|     Time results of function     |
------------------------------------
startpoint | {start_strf}
endpoint   | {end_strf}
====================================
t-diff     | {t_diff} s
------------------------------------
                \033[0m""")

            # prepare the DataFrame
            # ---------------------
            dict_df = {"bench_start": start_strf,
                       "bench_end": end_strf,
                       "run_duration [seconds]": t_diff,
                       "func_name": func_name}
            print(kwargs)
            reformed_kwargs = {key:str(value) for key, value in kwargs.items()}
            dict_df.update(reformed_kwargs)
            export_df = pd.DataFrame(dict_df, index=["func_info"]).T

            export_name = f"benchmark__{func_name}__{int(start_time)}.xlsx"

            # create excel workbook
            # ---------------------
            export_df.to_excel(Path(path_out)/export_name)

            return target_func
        return wrapper
    return time_wrapper

