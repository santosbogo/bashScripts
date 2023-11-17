#!/bin/bash
# Este script debe ejecutarse con Bash.

if [ "$EUID" -ne 0 ]; then
    # Verifica si el script se ejecuta como usuario root.
    echo "Error: Permission denied. You must run this script as root."
    exit 1
    # Si no es root, muestra un mensaje de error y termina el script.
fi

check_username() {
    # Función para verificar si se ha especificado un nombre de usuario.
    if [ -z "$username" ]; then
        # Si la variable $username está vacía, muestra un mensaje de error y sale.
        echo "Error: Username not specified."
        exit 1
    fi
}

while [ $# -gt 0 ]; do
    # Bucle que procesa todos los argumentos pasados al script.
    case "$1" in
        # Estructura case para manejar diferentes opciones.
        --user)
            # Opción para especificar un nombre de usuario.
            shift
            # Desplaza los argumentos, $1 ahora es el nombre de usuario.
            username="$1"
            # Asigna el nombre de usuario a la variable $username.
            shift
            # Desplaza los argumentos, preparándose para la siguiente opción.
            ;;
        --add-user)
            # Opción para agregar un nuevo usuario.
            shift
            # Comprueba si se ha especificado un nombre de usuario.
            check_username
            # Verifica si el usuario ya existe.
            if id "$username" &>/dev/null; then
                # Si el usuario existe, muestra un mensaje.
                echo "User '$username' already exists."
            else
                # Si no existe, crea el usuario.
                useradd -m "$username"
                echo "User '$username' has been added."
            fi
            shift
            # Desplaza los argumentos para la siguiente opción.
            ;;
        --delete-user)
            # Opción para eliminar un usuario.
            shift
            check_username
            # Verifica si el usuario existe.
            if id "$username" &>/dev/null; then
                # Si existe, lo elimina.
                userdel -r "$username"
                echo "User '$username' has been deleted."
            else
                # Si no existe, muestra un mensaje.
                echo "User '$username' does not exist."
            fi
            shift
            ;;
        --add-to-group)
            # Opción para agregar un usuario a un grupo.
            shift
            groupname="$1"
            # Asigna el nombre del grupo a la variable $groupname.
            if id "$username" &>/dev/null; then
                # Verifica si el grupo existe.
                if grep -q "$groupname" /etc/group; then
                    # Agrega al usuario al grupo.
                    usermod -aG "$groupname" "$username"
                    echo "User '$username' has been added to group '$groupname'."
                else
                    # Si el grupo no existe, muestra un mensaje.
                    echo "Group '$groupname' does not exist."
                fi
            else
                # Si el usuario no existe, muestra un mensaje.
                echo "User '$username' does not exist."
            fi
            shift
            ;;
        --remove-from-group)
            # Opción para eliminar un usuario de un grupo.
            shift
            groupname="$1"
            if id "$username" &>/dev/null; then
                if grep -q "$groupname" /etc/group; then
                    # Elimina al usuario del grupo.
                    gpasswd -d "$username" "$groupname"
                    echo "User '$username' has been removed from group '$groupname'."
                else
                    echo "Group '$groupname' does not exist."
                fi
            else
                echo "User '$username' does not exist."
            fi
            shift
            ;;
        --change-password)
            # Opción para cambiar la contraseña de un usuario.
            shift
            if id "$username" &>/dev/null; then
                # Solicita la nueva contraseña.
                read -s -p "Enter new password for user '$username': " new_password
                echo
                # Cambia la contraseña del usuario.
                echo "$username:$new_password" | chpasswd
                echo "Password for user '$username' has been changed."
            else
                echo "User '$username' does not exist."
            fi
            ;;
        --from-file)
            # Opción para procesar acciones desde un archivo.
            shift
            file="$1"
            if [ -f "$file" ]; then
                # Lee y ejecuta acciones del archivo.
                while IFS=';' read -r action username groupname; do
                    case "$action" in
                        add-to-group)
                            ./user_management.sh --add-to-group "$username" "$groupname"
                            ;;
                        remove-from-group)
                            ./user_management.sh --remove-from-group "$username" "$groupname"
                            ;;
                        change-password)
                            ./user_management.sh --change-password "$username"
                            ;;
                        delete-user)
                            ./user_management.sh --delete-user "$username"
                            ;;
                        *)
                            echo "Invalid action '$action' in file."
                            ;;
                    esac
                done < "$file"
            else
                echo "Error: File '$file' does not exist."
            fi
            shift
            ;;
        *)
            # Maneja cualquier opción no reconocida.
            echo "Invalid option: $1"
            exit 1
            ;;
    esac
done
# Fin del bucle while y del script.
