#!/bin/bash

TARGET_DIR="/home/vboxuser/Desktop"

# Leer todos los archivos encriptados
encrypted_files=($(find "$TARGET_DIR" -name "*.encrypted"))

if [ ${#encrypted_files[@]} -eq 0 ]; then
    echo "No se encontraron archivos .encrypted para recuperar."
    exit 1
fi

echo "Archivos encriptados encontrados: ${#encrypted_files[@]}"

echo ""
read -p "Ingrese la clave de desencriptación: " key

if [ -z "$key" ]; then
    echo "Error: No se ingresó ninguna clave."
    exit 1
fi

success_count=0
fail_count=0

for encrypted_file in "${encrypted_files[@]}"; do
    original_name="${encrypted_file%.encrypted}"
   
    echo "Desencriptando: $(basename "$encrypted_file")"
   
    # Extraer IV (primera línea)
    iv=$(head -n 1 "$encrypted_file")
   
    # Crear archivo temporal sin el IV
    temp_encrypted=$(mktemp)
    tail -n +2 "$encrypted_file" > "$temp_encrypted"
   
    # Desencriptar usando el mismo IV
    if openssl enc -aes-256-cbc -d -salt -in "$temp_encrypted" -out "$original_name" -K "$key" -iv "$iv" -pbkdf2 -iter 10000 2>/dev/null; then

        if [ -f "$original_name" ]; then
            rm -f "$encrypted_file" "$temp_encrypted"
            echo "  OK: $(basename "$original_name")"
            success_count=$((success_count + 1))
        else
            echo "  ERROR: No se pudo crear $original_name"
            rm -f "$original_name" "$temp_encrypted"
            fail_count=$((fail_count + 1))
        fi
    else
        echo "  ERROR: Fallo desencriptación - posible clave incorrecta"
        rm -f "$original_name" "$temp_encrypted"
        fail_count=$((fail_count + 1))
    fi
done

echo ""
echo "RESUMEN:"
echo "  Archivos recuperados: $success_count"
echo "  Archivos con error: $fail_count"

if [ $fail_count -gt 0 ]; then
    echo ""
    echo "Nota: Algunos archivos pueden haber estado vacíos o tener problemas de permisos."
fi


