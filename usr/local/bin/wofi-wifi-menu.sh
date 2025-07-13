#!/bin/bash
#
# Autor:           Fernando Souza - https://www.youtube.com/@fernandosuporte/ | https://github.com/tuxslack
# Colaboração:     
# Data:            12/07/2025 as 20:26:13
# Script:          wofi-wifi-menu.sh
# Versão:          0.1
#
# Um menu Wi-Fi escrito em bash. Usa wofi e nmcli.
#
#
# Data da atualização:  
#
# Licença:  MIT
#
# Repositório: https://github.com/tuxslack/wofi-wifi-menu
#
#
# Você provavelmente vai querer colocar o script no seu $PATH para poder executá-lo como 
# um comando e mapear uma combinação de teclas para ele.
#
# echo $PATH
#
# mv -i  wofi-wifi-menu.sh /usr/local/bin/
#
# chmod +x  /usr/local/bin/wofi-wifi-menu.sh


# https://www.youtube.com/watch?v=v8w1i3wAKiw



# Script adaptado para Wofi



# $ wofi-wifi-menu.sh 

# (wofi:29433): Gtk-WARNING **: 20:15:45.853: Failed to set text '  C&D ' from markup due to error parsing markup: Erro na linha 1: Entidade não termina com um ponto e vírgula; provavelmente você utilizou um “e comercial” sem desejar iniciar uma entidade — escape-o com &amp;

# (wofi:29433): Gtk-WARNING **: 20:15:45.854: Failed to set text '  C&D ' from markup due to error parsing markup: Erro na linha 1: Entidade não termina com um ponto e vírgula; provavelmente você utilizou um “e comercial” sem desejar iniciar uma entidade — escape-o com &amp;


# ----------------------------------------------------------------------------------------

# Para Labwc:


# nano ~/.config/labwc/autostart

# mako >/dev/null 2>&1 &


# nano ~/.config/labwc/menu.xml

# 		<item label="wofi-wifi-menu" icon="network-wireless">
# 			<action name="Execute"><command>/usr/local/bin/wofi-wifi-menu.sh</command></action>
# 		</item>


# ----------------------------------------------------------------------------------------

# FONT (não usado com wofi, mas mantido para referência)
# FONT="Monospace 12"



# Dica: Os temas do Wofi usam CSS, então é bem flexível. Você pode criar seu próprio em 
# ~/.config/wofi/ ou copiar e modificar algum da internet.

export WOFI_STYLE="$HOME/.config/wofi/style-menu-wifi.css"

# Renomeia o arquivo $HOME/.config/wofi/config-menu-wifi para $HOME/.config/wofi/config




# Cores

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
NC='\e[0m'

# Internacionalização

export LANG="$LANG"
export TEXTDOMAIN=wofi-wifi-menu
export TEXTDOMAINDIR=/usr/share/locale


# Caminho do arquivo de tradução

idioma=$(echo "$LANG" | cut -d. -f1)
arquivo="/usr/share/locale/$idioma/LC_MESSAGES/wofi-wifi-menu.mo"
diretorio=$(dirname "$arquivo")

# Verificações básicas

if [ ! -d "$diretorio" ] || [ ! -f "$arquivo" ]; then
    echo -e "\n${RED}$(gettext 'Translation files not found.')${NC}\n"
    exit 1
fi

# Função para verificar se há internet

verificar_internet() {
    ping -q -c 1 -W 1 8.8.8.8 > /dev/null
    return $?
}

# Verificar dependências

for cmd in "notify-send" "nmcli" "sed" "wofi" "fc-list" "gettext" "yad" "sudo" "grep" "sort"; do
    command -v "$cmd" &>/dev/null || {
        echo -e "\n${RED}$(printf "$(gettext 'Error: %s is not installed.')" "'$cmd'") ${NC}\n"
        exit 1
    }
done

# Verificar tema Adwaita

DIR="/usr/share/icons/Adwaita"

if [ ! -d "$DIR" ]; then

    yad --center --title="$(gettext 'Error')" --text="$(gettext "The Adwaita icon theme is missing.\nInstall the 'adwaita-icon-theme' package.")" --button="OK":0 --width="300" --height="150"
    exit 1

fi

# Verifica se Font Awesome ou Nerd Fonts estão instaladas

if ! fc-list | grep -iqE "Font Awesome|Nerd Fonts"; then
    echo -e "\n${RED}$(gettext "Error: Neither 'Font Awesome' nor 'Nerd Fonts' is installed.")${NC}\n"
    exit 1
fi

# Verificar status do Wi-Fi

wifi_status=$(nmcli radio wifi)

if [[ "$wifi_status" =~ "enabled" || "$wifi_status" =~ "habilitado" ]]; then

    toggle="󰖪  $(gettext 'Disable Wi-Fi')"
    nmcli dev wifi rescan
    networks=$(nmcli -t -f SSID dev wifi | sort)

    [ -z "$networks" ] && exit

    notify-send -i "/usr/share/icons/Adwaita/symbolic/status/network-wireless-connected-symbolic.svg" "$(gettext 'Getting list of available Wi-Fi networks...')"
    sleep 1
    wifi_list=$(nmcli --fields "SECURITY,SSID" device wifi list | sed 1d | sed 's/  */ /g' | sed -E "s/WPA*.?\S/ /g" | sed "s/^--/ /g" | sed "s/  //g" | sed "/--/d")

elif [[ "$wifi_status" =~ "disabled" || "$wifi_status" =~ "desabilitado" ]]; then

    toggle="󰖩  $(gettext 'Enable Wi-Fi')"

fi

# Mostrar menu com wofi

# chosen_network=$(echo -e "$toggle\n$wifi_list" | uniq -u | wofi --dmenu --prompt "$(gettext 'Choose a Wi-Fi network:')")


chosen_network=$(echo -e "$toggle\n$wifi_list" | uniq -u | wofi --style $WOFI_STYLE --dmenu --prompt "$(gettext 'Choose a Wi-Fi network:')")




# Cancelado?

[ -z "$chosen_network" ] && exit

# Nome da rede escolhida

read -r chosen_id <<< "${chosen_network:3}"

# Toggle Wi-Fi

if [ "$chosen_network" = "󰖩  $(gettext 'Enable Wi-Fi')" ]; then

    nmcli radio wifi on
    notify-send -i "/usr/share/icons/Adwaita/symbolic/status/network-wireless-connected-symbolic.svg" "$(gettext 'Wi-Fi Enabled')" "$(gettext 'Wi-Fi has been enabled.')"

elif [ "$chosen_network" = "󰖪  $(gettext 'Disable Wi-Fi')" ]; then

    nmcli radio wifi off
    notify-send -i "/usr/share/icons/Adwaita/symbolic/status/network-wireless-offline-symbolic.svg" "$(gettext 'Wi-Fi Disabled')" "$(gettext 'Wi-Fi has been disabled.')"

else

    saved_connections=$(nmcli -g NAME connection)
    success_message=$(printf "$(gettext 'You are now connected to the Wi-Fi network %s.')" "\"$chosen_id\"")
    message=$(gettext 'Failed to connect to %s. Please check the network.')

    if echo "$saved_connections" | grep -w -q "$chosen_id"; then

        if nmcli connection up id "$chosen_id" > /dev/null 2>&1; then
            notify-send -i "/usr/share/icons/Adwaita/symbolic/status/network-wireless-connected-symbolic.svg" "$(gettext 'Connection Established')" "$success_message"
        else
            notify-send -i "/usr/share/icons/Adwaita/symbolic/status/network-wireless-offline-symbolic.svg" "$(gettext 'Wi-Fi Connection Error')" "$(printf "$message" "$chosen_id")"
        fi

    else

        if [[ "$chosen_network" =~ "" ]]; then
            wifi_password=$(wofi --dmenu --password --prompt "$(gettext 'Enter the network password:')")
        fi

        if nmcli device wifi connect "$chosen_id" password "$wifi_password"; then
            notify-send -i "/usr/share/icons/Adwaita/symbolic/status/network-wireless-connected-symbolic.svg" "$(gettext 'Connection Established')" "$success_message"
        else
            notify-send -i "/usr/share/icons/Adwaita/symbolic/status/network-wireless-offline-symbolic.svg" "$(gettext 'Wi-Fi Connection Error')" "$(printf "$message" "$chosen_id")"
        fi
    fi
fi

exit 0

