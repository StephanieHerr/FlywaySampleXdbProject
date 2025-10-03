# List of Flyway project directories (each containing its own flyway.toml)
$root = "C:\Users\stephanie.herr\Documents\FlywaySampleXdbProject"

$projects = @(
    "DB1",
    "DB2",
    "DB3",
    "DB4",
    "DB5"
)

$maxPasses = 5

for ($pass = 1; $pass -le $maxPasses; $pass++) {
    Write-Host "=== Pass $pass of $maxPasses ==="

    $failed = @()
    $path = ""

    foreach ($proj in $projects) {
        $path = $root + "\" +$proj
        $configFile = Join-Path $path "flyway.toml "
        Write-Host "Running Flyway migrate for $proj using $configFile"

        Push-Location $proj
        & flyway migrate -environment=myTarget -configFiles="$configFile"
        $exitCode = $LASTEXITCODE
        Pop-Location

        if ($exitCode -ne 0) {
            Write-Warning "Migration failed for $proj (exit code $exitCode)"
            $failed += $proj
        } else {
            Write-Host "Migration succeeded for $proj"
        }
    }

    if ($failed.Count -eq 0) {
        Write-Host "All migrations succeeded on pass $pass"
        break
    } else {
        Write-Host "$($failed.Count) projects failed this pass."
        if ($pass -eq $maxPasses) {
            Write-Error "Some projects still failed after $maxPasses passes: $($failed -join ', ')"
        } else {
            Write-Host "Retrying failed projects in next pass..."
            $projects = $failed
        }
    }
}