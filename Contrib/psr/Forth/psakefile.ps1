$ErrorActionPreference = 'Stop';

$dirExcludes = '.venv', '.pytest_cache'
$fileExcludes = 'asm.py', 'dev.py', 'font_vX.py', 'gcl0x.py'
$filesToFormat = get-childitem -Exclude $dirExcludes -Directory | % { get-childitem -path $_ -Recurse -Include '*.py' }
$filesToFormat += get-childitem -Name '*.py' -Exclude $fileExcludes

task default -depends Blacken, Test, ROM

task Blacken {
    & 'black' $filesToFormat
    if ($LASTEXITCODE -ne 0 ) {
        throw "Black failed";
    }
}

task Test {
    .\.venv\Scripts\pytest
    if ($LASTEXITCODE -ne 0 ) {
        throw "Test failure";
    }
}

task Virtualenv {
    try {
        get-item '.venv' -ErrorAction Stop > $null
    }
    catch {
        python3 -m venv '.\.venv'
    }
}

task Packages -depends Virtualenv {
    .\.venv\Scripts\pip install cffi ipython pytest hypothesis
    if ($LASTEXITCODE -ne 0 ) {
        throw "Packages failed"
    }
}

task Extension -depends Packages {
    .\.venv\Scripts\python.exe .\gtemu_extension_build.py
    if ($LASTEXITCODE -ne 0 ) {
        throw "Extension failed"
    }
}


task ROM {
    .\.venv\Scripts\python.exe .\dev.py Main=MainMenu\MainMenu.gcl Reset=Reset.gcl
    if ($LASTEXITCODE -ne 0 ) {
        throw "Rom failed";
    }
}
