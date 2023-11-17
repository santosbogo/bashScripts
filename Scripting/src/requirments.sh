#!/bin/bash

# Constants
REQUIREMENTS_FILE="requirements.txt"

# Function to check if a package is installed
is_package_installed() { #como primer parametro se le debe pasar el package a verificar si esta instalado
    dpkg -l "$1" &>/dev/null #Si esta instalado se ejecuta correctamente, si no devolveria error pero se lo chupa &>/dev/null
}

check_root_perms() {
    if [ "$EUID" -ne 0 ]; then
        echo "Error: Permission denied. You must run this command as root."
        exit 1
    fi
}

# Function to install a package
install_package() {
    check_root_perms
    if is_package_installed "$1"; then
        echo "Package '$1' is already installed."
    else
        sudo apt-get update
        sudo apt-get install -y "$1"
        echo "Package '$1' has been installed."
    fi
}

# Function to verify dependencies
verify_dependencies() {
    if [ ! -f "$REQUIREMENTS_FILE" ]; then #Se fija si existe el archvio
        echo "Error: '$REQUIREMENTS_FILE' not found in the current directory."
        exit 1
    fi

    while read -r package; do #Lee una linea de entrada y la escribe en package (-r significa que cualquier tipo de car)
        if is_package_installed "$package"; then
            echo "Dependency '$package' is met."
        else
            echo "Dependency '$package' is not met."
        fi
    done < "$REQUIREMENTS_FILE"
}

# Function to add a dependency
add_dependency() {
    if [ $# -ne 1 ]; then
        echo "Usage: $0 add <dependency>"
        exit 1
    fi

    dependency="$1"

    if is_package_installed "$dependency"; then
        echo "Dependency '$dependency' is already installed."
    else
        echo "$dependency" >> "$REQUIREMENTS_FILE"
        echo "Dependency '$dependency' has been added to '$REQUIREMENTS_FILE'."
        install_package "$dependency"
    fi
}

# Function to remove a dependency
remove_dependency() {
    if [ $# -ne 1 ]; then
        echo "Usage: $0 remove <dependency>"
        exit 1
    fi

    dependency="$1"

    if grep -q "$dependency" "$REQUIREMENTS_FILE"; then
        sed -i "/^$dependency\$/d" "$REQUIREMENTS_FILE"
        echo "Dependency '$dependency' has been removed from '$REQUIREMENTS_FILE'."
    else
        echo "Dependency '$dependency' not found in '$REQUIREMENTS_FILE'."
    fi
}

# Help function
print_help() {
    echo "Usage: $0 <command>"
    echo "Commands:"
    echo "  install        - Install missing dependencies from '$REQUIREMENTS_FILE'."
    echo "  verify         - Verify that dependencies are met."
    echo "  add <dependency> - Add a new dependency to '$REQUIREMENTS_FILE' and install it."
    echo "  remove <dependency> - Remove a dependency from '$REQUIREMENTS_FILE'."
    echo "  help           - Print this help message."
    echo "Options:"
    echo "  -f, --file <file> - Specify an alternative requirements file (default is '$REQUIREMENTS_FILE')."
}

ARGS=("$@") #Pasa todos los elementos a una lista
# Parse options first
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--file) #Si $1 es igual a -f o --file
            shift #Desplaza todos los argumentos una posicion a la izquierda $1 se elimina $1=$2, $2=$3, etc.
            REQUIREMENTS_FILE="$1" #Por lo tanto en $1 esta el archivo ya que se le pasa como argumento: --file ./req.txt
            break
            ;;
        *)
            shift
            ;;
    esac
done

# Main script
if [ "$EUID" -ne 0 ]; then #Verifica que seas root
    echo "Error: Permission denied. You must run this script as root."
    exit 1
fi

set -- "${ARGS[@]}" #Hace que los valores en el array ARGS se accedan con $1, $2, $3, etc.
                    #Esto es porque antes habiamos hecho shift

while [[ $# -gt 0 ]]; do # La cantidad de argumentos es mayor a 0
    case "$1" in
        install)
            verify_dependencies #esta mal, solo verifica, no las instala automaticamente
            ;;
        verify)
            verify_dependencies
            ;;
        add)
            shift
            add_dependency "$1"
            shift
            ;;
        remove)
            shift
            remove_dependency "$1"
            shift
            ;;
        help)
            print_help
            exit 0
            ;;
        -f|--file)
            shift
            shift
            ;;
        *)
            echo "Invalid command: $1"
            print_help
            exit 1
            ;;
    esac
done

exit 0