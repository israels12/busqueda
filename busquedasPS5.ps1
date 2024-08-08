# Función para descomprimir archivos .zip
function Extract_Zip {
    param (
        [string]$zipFile,
        [string]$destination
    )
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, $destination)
}

# Función para descomprimir archivos .rar
function Extract_Rar {
    param (
        [string]$rarFile,
        [string]$destination
    )
    $sevenZipPath = "C:\Program Files\7-Zip\7z.exe" # Cambia esto si `7z.exe` está en otra ubicación

    # Crear el directorio de destino si no existe
    if (-not (Test-Path -Path $destination)) {
        New-Item -ItemType Directory -Path $destination
    }

    Write-Host "Descomprimiendo $rarFile en $destination"
    & $sevenZipPath x $rarFile -o"$destination" -y | Write-Host
}

# Verificar e instalar 7-Zip si no está presente
$sevenZipPath = "C:\Program Files\7-Zip\7z.exe"

if (-not (Test-Path $sevenZipPath)) {
    Write-Host "7-Zip no está instalado. Instalando 7-Zip..."

    # Descargar el instalador de 7-Zip
    $downloadUrl = "https://www.7-zip.org/a/7z1900-x64.exe"
    $installerPath = "$env:TEMP\7z1900-x64.exe"

    Write-Host "Descargando 7-Zip desde $downloadUrl..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath

    # Instalar 7-Zip silenciosamente
    Write-Host "Instalando 7-Zip..."
    Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait

    # Verificar la instalación
    if (Test-Path $sevenZipPath) {
        Write-Host "7-Zip se ha instalado correctamente."
    } else {
        Write-Host "La instalacion de 7-Zip ha fallado."
        exit
    }
}

# Solicitar la ruta absoluta al usuario
$path = Read-Host "Ingrese la ruta absoluta (por ejemplo, C:\Users\Usuario\Documentos)"
$path = [System.IO.Path]::GetFullPath($path)

# Preguntar si se desea descomprimir archivos .rar o .zip
$decompress = Read-Host "Desea descomprimir archivos (.rar o .zip) en esta ruta? (s/n)"
if ($decompress -eq 's') {
    $pattern = Read-Host "Ingrese el patron de archivo (por ejemplo, *.rar, *.zip)"
    $files = Get-ChildItem -Path $path -Filter $pattern -Recurse

    foreach ($file in $files) {
        $archivePath = $file.FullName
        $extension = [System.IO.Path]::GetExtension($archivePath).ToLower()
        if ($extension -eq '.zip') {
            Extract_Zip -zipFile $archivePath -destination $path
            Write-Host "Archivo .zip descomprimido en $path"
        } elseif ($extension -eq '.rar') {
            Extract_Rar -rarFile $archivePath -destination $path
            Write-Host "Archivo .rar descomprimido en $path"
        } else {
            Write-Host "Formato de archivo no soportado. Solo se soportan .rar y .zip." -ForegroundColor Red
        }
    }

    # Mostrar archivos descomprimidos
    $extractedFiles = Get-ChildItem -Path $path
    Write-Host "Archivos descomprimidos en $path :" -ForegroundColor Green
    $extractedFiles | ForEach-Object { Write-Host $_.FullName }
}

# Solicitar el tipo de archivo que desea buscar
$fileType = Read-Host "Ingrese el tipo de archivo a buscar (por ejemplo, *.txt, *.log, etc.)"

# Solicitar la cantidad de palabras que desea buscar
$wordCount = Read-Host "Ingrese la cantidad de palabras que desea buscar"

# Inicializar un array para almacenar las palabras
$patterns = @()

# Solicitar las palabras al usuario
for ($i = 1; $i -le [int]$wordCount; $i++) {
    $word = Read-Host "Ingrese la palabra $i"
    $patterns += $word
}

# Mostrar las palabras ingresadas para confirmar
Write-Host "Buscando las siguientes palabras:" -ForegroundColor Green
$patterns | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }

# Ejecutar la búsqueda con las palabras ingresadas
$results = Get-ChildItem -Path $path -Filter $fileType -Recurse | Select-String -Pattern $patterns

# Resaltar las palabras encontradas
foreach ($result in $results) {
    $line = $result.Line
    foreach ($pattern in $patterns) {
        if ($line -match [regex]::Escape($pattern)) {
            $highlighted = $line -replace [regex]::Escape($pattern), "[31m$pattern[0m"
            Write-Host "$($result.Path): " -ForegroundColor Green
            Write-Host "$highlighted"
        }
    }
}
