param([string]$Configuracion='configuracion_pi.local.json')
$ErrorActionPreference='Stop'
$app=Split-Path $PSScriptRoot -Parent
$c=Get-Content $Configuracion -Raw | ConvertFrom-Json
$firmware=Get-Content (Join-Path (Split-Path $app -Parent) 'firware\config.py') -Raw
function Valor($nombre) {
    $patron='(?m)^'+$nombre+'\s*=\s*["'']([^"'']+)["'']'
    $m=[regex]::Match($firmware,$patron)
    if (!$m.Success) { throw ('Falta configuración local: '+$nombre) }
    return $m.Groups[1].Value
}
try {
    $auth=Invoke-RestMethod ('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key='+(Valor 'FIREBASE_API_KEY')) -Method Post -ContentType 'application/json' -Body (@{email=(Valor 'FIREBASE_EMAIL');password=(Valor 'FIREBASE_PASSWORD');returnSecureToken=$true}|ConvertTo-Json) -TimeoutSec 30
    $id='ensayo_alerta_'+[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $dato=@{ensayoId=$c.PI_ENSAYO_ID;categoria='sensor';descripcion=('ENSAYO_ALERTA '+$id);fechaHora=[DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ');nivel='AVISO';sensorId='S3';tipoAlerta='FALLO_SENSOR';elegiblePush=$false;leida=$false}
    if($c.PI_ENSAYO_ID -ne 'ensayo_01') {throw 'Revisar identificador de ensayo'}
    $url=$c.FIREBASE_DATABASE_URL.TrimEnd('/')+'/alertas/'+$c.HIVE_ID+'/'+$id+'.json?auth='+$auth.idToken
    $null=Invoke-RestMethod $url -Method Put -ContentType 'application/json' -Body ($dato|ConvertTo-Json) -TimeoutSec 30
    $c | Add-Member -NotePropertyName PI_ALERTA_ID -NotePropertyValue $id -Force
    $c|ConvertTo-Json -Depth 10|Set-Content $Configuracion
    Write-Output ('Alerta de ensayo preparada: '+$id)
} catch {
    Write-Output 'No se pudo preparar la alerta de ensayo con las credenciales del dispositivo y las reglas actuales. No se muestran detalles que puedan incluir tokens.'
    exit 1
} finally { $auth=$null; $url=$null }

# Resultado explicito para el ejecutor, independiente de comandos anteriores.
exit 0
