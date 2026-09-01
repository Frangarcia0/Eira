# Verificación estática completa del proyecto EIRA.
#
# Ejecuta el verificador de reglas estructurales (E1-E7 y prohibición de red) y
# después flutter analyze. Se detiene en el primer fallo.
#
# El verificador no puede colgarse de flutter analyze: ese comando no admite
# pre-pasos ni plugins sin dependencias. Ver docs/decisions/ADR-007.
#
# Uso, desde la raíz del proyecto:
#   .\tool\verify.ps1

$ErrorActionPreference = 'Stop'

Write-Host '== Reglas estructurales E1-E7 ==' -ForegroundColor Cyan
dart run tool/check_architecture.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'Verificación detenida: hay violaciones estructurales.' -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ''
Write-Host '== Análisis estático ==' -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'Verificación detenida: flutter analyze reportó problemas.' -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ''
Write-Host 'Verificación completa: sin violaciones estructurales y análisis limpio.' -ForegroundColor Green
exit 0
