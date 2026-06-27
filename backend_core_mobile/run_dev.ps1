# run_dev.ps1
& venv\Scripts\uvicorn.exe app.main:app --reload --host 0.0.0.0 --port 8003
