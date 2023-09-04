$ErrorActionPreference = "Stop"

$failed_count = 0
$tests = Get-ChildItem -Path test -Filter "test-*.lua"

if ($args.Length -eq 1) {
    $tests = @($args[0])
}

foreach ($t in $tests) {
    Write-Output "SUITE START  $t..."
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $randomNumber = Get-Random -Minimum 1 -Maximum 999
    $env:NVIM_APPNAME = "${randomNumber}_${timestamp}"
    $env:NVIM_BIN = "c:\tools\neovim\nvim-win64\bin\nvim"
    c:\tools\neovim\nvim-win64\bin\nvim +"set columns=1000" -l $t.FullName
    if ($LastExitCode -ne 0) {
        Write-Output "SUITE FAILED $t"
        $failed_count = 1
    }
    else {
        Write-Output "SUITE PASSED $t"
    }
    Write-Output ""
}

if ($failed_count -ne 0) {
    Write-Output "SOME TESTS FAILED"
}
else {
    Write-Output "ALL TESTS PASSED"
}

exit $failed_count

