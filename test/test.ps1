$ErrorActionPreference = "Stop"

$failed_count = 0
$tests = @("require-a-fnl-file", "cache-invalidation", "dot-hotpot", "api-make")

if ($args.Length -eq 1) {
    $tests = @($args[0])
}

foreach ($t in $tests) {
    Write-Output "SUITE START  $t..."
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $randomNumber = Get-Random -Minimum 1 -Maximum 99
    $env:NVIM_APPNAME = "${timestamp}_${randomNumber}"
    c:\tools\neovim\nvim-win64\bin\nvim +"set columns=1000" -l "test/${t}.lua"
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

