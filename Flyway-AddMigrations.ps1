# Root folder for all projects
$root = "C:\Users\stephanie.herr\Documents\FlywaySampleXdbProject"

# Loop through DB1–DB5
1..5 | ForEach-Object {
    $dbName = "DB$_"
    $projPath = Join-Path $root $dbName
    $migrationsPath = Join-Path $projPath "migrations"

    Push-Location $projPath

    # Create a new migration with flyway add
    & flyway add -description="init_$dbName"
    if ($LASTEXITCODE -eq 0) {
        # Find the most recent migration file
        $latestFile = Get-ChildItem $migrationsPath -Filter "V*.sql" |
                      Sort-Object LastWriteTime -Descending |
                      Select-Object -First 1

        if ($latestFile) {
            $content = @"
-- Migration script for $dbName
-- Creates a sample table and a stored procedure that selects from it

CREATE TABLE ${dbName}_Sample (
    Id INT PRIMARY KEY,
    Name NVARCHAR(100)
);
GO

CREATE OR ALTER PROCEDURE ${dbName}_GetSamples
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Name FROM ${dbName}_Sample;
END;
GO
"@
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($latestFile.FullName, $content, $utf8NoBom)
            Write-Host "Updated $($latestFile.Name) in $dbName with table + proc"
        }
    } else {
        Write-Warning "flyway add failed for $dbName"
    }

    # Special case: DB2 gets an extra migration depending on DB4
    if ($dbName -eq "DB2") {
        & flyway add -description="depends_on_DB4"
        if ($LASTEXITCODE -eq 0) {
            $latestFile = Get-ChildItem $migrationsPath -Filter "V*.sql" |
                          Sort-Object LastWriteTime -Descending |
                          Select-Object -First 1
            if ($latestFile) {
                $depContent = @"
-- Migration script for DB2 that depends on an object in DB4
-- Example: create a view that selects from DB4's sample table

CREATE OR ALTER VIEW DB2_View_Using_DB4
AS
SELECT Id, Name
FROM DB4.dbo.DB4_Sample;
GO
"@
                $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
                [System.IO.File]::WriteAllText($latestFile.FullName, $depContent, $utf8NoBom)
                Write-Host "Updated $($latestFile.Name) in DB2 with dependency on DB4"
            }
        }
    }

    Pop-Location
}