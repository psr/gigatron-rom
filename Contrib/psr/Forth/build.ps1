$ErrorActionPreference = 'Stop';

$dirExcludes = '.venv', '.pytest_cache'
$fileExcludes = 'asm.py', 'dev.py', 'font_v3.py', 'gcl0x.py'
$filesToFormat = get-childitem -Exclude $dirExcludes -Directory | % { get-childitem -path $_ -Recurse -Include '*.py' }
$filesToFormat += get-childitem -Name '*.py' -Exclude $fileExcludes

& 'black' $filesToFormat
if ($LASTEXITCODE -ne 0 ) {
    exit 1;
}


try {
    get-item '.venv' -ErrorAction Stop > $null
} catch {
    py -2 -m virtualenv '.\.venv'
    .\.venv\Scripts\pip install cffi ipython pytest
}


.\.venv\Scripts\python.exe .\gtemu_extension_build.py
if ($LASTEXITCODE -ne 0 ) {
    exit 1;
}

.\.venv\Scripts\python.exe -m pytest
if ($LASTEXITCODE -ne 0 ) {
    exit 1;
}


.\.venv\Scripts\python.exe .\dev.py Main=MainMenu\MainMenu.gcl Reset=Reset.gcl
if ($LASTEXITCODE -ne 0 ) {
    exit 1;
}



'success'
