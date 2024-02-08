
import pysftp
import os
from .settings import SFTP_CONFIG
import pathlib
data_storage = pathlib.Path(__file__).parent.parent / "data_storage"
local_filepath = pathlib.Path(__file__).parent.parent / "downloaded_data"
pathlib.Path(local_filepath).mkdir(mode=0o777, parents=False, exist_ok=True)
def download_files(sftp_details=SFTP_CONFIG):
#     cnopts = pysftp.CnOpts()
#     cnopts.hostkeys = None  # Not recommended for production
    files = []
#     with pysftp.Connection(**sftp_details, cnopts=cnopts) as sftp:
#         sftp.chdir('data/')  # Target directory
#         files = sftp.listdir()
#
#         for file in files:
#             if file.endswith('.csv'):
#                 local_filepath = os.path.join('downloaded_data', file)
#                 sftp.get(file, local_filepath)
#                 print(f"Downloaded {file}")
#
    return files


def download_files_local():
    files = []
    for file_name in data_storage.iterdir():
        print(file_name)
        if file_name.with_suffix('.csv'):

            local_file = pathlib.Path(local_filepath).joinpath(file_name.name)

            with file_name.open('r') as f:
                with local_file.open('w') as wf:
                    wf.write(f.read())
                    print(f"Downloaded {file_name}")
                    files.append(file_name)
    return files