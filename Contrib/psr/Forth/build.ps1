$ErrorActionPreference = 'Stop';

try {
    get-item '.venv' -ErrorAction Stop > $null
} catch {
    py -2 -m virtualenv '.\.venv'
}

.\.venv\Scripts\pip install cffi ipython

.\.venv\Scripts\python.exe .\dev.py Main=MainMenu\MainMenu.gcl Reset=Reset.gcl
if ($LASTEXITCODE -ne 0 ) {
    exit 1;
}
'success'