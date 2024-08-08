#!/bin/bash

# Función para descomprimir archivos .zip
extract_zip() {
    local zip_file=$1
    local destination=$2
    unzip -q "$zip_file" -d "$destination"
}

# Función para descomprimir archivos .rar
extract_rar() {
    local rar_file=$1
    local destination=$2
    local seven_zip_path="/usr/bin/7z" # Cambia esto si `7z` está en otra ubicación

    # Crear el directorio de destino si no existe
    if [ ! -d "$destination" ]; then
        mkdir -p "$destination"
    fi

    echo "Descomprimiendo $rar_file en $destination"
    "$seven_zip_path" x "$rar_file" -o"$destination" -y > /dev/null
}

# Verificar e instalar 7-Zip si no está presente
seven_zip_path="/usr/bin/7z"

if [ ! -f "$seven_zip_path" ]; then
    echo "7-Zip no está instalado. Instalando 7-Zip..."
    sudo apt-get update
    sudo apt-get install -y p7zip-full
fi

# Solicitar la ruta absoluta al usuario
read -p "Ingrese la ruta absoluta (por ejemplo, /ruta/absoluta): " path
path=$(realpath "$path")

# Preguntar si se desea descomprimir archivos .rar o .zip
read -p "Desea descomprimir archivos (.rar o .zip) en esta ruta? (s/n): " decompress
if [ "$decompress" = "s" ]; then
    read -p "Ingrese el patrón de archivo (por ejemplo, *.rar, *.zip): " pattern
    files=$(find "$path" -type f -name "$pattern")

    for file in $files; do
        extension="${file##*.}"
        if [ "$extension" = "zip" ]; then
            extract_zip "$file" "$path"
            echo "Archivo .zip descomprimido en $path"
        elif [ "$extension" = "rar" ]; then
            extract_rar "$file" "$path"
            echo "Archivo .rar descomprimido en $path"
        else
            echo "Formato de archivo no soportado. Sólo se soportan .rar y .zip."
        fi
    done

    # Mostrar archivos descomprimidos
    echo "Archivos descomprimidos en $path:"
    ls -l "$path"
fi

# Solicitar el tipo de archivo que desea buscar
read -p "Ingrese el tipo de archivo a buscar (por ejemplo, *.txt, *.log, etc.): " file_type

# Solicitar la cantidad de palabras que desea buscar
read -p "Ingrese la cantidad de palabras que desea buscar: " word_count

# Inicializar un array para almacenar las palabras
patterns=()

# Solicitar las palabras al usuario
for ((i = 1; i <= word_count; i++)); do
    read -p "Ingrese la palabra $i: " word
    patterns+=("$word")
done

# Mostrar las palabras ingresadas para confirmar
echo -e "\e[32mBuscando las siguientes palabras:\e[0m"
for pattern in "${patterns[@]}"; do
    echo -e "\e[33m$pattern\e[0m"
done

# Unir los patrones en una expresión regular separada por |
joined_patterns=$(IFS="|"; echo "${patterns[*]}")

# Ejecutar la búsqueda con las palabras ingresadas
find "$path" -type f -name "$file_type" -print0 | xargs -0 grep -E "$joined_patterns" | while IFS= read -r line; do
    for pattern in "${patterns[@]}"; do
        if [[ "$line" == *"$pattern"* ]]; then
            highlighted_line=$(echo "$line" | sed "s/$pattern/$(printf '\033[31m')$pattern$(printf '\033[0m')/g")
            echo  "$highlighted_line"
        fi
    done
done
