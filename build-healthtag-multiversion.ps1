$ErrorActionPreference = "Stop"

function Get-ShortPath([string]$Path) {
    $fso = New-Object -ComObject Scripting.FileSystemObject
    if (Test-Path -LiteralPath $Path -PathType Container) {
        return $fso.GetFolder($Path).ShortPath
    }
    return $fso.GetFile($Path).ShortPath
}

$root = (Get-Location).ProviderPath
$helthtag = Join-Path $root "helthtag"
$output = Join-Path ([Environment]::GetFolderPath("Desktop")) "multiversion"
$java = "C:\Users\kil\.jdks\jdk-25.0.4+7\bin\java.exe"
$gradleJar = Join-Path $root "gradle\wrapper\gradle-wrapper.jar"
$helthtagModernBuild = Join-Path $helthtag "build-1.21.11.gradle"
$helthtagGradlePath = Get-ShortPath $helthtag
$gradleJarPath = Get-ShortPath $gradleJar
$resourceOutput = Join-Path $root "src\main\resources\multiversion"

$targets = @(
    @{ Minecraft = "26.2";    Api = "0.158.0+26.2" },
    @{ Minecraft = "26.1.2";  Api = "0.155.2+26.1.2" },
    @{ Minecraft = "26.1.1";  Api = "0.145.4+26.1.1" },
    @{ Minecraft = "26.1";    Api = "0.145.1+26.1" },
    @{ Minecraft = "1.21.11"; Api = "0.141.6+1.21.11" }
)

New-Item -ItemType Directory -Force -Path $output | Out-Null
New-Item -ItemType Directory -Force -Path $resourceOutput | Out-Null
Get-ChildItem -LiteralPath $output -Filter "helthtag-*.jar" -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem -LiteralPath $resourceOutput -Filter "helthtag-*.jar" -ErrorAction SilentlyContinue | Remove-Item -Force

foreach ($target in $targets) {
    $mc = $target.Minecraft
    $safeMc = $mc.Replace(".", "_")
    $buildDir = Join-Path $env:TEMP "kriptonite-helthtag-$safeMc"
    $gradleTask = if ($mc.StartsWith("1.")) { "remapJar" } else { "jar" }
    $projectPath = $helthtagGradlePath

    if ($mc.StartsWith("1.")) {
        $modernProject = Join-Path $env:TEMP "kriptonite-helthtag-$safeMc-project"
        if (Test-Path -LiteralPath $modernProject) {
            Remove-Item -LiteralPath $modernProject -Recurse -Force
        }

        New-Item -ItemType Directory -Force -Path $modernProject | Out-Null
        Copy-Item -LiteralPath (Join-Path $helthtag "src") -Destination $modernProject -Recurse
        Copy-Item -LiteralPath (Join-Path $helthtag "settings.gradle") -Destination (Join-Path $modernProject "settings.gradle")
        Copy-Item -LiteralPath (Join-Path $helthtag "gradle.properties") -Destination (Join-Path $modernProject "gradle.properties")
        Copy-Item -LiteralPath $helthtagModernBuild -Destination (Join-Path $modernProject "build.gradle")
        $projectPath = Get-ShortPath $modernProject
    }

    $gradleArgs = @(
        "-Dorg.gradle.appname=gradlew",
        "-Dorg.gradle.problems.report=false",
        "-jar", $gradleJarPath,
        "-p", $projectPath
    )

    $gradleArgs += @(
        $gradleTask,
        "-Pminecraft_version=$mc",
        "-Ploader_version=0.19.3",
        "-Pjava_version=21",
        "-Pfabric_api_version=$($target.Api)",
        "-Parchives_base_name=helthtag-$mc",
        "-Pcustom_build_dir=$buildDir"
    )

    Write-Host "Building Health Tag for Minecraft $mc..."

    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
    }

    & $java @gradleArgs

    if ($LASTEXITCODE -ne 0) {
        throw "Build failed for Minecraft $mc"
    }

    $jar = Get-ChildItem -LiteralPath (Join-Path $buildDir "libs") -Filter "*.jar" |
        Where-Object { $_.Name -notmatch "sources|dev|all" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -eq $jar) {
        throw "No jar found for Minecraft $mc"
    }

    $dest = Join-Path $output ("helthtag-$mc-1.0.0.jar")
    $resourceDest = Join-Path $resourceOutput ("helthtag-$mc-1.0.0.jar")
    Copy-Item -LiteralPath $jar.FullName -Destination $dest -Force
    Copy-Item -LiteralPath $jar.FullName -Destination $resourceDest -Force
}

Write-Host "SUCCESS: Health Tag multiversion jars copied to $output and $resourceOutput"
