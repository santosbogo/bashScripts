#!/bin/bash
# Este script se ejecuta con Bash.

# Function to encrypt a file
encrypt_file() {
    # Función para encriptar un archivo.
    if [ $# -ne 3 ]; then
        # Verifica si se pasaron exactamente 3 argumentos a la función.
        echo "Usage: $0 encrypt <recipient_public_key> <input_file> <output_file>"
        exit 1
        # Si no, muestra cómo usar la función y sale del script.
    fi

    # Asignación de argumentos a variables locales para mejor claridad.
    recipient_public_key="$1"
    input_file="$2"
    output_file="$3"

    # Verifica si el archivo de clave pública existe.
    if [ ! -f "$recipient_public_key" ]; then
        echo "Error: Recipient's public key file '$recipient_public_key' does not exist."
        exit 1
    fi

    # Verifica si el archivo de entrada existe.
    if [ ! -f "$input_file" ]; then
        echo "Error: Input file '$input_file' does not exist."
        exit 1
    fi

    # Utiliza OpenSSL para encriptar el archivo.
    openssl rsautl -encrypt -pubin -inkey "$recipient_public_key" -in "$input_file" -out "$output_file"
    echo "File '$input_file' encrypted with recipient's public key and saved as '$output_file'."
}

# Function to decrypt a file
decrypt_file() {
    # Función para desencriptar un archivo.
    if [ $# -ne 3 ]; then
        # Verifica si se pasaron exactamente 3 argumentos a la función.
        echo "Usage: $0 decrypt <recipient_private_key> <input_file> <output_file>"
        exit 1
    fi

    # Asignación de argumentos a variables locales.
    recipient_private_key="$1"
    input_file="$2"
    output_file="$3"

    # Verifica si el usuario tiene permisos de root.
    if [ "$EUID" -ne 0 ]; then
        echo "Error: Permission denied. You must run this command as root."
        exit 1
    fi

    # Verifica si el archivo de clave privada existe.
    if [ ! -f "$recipient_private_key" ]; then
        echo "Error: Recipient's private key file '$recipient_private_key' does not exist."
        exit 1
    fi

    # Verifica si el archivo de entrada existe.
    if [ ! -f "$input_file" ]; then
        echo "Error: Input file '$input_file' does not exist."
        exit 1
    fi

    # Utiliza OpenSSL para desencriptar el archivo.
    openssl rsautl -decrypt -inkey "$recipient_private_key" -in "$input_file" -out "$output_file"
    echo "File '$input_file' decrypted with recipient's private key and saved as '$output_file'."
}

# Function to generate RSA key pair
generate_keys() {
    # Función para generar un par de claves RSA.
    if [ $# -ne 1 ]; then
        # Verifica si se pasó exactamente 1 argumento a la función.
        echo "Usage: $0 generate <filename>"
        exit 1
    fi

    # Asignación del argumento a una variable local.
    filename="$1"
    public_key_file="${filename}_pub.pem"
    private_key_file="${filename}_priv.pem"

    # Verifica si los archivos de clave ya existen.
    if [ -e "$public_key_file" ] || [ -e "$private_key_file" ]; then
        echo "Error: Key files already exist for '$filename'."
        exit 1
    fi

    # Utiliza OpenSSL para generar el par de claves RSA.
    openssl genpkey -algorithm RSA -out "$private_key_file"
    openssl rsa -pubout -in "$private_key_file" -out "$public_key_file"
    echo "RSA key pair generated and saved as '$public_key_file' and '$private_key_file'."
}

# Help function
print_help() {
    # Función para imprimir la ayuda del script.
    echo "Usage: $0 <command>"
    echo "Commands:"
    echo "  encrypt <recipient_public_key> <input_file> <output_file> - Encrypt a file."
    echo "  decrypt <recipient_private_key> <input_file> <output_file> - Decrypt a file."
    echo "  generate <filename> - Generate RSA key pair and save as 'filename_pub.pem' and 'filename_priv.pem'."
}

# Main script
if [ $# -eq 0 ]; then
    # Si no se proporcionan argumentos, imprime la ayuda.
    print_help
    exit 0
fi

# Procesa el primer argumento para determinar qué acción realizar.
case "$1" in
    encrypt)
        # Opción para encriptar un archivo.
        shift
        encrypt_file "$@"
        ;;
    decrypt)
        # Opción para desencriptar un archivo.
        shift
        decrypt_file "$@"
        ;;
    generate)
        # Opción para generar claves RSA.
        shift
        generate_keys "$@"
        ;;
    help)
        # Opción para mostrar la ayuda.
        print_help
        exit 0
        ;;
    *)
        # Maneja opciones no válidas.
        echo "Invalid command: $1"
        print_help
        exit 1
        ;;
esac

exit 0
# Fin del script.
