param([string]$Configuracion = 'configuracion_pi.local.json')
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$carpeta = Join-Path 'evidencia' ('integracion_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
New-Item -ItemType Directory -Path $carpeta -Force | Out-Null
$salida = Join-Path $carpeta 'resultado.json'
function Pendiente($motivo) {
    @{estado='PENDIENTE'; motivo=$motivo; fecha=(Get-Date).ToString('o')} |
        ConvertTo-Json | Set-Content $salida
    Write-Output $motivo
    exit 2
}
if (!(Test-Path -LiteralPath $Configuracion)) {
    Pendiente 'Falta configuracion_pi.local.json. Copiar configuración Firebase local y completar cuentas y registros de ensayo según PRUEBAS_REALES.md.'
}
$c = Get-Content -LiteralPath $Configuracion -Raw | ConvertFrom-Json
$campos = @('FIREBASE_API_KEY','FIREBASE_APP_ID','FIREBASE_SENDER_ID','FIREBASE_PROJECT_ID',
    'FIREBASE_DATABASE_URL','FIREBASE_AUTH_DOMAIN','HIVE_ID','DEVICE_ID',
    'PI_CORREO','PI_CLAVE','PI_RESPONSABLE_CORREO','PI_RESPONSABLE_CLAVE',
    'PI_ENSAYO_ID','PI_ALERTA_ID','PI_EVENTO_ID','PI_FECHA_INICIO','PI_FECHA_FIN')
$faltan = @($campos | Where-Object { !($c.$_) })
if ($faltan.Count) { Pendiente ('Faltan campos: ' + ($faltan -join ', ')) }
if ($c.FIREBASE_ENABLED -ne $true -or $c.PUSH_ENABLED -ne $false) {
    Pendiente 'Se requiere FIREBASE_ENABLED=true y PUSH_ENABLED=false.'
}
if (!$c.PI_ENSAYO_ID.StartsWith('ensayo_') -or !$c.PI_ALERTA_ID.StartsWith('ensayo_')) {
    Pendiente 'PI_ENSAYO_ID y PI_ALERTA_ID deben comenzar por ensayo_.'
}
$comando=Get-Command chromedriver -ErrorAction SilentlyContinue
$chromeDriver=if($comando){$comando.Source}else{'C:\Users\Bernardo\Downloads\chromedriver-win64\chromedriver.exe'}
if (!(Test-Path -LiteralPath $chromeDriver)) { Pendiente 'Falta chromedriver.exe en PATH o Downloads/chromedriver-win64.' }
& (Join-Path $PSScriptRoot 'preparar_alerta.ps1') -Configuracion $Configuracion
if($LASTEXITCODE -ne 0){ Pendiente 'No se pudo preparar una alerta nueva de ensayo.' }
$env:BEECARE_EVIDENCIA = (Resolve-Path $carpeta).Path
$driver = $null
try {
    $driver = Start-Process $chromeDriver -ArgumentList '--port=5555' -WindowStyle Hidden -PassThru
    $listo = $false
    for ($i=0; $i -lt 30; $i++) {
        try { $null = Invoke-RestMethod http://localhost:5555/status; $listo=$true; break }
        catch { Start-Sleep -Milliseconds 200 }
    }
    if (!$listo) { throw 'ChromeDriver no disponible en puerto 5555' }
    & flutter drive -d web-server --browser-name=chrome --driver-port=5555 --no-headless --no-web-resources-cdn --driver=test_driver/integration_test.dart `
        --target=integration_test/beecare_test.dart "--dart-define-from-file=$Configuracion" 2>&1 |
        Tee-Object (Join-Path $carpeta 'ejecucion.log')
    $codigo = $LASTEXITCODE
    @{estado=$(if ($codigo -eq 0) {'APROBADA'} else {'FALLIDA'}); codigo=$codigo;
        fecha=(Get-Date).ToString('o')} | ConvertTo-Json | Set-Content $salida
    exit $codigo
} finally {
    if ($driver -and !$driver.HasExited) { Stop-Process -Id $driver.Id }
    Remove-Item Env:\BEECARE_EVIDENCIA -ErrorAction SilentlyContinue
}
