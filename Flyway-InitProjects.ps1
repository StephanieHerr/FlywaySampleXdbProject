# Root folder for all projects
$root = "C:\Users\stephanie.herr\Documents\FlywaySampleXdbProject"

# Database connection info (adjust as needed)
$server   = "localhost"
$instance = "SQLExpress"

# Create DB1 through DB5
1..5 | ForEach-Object {
    $dbName = "DB$_"
    $projPath = Join-Path $root $dbName

    # Ensure folder exists
    if (-not (Test-Path $projPath)) {
        New-Item -ItemType Directory -Path $projPath | Out-Null
        Write-Host "Created folder $projPath"
    }

    # Create a callbacks folder to avoid Flyway warnings
    $callbacksPath = Join-Path $projPath "callbacks"
    if (-not (Test-Path $callbacksPath)) {
        New-Item -ItemType Directory -Path $callbacksPath | Out-Null
        Write-Host "Created folder $callbacksPath"
    }

    Push-Location $projPath

    # Initialize Flyway project (creates flyway.toml if not present)
    & flyway init -projectName="$dbName" -databaseType="sqlserver"
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "flyway init failed for $dbName"
    }

    # Path to the TOML file
    $tomlPath = Join-Path $projPath "flyway.user.toml"

    if (Test-Path $tomlPath) {
        # Add connection settings
        $envLine         = "[environments.myTarget]"
        $urlLine         = "url = `"jdbc:sqlserver://$server;instanceName=$instance;databaseName=$dbName;encrypt=true;integratedSecurity=true;trustServerCertificate=true`""
        $displayNameLine = "displayName = `"myTarget`""

        # Read existing lines
        $lines = Get-Content $tomlPath

        # Add our connection info at the end
        $lines += $envLine + "`n"
        $lines += $urlLine + "`n"
        $lines += $displayNameLine

        # Write back
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllLines($tomlPath, $lines, $utf8NoBom)

        Write-Host "Updated $tomlPath with connection info for $dbName"
    } else {
        Write-Warning "No flyway.user.toml found in $projPath"
    }

    Pop-Location
}