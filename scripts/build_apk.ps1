$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Push-Location $projectRoot

try {
    # Ensure flutter is available even when PATH is not configured in the current shell.
    $flutter = Get-Command flutter -ErrorAction SilentlyContinue
    if (-not $flutter) {
        $localFlutter = Join-Path $env:USERPROFILE "flutter\\bin"
        $localFlutterBat = Join-Path $localFlutter "flutter.bat"
        if (Test-Path $localFlutterBat) {
            $env:Path += ";$localFlutter"
        }
        else {
            throw "Flutter nao encontrado no PATH e nem em $localFlutterBat"
        }
    }

    # Restore Android wrapper files when they were removed by cleanup.
    if (-not (Test-Path "android/gradlew") -or -not (Test-Path "android/gradle/wrapper/gradle-wrapper.jar")) {
        flutter create .
    }

    flutter pub get
    flutter build apk --release

    Write-Host "APK gerado em: build/app/outputs/flutter-apk/app-release.apk"
}
finally {
    Pop-Location
}
