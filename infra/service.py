import pathlib
from sanic import Sanic
from sanic.response import json
from src.sftp_downloader import download_files, download_files_local
from src.data_processor import validate_and_clean

app = Sanic("DataPipelineService")

@app.route("/fetch_data", methods=['GET'])
async def fetch_and_prepare_data(request):
    data_storage = pathlib.Path(__file__).parent / "redydata_storage"
    local_filepath = pathlib.Path(__file__).parent / "downloaded_data"
    # Download CSV files from SFTP
    downloaded_files = download_files_local()
    results = []

    # Process each file
    for file in downloaded_files:
        result = validate_and_clean(file)
        if result:
            pathlib.Path(local_filepath.joinpath(result)).unlink()
            pathlib.Path(data_storage.joinpath(result)).unlink()
            print(f"Done and Removed {result}")
        results.append(result)

    return json({"message": "Data fetching and processing complete", "files_processed": results})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5050)