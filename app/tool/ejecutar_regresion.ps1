param([string]$Configuracion='configuracion_pi.local.json',[int]$Puerto=5566)
$ErrorActionPreference='Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$carpeta=Join-Path 'evidencia' ('regresion_'+(Get-Date -Format 'yyyyMMdd_HHmmssfff'))
New-Item -ItemType Directory -Path $carpeta | Out-Null
$carpeta=(Resolve-Path $carpeta).Path
$casos=@(
    @{id='PR-01';modulo='acceso'},@{id='PR-02';modulo='monitoreo'},
    @{id='PR-03';modulo='historico'},@{id='PR-04';modulo='alertas'},
    @{id='PR-05';modulo='soporte'},@{id='PR-06';modulo='acceso'}
)
$driver=$null
$temporal=$null
$codigo=2
$motivo='No se completó la ejecución.'
$previo=$env:BEECARE_REGRESION_EVIDENCIA
function GuardarPendientes($detalle){
    $filas=@('# Regresión BeeCare','','Estado: PENDIENTE. '+$detalle,'',
        '| Caso | Módulo | Resultado |','| --- | --- | --- |')
    foreach($c in $casos){$filas+=('| '+$c.id+' | '+$c.modulo+' | NO_EJECUTADA |')}
    $filas | Set-Content (Join-Path $carpeta 'reporte.md')
}
GuardarPendientes $motivo
try {
    if(!(Test-Path -LiteralPath $Configuracion)){throw 'Falta configuracion_pi.local.json.'}
    $c=Get-Content -LiteralPath $Configuracion -Raw|ConvertFrom-Json
    $campos=@('FIREBASE_API_KEY','FIREBASE_APP_ID','FIREBASE_SENDER_ID',
        'FIREBASE_PROJECT_ID','FIREBASE_DATABASE_URL','FIREBASE_AUTH_DOMAIN',
        'HIVE_ID','DEVICE_ID','PI_CORREO','PI_CLAVE','PI_RESPONSABLE_CORREO',
        'PI_RESPONSABLE_CLAVE','PI_ENSAYO_ID','PI_FECHA_INICIO','PI_FECHA_FIN')
    $faltan=@($campos|Where-Object{![string]$c.$_})
    if($faltan.Count){throw ('Faltan campos: '+($faltan -join ', '))}
    if($c.FIREBASE_ENABLED -ne $true -or $c.PUSH_ENABLED -ne $false){throw 'Usar FIREBASE_ENABLED=true y PUSH_ENABLED=false.'}
    if($c.PI_ENSAYO_ID -ne 'ensayo_01'){throw 'La preparación existente requiere PI_ENSAYO_ID=ensayo_01.'}
    $inicio=[datetime]::ParseExact($c.PI_FECHA_INICIO,'yyyy-MM-dd',$null)
    $fin=[datetime]::ParseExact($c.PI_FECHA_FIN,'yyyy-MM-dd',$null)
    if($fin -lt $inicio -or $fin.Date -gt (Get-Date).Date -or $inicio.Year -lt 2020){throw 'Rango de fechas inválido.'}
    if($inicio.Date -eq (Get-Date).Date -and $fin.Date -eq $inicio.Date){throw 'Usar un rango distinto del filtro inicial de hoy.'}
    $cmd=Get-Command chromedriver -ErrorAction SilentlyContinue
    $bin=if($cmd){$cmd.Source}else{Join-Path $env:USERPROFILE 'Downloads\chromedriver-win64\chromedriver.exe'}
    if(!(Test-Path -LiteralPath $bin)){throw 'No se encontró ChromeDriver en PATH ni Downloads/chromedriver-win64.'}
    $ocupado=Get-NetTCPConnection -LocalPort $Puerto -State Listen -ErrorAction SilentlyContinue
    if($ocupado){throw ('El puerto '+$Puerto+' está ocupado. Usar -Puerto con otro puerto libre.')}
    $commit=(& git -c safe.directory=F:/proyecto_u -C .. rev-parse HEAD 2>$null)
    $archivos=@(Get-ChildItem lib,integration_test,test_driver,tool -Recurse -File |
        Where-Object{$_.Extension -in @('.dart','.ps1')})
    $archivos+=Get-Item pubspec.yaml
    $hashes=@($archivos|Sort-Object FullName|ForEach-Object{
        @{archivo=$_.FullName.Substring((Get-Location).Path.Length+1).Replace('\','/');sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
    })
    @{commit=$commit;version='1.0.0+1';arbol='CON_CAMBIOS_LOCALES';
      referencia='evidencia/integracion_20261107_164216';
      limite='No hay manifiesto de hashes de la referencia; no se atribuyen otros cambios de producto a una fecha.';
      archivos=$hashes} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $carpeta 'version.json')
    $temporal=Join-Path $env:TEMP ('beecare_regresion_'+[guid]::NewGuid().ToString('N')+'.json')
    $c|ConvertTo-Json -Depth 10|Set-Content -LiteralPath $temporal
    $LASTEXITCODE=0
    & (Join-Path $PSScriptRoot 'preparar_alerta.ps1') -Configuracion $temporal
    if($LASTEXITCODE -ne 0){throw 'Falló la preparación de la alerta de ensayo.'}
    $preparado=Get-Content -LiteralPath $temporal -Raw|ConvertFrom-Json
    @{ensayoId=$preparado.PI_ENSAYO_ID;alertaId=$preparado.PI_ALERTA_ID;
      colmena=$preparado.HIVE_ID;prototipo=$preparado.DEVICE_ID;
      inicio=$preparado.PI_FECHA_INICIO;fin=$preparado.PI_FECHA_FIN;
      nota='Alerta nueva exclusiva; no se sobrescribe la configuración de integración. Roles, datos e indicador sin leer se comprueban con Firebase desde los recorridos.'} |
        ConvertTo-Json|Set-Content (Join-Path $carpeta 'preparacion.json')
    $env:BEECARE_REGRESION_EVIDENCIA=$carpeta
    $driver=Start-Process $bin -ArgumentList "--port=$Puerto" -WindowStyle Hidden -PassThru
    $listo=$false
    for($i=0;$i -lt 30;$i++){
        try{$null=Invoke-RestMethod "http://localhost:$Puerto/status" -TimeoutSec 2;$listo=$true;break}
        catch{Start-Sleep -Milliseconds 200}
    }
    if(!$listo){throw 'ChromeDriver no respondió.'}
    & flutter drive -d web-server --browser-name=chrome "--driver-port=$Puerto" `
        --no-headless --no-web-resources-cdn `
        --driver=test_driver/regresion.dart `
        --target=integration_test/regresion_test.dart `
        "--dart-define-from-file=$temporal" 2>&1 |
        Tee-Object (Join-Path $carpeta 'ejecucion.log')
    $codigo=$LASTEXITCODE
    # El driver puede devolver cero aunque haya fallos; exigir evidencia de los seis casos.
    $rutaCasos=Join-Path $carpeta 'casos.json'
    if(Test-Path -LiteralPath $rutaCasos){
        $registrados=(Get-Content -LiteralPath $rutaCasos -Raw|ConvertFrom-Json).casos
        foreach($esperado in $casos){
            if($registrados.($esperado.id).estado -ne 'APROBADA'){$codigo=1}
        }
    } else {$codigo=1}
    $motivo=if($codigo -eq 0){'Ejecución completa aprobada.'}else{'Revisar casos.json y ejecucion.log; no se aprueban casos sin evidencia.'}
} catch {
    $motivo='Preparación o ejecución interrumpida: '+$_.Exception.GetType().Name
    Write-Output $motivo
    # Sólo mensajes controlados del script; no imprimir excepciones HTTP con tokens.
    if($_.Exception -is [System.Management.Automation.RuntimeException] -and $_.Exception.Message -notmatch 'https?://|auth=|password'){
        $motivo=$_.Exception.Message;Write-Output $motivo
    }
} finally {
    if($driver -and !$driver.HasExited){Stop-Process -Id $driver.Id}
    if($temporal -and (Test-Path -LiteralPath $temporal)){Remove-Item -LiteralPath $temporal}
    $env:BEECARE_REGRESION_EVIDENCIA=$previo
    $estado=if($codigo -eq 0){'APROBADA'}elseif($codigo -eq 2){'PENDIENTE'}else{'FALLIDA'}
    @{suite='regresion';estado=$estado;codigo=$codigo;motivo=$motivo;
      fechaUtc=[datetime]::UtcNow.ToString('o')}|ConvertTo-Json|Set-Content (Join-Path $carpeta 'resultado.json')
    if(!(Test-Path (Join-Path $carpeta 'casos.json'))){GuardarPendientes $motivo}
    Write-Output ('Evidencia de regresión: '+$carpeta)
}
exit $codigo
