#!/usr/bin/env bash

#--------------------------------------------------#
# Script_Name: transvert.bash
#
# Author:  'dossantosjdf@gmail.com'
#
# Date: 22/02/2025
# Version: 1.0
# Bash_Version: 5.2.32
#--------------------------------------------------#

pkg_manager=''
dirfilepath="${1%/}"
datetime="$(date +"%d%m%y%H%M%S")"

trap end_script EXIT

# Quel est le gestionnaire de paquets
if type -P apt &> /dev/null; then
  pkg_manager='apt'
elif type -P dnf &> /dev/null; then
  pkg_manager='dnf'
else
  mesg_info 'w' "Gestionnaire de paquets non pris en charge !."
  exit 1
fi

## Les fonctions
end_script() {
  mesg_info 'i' " 🚪 Programme $0 terminé !"
}

check_dirfile() {
  ### dossier ou fichier
  if [[ -z "$dirfilepath" ]]; then
    # Demander la nouvelle extension
    mesg_info 'i' "Indiquer le chemin du dossier ou du fichier à modifier"
    read -e -r -p "Chemin, (ex: /home/daniel/Videos, /home/daniel/film.mkv...) : " dirfilepath
    echo ""
  fi

  dirfilepath="${dirfilepath//\\/}"

  if [[ -f "$dirfilepath" ]]; then
    typefile='file'
  elif [[ -d "$dirfilepath" ]]; then
    count_files="$(find "$dirfilepath" -maxdepth 1 -type f | wc -l)"
    if [[ "$count_files" -gt 0 ]]; then
      typefile='directory'
    else
      mesg_info 'w' "Le dossier $dirfilepath est vide !."
      exit 1
    fi
  else
    mesg_info 'w' "Le fichier/dossier n'existe pas !."
    exit 1
  fi

  dirfilepath="${dirfilepath%/}"
}

### Les dépendances
dependencies() {
  need_update='0'
  option="$opt"

  case $option in
    "Convert")
      if [[ "$pkg_manager" = 'dnf' ]]; then
        repo_rpmfusion_free="https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
        repo_rpmfusion_nonfree="https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

        get_repos="$repo_rpmfusion_free $repo_rpmfusion_nonfree"
        get_apps='ffmpeg'

      elif [[ "$pkg_manager" = 'apt' ]]; then
        get_repos="multiverse"
        get_apps="ffmpeg libavcodec-extra"
        do_reconfigure=''
      fi
      ;;
    "KeepVF")
      if [[ "$pkg_manager" = 'dnf' ]]; then
        repo_rpmfusion_free="https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
        repo_rpmfusion_nonfree="https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

        get_repos="$repo_rpmfusion_free $repo_rpmfusion_nonfree"
        get_apps='ffmpeg'

      elif [[ "$pkg_manager" = 'apt' ]]; then
        get_repos='multiverse'
        get_apps='ffmpeg libavcodec-extra'
        do_reconfigure=''
      fi
      ;;
    "DVD_to_MKV")
      if [[ "$pkg_manager" = 'dnf' ]]; then
        repo_rpmfusion_free="https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
        repo_rpmfusion_nonfree="https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

        get_repos="$repo_rpmfusion_free rpmfusion-free-release-tainted $repo_rpmfusion_nonfree"
        get_apps='ddrescue libdvdcss HandBrake libaacs libbdplus'

      elif [[ "$pkg_manager" = 'apt' ]]; then
        get_repos=''
        get_apps='gddrescue libavcodec-extra handbrake-cli libaacs0 libbdplus0'
        do_reconfigure='libdvd-pkg'
      fi
      ;;
    "VCD_to_MKV")
      if [[ "$pkg_manager" = 'dnf' ]]; then
        repo_rpmfusion_free="https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
        repo_rpmfusion_nonfree="https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

        get_repos="$repo_rpmfusion_free rpmfusion-free-release-tainted $repo_rpmfusion_nonfree"
        get_apps='ffmpeg vcdimager libdvdcss HandBrake libaacs libbdplus'

      elif [[ "$pkg_manager" = 'apt' ]]; then
        get_repos='multiverse'
        get_apps='ffmpeg libavcodec-extra handbrake-cli libaacs0 libbdplus0 vcdimager
'
        do_reconfigure='libdvd-pkg'
      fi
      ;;
    "CD_DVD_Backup")
      if [[ "$pkg_manager" = 'dnf' ]]; then
        get_repos=""
        get_apps='ddrescue cdrdao genisoimage dvdbackup cdparanoia flac cuetools'

      elif [[ "$pkg_manager" = 'apt' ]]; then
        get_repos=''
        get_apps='gddrescue cdrdao genisoimage dvdbackup cdparanoia flac cuetools'
        do_reconfigure=''
      fi
      ;;
  esac
  mesg_info 'i' " 📦 Vérifications des dépendances !"
  if [[ "$pkg_manager" = 'dnf' ]]; then
    # Ajout de dépôts
    for repo in $get_repos; do
      if ! rpm -q "$repo" &> /dev/null; then
        if sudo dnf install -y "$repo"; then
          ((need_update++))
        else
          mesg_info 'w' "Impossible d'installer $repo"
          exit 1
        fi
      fi
    done

    if [[ "$need_update" -gt '0' ]]; then
      sudo dnf update
    fi

    # Ajout des paquets
    for app in $get_apps; do
      if ! rpm -q "$app" &> /dev/null; then
        if ! sudo dnf install -y "$app"; then
          mesg_info 'w' "Impossible d'installer $app"
          exit 1
        fi
      fi
    done
  elif [[ "$pkg_manager" = 'apt' ]]; then
    # Ajout de dépôts
    for repo in $get_repos; do
      if ! grep "$repo" /etc/apt/sources.list /etc/apt/sources.list.d/* &> /dev/null; then
        if sudo add-apt-repository "$repo"; then
          ((need_update++))
        else
          mesg_info 'w' "Impossible d'installer $repo"
          exit 1
        fi
      fi
    done

    if [[ "$need_update" -gt '0' ]]; then
      sudo apt-get update
    fi

    if [[ -n "$do_reconfigure" ]]; then
      for app in $do_reconfigure; do
        if ! dpkg -l | grep "$app" &> /dev/null; then
          if ! sudo apt-get install -y "$app"; then
            mesg_info 'w' "Impossible d'installer $app"
            exit 1
          else
            #dpkg --configure -a
            sudo dpkg-reconfigure "$app"
          fi
        fi
      done
    fi

    # Ajout des paquets
    for app in $get_apps; do
      if ! dpkg -l | grep "$app" &> /dev/null; then
        if ! sudo apt-get install -y "$app"; then
          mesg_info 'w' "Impossible d'installer $app"
          exit 1
        fi
      fi
    done
  fi
}

detect_disk() {
  cd_detected='0'
  tab_menu=()
  # Récupérer la liste des lecteurs CD/DVD/VCD/SVCD
  mapfile -t drives < <(lsblk --noheadings --include 11 --output NAME,MOUNTPOINT,MODEL --pairs)
  if [[ -n "${drives[*]}" ]]; then
    for drive in "${drives[@]}"; do
      cd_name="/dev/$(echo "$drive" | grep -oP 'NAME="\K[^"]+')"
      drive_model="$(echo "$drive" | grep -oP 'MODEL="\K[^"]+' | tr ' ' '_')"
      cd_type_status="$(blkid "$cd_name")"
      #1=cd inseré null=cd non inseré
      cd_inserted="$(udevadm info --query=property --property=ID_CDROM_MEDIA --value --name="$cd_name")"
      if [[ "$cd_inserted" -eq '1' ]]; then
        ((cd_detected++))
        if [[ -n "$cd_type_status" ]]; then
          cd_type='dvd'
      	  cd_mountpoint="$(basename "$(echo "$drive" | grep -oP 'MOUNTPOINT="\K[^"]+'| tr ' ' '_')")"
	        if [[ -z "$cd_mountpoint"  ]]; then
	          if [[ "$opt" = 'Backup' ]]; then
              cd_mountpoint="$(blkid "$cd_name" | grep -oP 'LABEL="\K[^"]+' | tr ' ' '_')"
            else
              mesg_info 'w' "ERREUR DVD $cd_name $cd_mountpoint non Monté !"
              exit 1
            fi
          fi
          tab_menu+=("$cd_name,$cd_type,$cd_mountpoint,${drive_model:=Unknown}")
        else
          cd_type='cd'
	  cd_mountpoint="$(basename "$cd_name")"
          tab_menu+=("$cd_name,$cd_type,$cd_mountpoint,${drive_model:=Unknown}")
        fi
      else
        mesg_info 'w' "ERREUR Pas des disque inséré dans le lecteur !"
        exit 1
      fi
    done
  else
    mesg_info 'w' "ERREUR Pas de lecteur de disques détecté !"
    exit 1
  fi

  # S'il y a plusieurs cds
  if [[ "$cd_detected" -gt 1 ]]; then
    PS3="Votre choix : "
    clear
    printf "\n -- Menu CDrom -- \n\n"
    #    dev  type   mount  model driver
    # /dev/sr0,dvd,CHOK_DEE,DVDRAM_GH60N
    select ITEM in "${tab_menu[@]}" 'Quitter'; do
      if [[ $ITEM == 'Quitter' ]]; then
        exit 0
      else
        cdrom="$ITEM"
        cdrompath="$(echo "$ITEM" | awk -F',' '{print $1}')"
        cdrom_type="$(echo "$ITEM" | awk -F',' '{print $2}')"
        cdrom_mountpoint="$(echo "$ITEM" | awk -F',' '{print $3}')"
        cdrom_driver_model="$(echo "$ITEM" | awk -F',' '{print $4}')"
      fi
      break
    done
  elif [[ "$cd_detected" -eq 1 ]]; then
    # S'il y a qu'un seul cd
    cdrom="${tab_menu[0]}"
    cdrompath="$(echo "$cdrom" | awk -F',' '{print $1}')"
    cdrom_type="$(echo "$cdrom" | awk -F',' '{print $2}')"
    cdrom_mountpoint="$(echo "$cdrom" | awk -F',' '{print $3}')"
    cdrom_driver_model="$(echo "$cdrom" | awk -F',' '{print $4}')"

    mesg_info 'i' " 💿 Disque sélectionné : $cdrom"
    read -rs -p "Appuyez sur Entrée pour continuer ! "
  fi

  if ! [[ -r "$cdrompath" ]]; then
    sudo usermod -aG cdrom $USER
    newgrp cdrom
  fi
}

### Les options
opt_convert() {
  clear
  printf "\n -- Choix du format en sortie -- \n\n"
  PS3='Votre choix: '
  options=("mp3" "flac" "aac" "mp4" "mkv" "avi" "Quitter")
  select opt in "${options[@]}"
  do
    case $opt in
      "mp3")
        codec="-vn -c:a libmp3lame -q:a 0 -y"
        metadata="-map_metadata 0 -id3v2_version 3"
        ext="mp3"
	      file_type='audio'
	      break
        ;;
      "flac")
        codec="-vn -c:a flac -y"
        metadata="-map_metadata 0"
        ext="flac"
	      file_type='audio'
	      break
        ;;
      "aac")
        codec="-vn -c:a aac -b:a 256k -y"
        metadata="-map_metadata 0"
        ext="m4a"
	      file_type='audio'
	      break
        ;;
      "mp4")
        video_codec="-c:v libx264 -preset fast -crf 23"
        audio_codec="-c:a aac -b:a 192k -y"
        metadata="-map_metadata 0"
        ext="mp4"
	      file_type='video'
	      break
        ;;
      "mkv")
        video_codec="-c:v libx265 -preset medium -crf 20 -map 0"
        audio_codec="-c:a aac -b:a 192k -y"
        metadata="-map_metadata 0"
        ext="mkv"
	      file_type='video'
	      break
        ;;
      "avi")
        video_codec="-c:v libxvid -q:v 3"
        audio_codec="-c:a mp3 -b:a 192k -y"
        metadata="-map_metadata 0"
        ext="avi"
	      file_type='video'
	      break
        ;;
      "Quitter")
        exit 1
        ;;
      *)
        mesg_info 'w' "Format non compatible ! : ${REPLY}"
        ;;
    esac
  done

  mesg_info 'i' "✎ Début de la conversion !"

  if [[ "$typefile" == "directory" ]]; then
    for ifile in "$dirfilepath"/*; do
      # Récupérer le type MIME
      file_mime_type="$(file --mime-type -b "$ifile")"
      input_file="$(basename "$ifile")"
      input_file_dir="$(dirname "$ifile")"
      output_dir="$input_file_dir/Converted_${datetime}"
      output_file="${input_file%.*}"

      mkdir -p "$output_dir"

      # Conversion
      if [[ "$file_mime_type" =~ ^video/ ]] && [[ "$file_type" == 'video' ]]; then
        if ! ffmpeg -hide_banner -nostdin -i "$ifile" $metadata $video_codec $audio_codec "$output_dir/$output_file.$ext"; then
          mesg_info 'w' "Erreur de conversion $output_dir/$output_file.$ext ! "
          rm -rf "${output_dir:?}/$output_file.$ext"
        fi
      elif [[ "$file_mime_type" =~ ^video/ ]] && [[ "$file_type" == 'audio' ]]; then
        if ! ffmpeg -hide_banner -nostdin -i "$ifile" $metadata $codec "$output_dir/$output_file.$ext"; then
          mesg_info 'w' "Erreur de conversion $output_dir/$output_file.$ext ! "
          rm -rf "${output_dir:?}/$output_file.$ext"
        fi
      elif [[ "$file_mime_type" =~ ^audio/ ]] && [[ "$file_type" == 'audio' ]]; then
        if ! ffmpeg -hide_banner -nostdin -i "$ifile" $metadata $codec "$output_dir/$output_file.$ext"; then
          mesg_info 'w' "Erreur de conversion $output_dir/$output_file.$ext ! "
          rm -rf "${output_dir:?}/$output_file.$ext"
        fi
      fi
    done
  elif [[ "$typefile" == "file" ]]; then
    # Récupérer le type MIME
    file_mime_type=$(file --mime-type -b "$dirfilepath")
    input_file="$(basename "$dirfilepath")"
    input_file_dir="$(dirname "$dirfilepath")"
    output_dir="$input_file_dir/Converted_${datetime}"
    output_file="${input_file%.*}"

    mkdir -p "$output_dir"

    # Conversion
    if [[ "$file_mime_type" =~ ^video/ ]] && [[ "$file_type" == 'video' ]]; then
      if ! ffmpeg -hide_banner -nostdin -i "$dirfilepath" $metadata $video_codec $audio_codec "$output_dir/$output_file.$ext"; then
        mesg_info 'w' "Erreur de conversion $output_dir/$output_file.$ext ! "
        rm -rf "${output_dir:?}/$output_file.$ext"
      fi
    elif [[ "$file_mime_type" =~ ^video/ ]] && [[ "$file_type" == 'audio' ]]; then
      if ! ffmpeg -hide_banner -nostdin -i "$dirfilepath" $metadata $codec "$output_dir/$output_file.$ext"; then
        mesg_info 'w' "Erreur de conversion $output_dir/$output_file.$ext ! "
        rm -rf "${output_dir:?}/$output_file.$ext"
      fi
    elif [[ "$file_mime_type" =~ ^audio/ ]] && [[ "$file_type" == 'audio' ]]; then
      if ! ffmpeg -hide_banner -nostdin -i "$dirfilepath" $metadata $codec "$output_dir/$output_file.$ext"; then
        mesg_info 'w' "Erreur de conversion $output_dir/$output_file.$ext ! "
        rm -rf "${output_dir:?}/$output_file.$ext"
      fi
    else mesg_info 'w' "Conversion de $file_mime_type vers $file_type non prise en charge pour $input_file !"
    fi
  fi
}

opt_keepvf() {
  if [[ "$typefile" == "directory" ]]; then
    for ifile in "$dirfilepath"/*; do
      if [[ $(file --mime-type -b "$ifile") =~ ^video/ ]]; then
        input_file="$(basename "$ifile")"
        input_file_dir="$(dirname "$ifile")"
        output_dir="$input_file_dir/Converted_VF_${datetime}"
        output_file="$input_file"
        piste_audio="$(ffmpeg -hide_banner -i "$ifile" 2>&1 | awk -F '[#:() ]+' '/Stream #[0-9]+:[0-9]+\(.*(fre|fra).*\): Audio/ {print $3":"$4":"$5}')"
        audio_count=0

        mkdir -p "$output_dir"

        if [[ -n "$piste_audio" ]]; then
          while read -r line; do
            if echo "$line" | grep -E '(fre|fra)'; then
              fr_index="$audio_count"
              break
            else
              ((audio_count++))
            fi
          done < <(ffmpeg -hide_banner -i "$ifile" 2>&1 | grep 'Audio')

          mesg_info 'i' "✎ Début de la transformation !"

          if ! ffmpeg -hide_banner -i "$ifile" -map 0:v -map a:"$fr_index" -map 0:s? -c copy -disposition:a -default -disposition:s -default "$output_dir/$output_file" 2>/dev/null; then
            rm -rf "${output_dir:?}/$output_file"
            if ! ffmpeg -hide_banner -i "$ifile" -map 0:v? -map a:"$fr_index" -c copy -disposition:a -default "$output_dir/$output_file" 2>/dev/null; then
              rm -rf "${output_dir:?}/$output_file"
              mesg_info 'w' "Erreur VF pour $output_dir/$output_file"
              exit 1
            fi
          fi
        else
          mesg_info 'w' "Pas de piste audio en Français pour $ifile !"
        fi
      fi
    done

  elif [[ "$typefile" == "file" ]]; then
    if [[ $(file --mime-type -b "$dirfilepath") =~ ^video/ ]]; then
      input_file="$(basename "$dirfilepath")"
      input_file_dir="$(dirname "$dirfilepath")"
      output_dir="$input_file_dir/Converted_VF_${datetime}"
      output_file="$input_file"
      piste_audio="$(ffmpeg -hide_banner -i "$dirfilepath" 2>&1 | awk -F '[#:() ]+' '/Stream #[0-9]+:[0-9]+\(.*(fre|fra).*\): Audio/ {print $3":"$4":"$5}')"
      audio_count=0

      mkdir -p "$output_dir"

      if [[ -n "$piste_audio" ]]; then
        while read -r line; do
          if echo "$line" | grep -E '(fre|fra)'; then
            fr_index="$audio_count"
            break
          else
            ((audio_count++))
          fi
        done < <(ffmpeg -hide_banner -i "$dirfilepath" 2>&1 | grep 'Audio')

        mesg_info 'i' "✎ Début de la transformation !"

        if ! ffmpeg -hide_banner -i "$dirfilepath" -map 0:v -map a:"$fr_index" -map 0:s? -c copy -disposition:a -default -disposition:s -default "$output_dir/$output_file" 2>/dev/null; then
          rm -rf "${output_dir:?}/$output_file"
          if ! ffmpeg -hide_banner -i "$dirfilepath" -map 0:v? -map a:"$fr_index" -c copy -disposition:a -default "$output_dir/$output_file" 2>/dev/null; then
            rm -rf "${output_dir:?}/$output_file"
            mesg_info 'w' "Erreur Convert $output_dir/$output_file"
            exit 1
          fi
        fi
      else
        mesg_info 'w' "Pas de piste audio en Français ! $dirfilepath"
        exit 1
      fi
    else
      mesg_info 'i' "Le fichier $dirfilepath a été ignoré !"
    fi
  fi
}

opt_dvdtomkv() {
  tab_preset=('Matroska/H.265 MKV 480p30' 'Matroska/H.265 MKV 576p25' 'Matroska/H.265 MKV 720p30' 'Matroska/H.265 MKV 1080p30' 'Matroska/H.265 MKV 2160p60 4K')

  # Récupération de toutes les infos sur les pistes
  if ! disk_infos="$(timeout 60s HandBrakeCLI --scan -i "$cdrompath" --title 0 2>&1)"; then
    mesg_info 'w' "Problème de lecture DVD !"
    exit 1
  fi

  # Récupération du titre du DVD
  dvd_titleA="$(echo "$disk_infos" | awk -F ': ' '/Title:/ {print $3}' | tr ' ' '_')"
  dvd_titleB="$(echo "$disk_infos" | awk -F ': ' '/Title (Alternative):/ {print $3}' | tr ' ' '_')"
  if [[ -n "$dvd_titleA" ]]; then
    output_name_file="$dvd_titleA"
  else
    if [[ -n "$dvd_titleB" ]]; then
      output_name_file="$dvd_titleB"
    else
      output_name_file="${cdrom_mountpoint}${cdrom_driver_model}"
    fi
  fi

  # Création des dossiers
  dvd_dir="$HOME/My_DVD_${datetime}_${output_name_file}"
  dvd_dir_bonus="$dvd_dir/Videos_bonus"

  # Récupération de tous les titres vidéos disponibles
  titles="$(echo "$disk_infos" | awk '/^\+ title [0-9]+:/ {print $3}' | cut -d':' -f1)"

  # récupération des informations par titre
  for title in $titles; do
    # Infos par title
    title_infos="$(HandBrakeCLI --scan -i "$cdrompath" --title "$title" 2>&1)"
    # Durée par title (01:42:27)
    title_duration="$(echo "$title_infos" | awk '/^\s+\+\sduration:\s/ {print $3}')"
    # Dysplay par title (720x[576])
    title_dysplay_format="$(echo "$title_infos" | awk '/^\s+\+ size:/' | awk -F'[ ,]' '{print $5}' | cut -d'x' -f2)"
    # Crop par title (12/16/2/0)
    title_autocrop="$(echo "$title_infos" | awk '/^\s+\+ autocrop:/ {print $3}' | tr '/' ':')"

    tab_infos_titles[title]="du=${title_duration},dy=${title_dysplay_format},cr=${title_autocrop},"
  done

  # Trouver la plus longue vidéo = vidéo principale
  main_duration_title="$(echo "${tab_infos_titles[@]}" | tr ' ' '\n' | awk -F'du=' '{print $2}' | cut -d ',' -f1 | sort -r | head -n 1)"

  # Traitement de tous les titles
  for video_index in "${!tab_infos_titles[@]}"; do
    # Trouver le title principale
    if echo "${tab_infos_titles[video_index]}" | grep "$main_duration_title"; then
      output_file="$dvd_dir/Main_t${video_index}_${output_name_file}.mkv"
    else
      output_file="$dvd_dir_bonus/Bonus_t${video_index}_${output_name_file}.mkv"
    fi

    # Les differents paramètres
    video_dysplay="$(echo "${tab_infos_titles[video_index]}" | awk -F 'dy=' '{print $2}' | cut -d ',' -f1)"
    video_crop="$(echo "${tab_infos_titles[video_index]}" | awk -F 'cr=' '{print $2}' | cut -d ',' -f1)"

    # Déterminer la bonne configuration de preset
    if [[ -n "$video_dysplay" ]]; then
      preset_index=0
      for preset_config in "${tab_preset[@]}"; do
        preset_dysplay="$(echo "$preset_config" | grep -Eo '\s+[0-9]+p' | tr -d '  p')"
        if [[ "$preset_dysplay" = "$video_dysplay" ]]; then
          preset_para1='--preset'
          preset_para2="$preset_index"
          break
        fi
        ((preset_index++))
      done
    else
      preset_para1='--keep-display-aspect'
    fi

    # Déterminer crop si possible
    if [[ -n "$video_crop" ]]; then
      para_crop="--crop $video_crop"
    else
      para_crop=''
    fi

    # Création des dossiers
    mkdir -p "$dvd_dir_bonus"

    mesg_info 'i' " 📀 Début de la conversion !"

    HandBrakeCLI --input "$cdrompath" \
    --output "$output_file" \
    --title "$video_index" \
    $preset_para1 "${tab_preset[preset_para2]}" \
    --all-subtitles \
    --subtitle-default none \
    --subtitle-burned none \
    --all-audio \
    --arate auto \
    --verbose \
    $para_crop

    if [[ "$?" -ne '0' ]]; then
      mesg_info 'w' "Erreur pendant la récupération du DVD $output_name_file"
    fi
  done
  eject
}

opt_vcdtomkv() {
  vcd_dir="$HOME/My_VCD_${datetime}"
  vcd_dir_temp="$vcd_dir/Temp_VCD_files"

  # Créer le répertoire de sortie s'il n'existe pas
  mkdir -p "$vcd_dir_temp"

  # Se placer dans le répertoire de sortie
  cd "$vcd_dir_temp" || { mesg_info 'w' "Erreur: Impossible de changer de répertoire."; exit 1; }

  mesg_info 'i' "📀 Début de la conversion !"
  # Extraire les fichiers du VCD
  vcdxrip --cdrom-device "$cdrompath" --progress --verbose
  if [[ "$?" -ne '0' ]]; then
    mesg_info 'w' "Erreur de récupération des données du VCD $cdrom_mountpoint"
    exit 1
  fi

  # Création d'une liste
  find "$vcd_dir_temp" -type f -print0 | while IFS= read -r -d '' file; do
    mime_type=$(file --mime-type -b "$file")
    if [[ "$mime_type" == audio/* || "$mime_type" == video/* ]]; then
      echo "file ${file#./}" >> /tmp/rawlist.txt
    fi
  done

  sort /tmp/rawlist.txt > /tmp/list.txt

  # Convertir en mkv
  if ! ffmpeg -f concat -safe 0 -i /tmp/list.txt -c:v libx264 -crf 23 -preset veryfast -c:a aac -b:a 192k "$vcd_dir"/"$cdrom_mountpoint".mkv ; then
    mesg_info 'w' "Erreur de récupération du VCD $cdrom_mountpoint"
    exit 1
  fi
  eject
}

opt_cddvd_backup() {
  # Détecter si c'est un CD ou un DVD
  if [[ "$cdrom_type" = 'cd' ]]; then
    # Création des répertoires
    Backup_dir="$HOME/My_${cdrom_type}_Backup_${datetime}_${cdrom_mountpoint}"
    mkdir -p "$Backup_dir"
    mesg_info 'i' "💿 Copie du CD !"
    cdrdao read-cd \
    --read-raw \
    --driver generic-mmc:0x20000 \
    --device "$cdrompath" \
    --datafile "$Backup_dir"/image.bin \
    --eject \
    --paranoia-mode 1 -v 2 "$Backup_dir"/image.toc
    if [[ "$?" -ne '0' ]]; then
      mesg_info 'w' "Erreur copie du CD et tentative de récupération via ddrescue !"
      if ! sudo ddrescue -b 2048 -r3 -d -v "$cdrompath" "$Backup_dir"/"$cdrom_mountpoint".iso "$Backup_dir"/"$cdrom_mountpoint".log ; then
        mesg_info 'w' "Impossible de récupérer le CD !"
        exit 1
      fi
    else
      # Convertir en cue
      if ! convert_toc2cue "$Backup_dir"/image.toc; then
        mesg_info 'w' "Erreur de conversion de toc vers cue"
        exit 1
      else
        mkdir -p "$Backup_dir"/Audio && cd "$Backup_dir"/Audio || exit 1
        cdparanoia -B --verbose --never-skip=5 --log-summary
        flac track*.wav --preserve-modtime --best --delete-input-file

        cuetag "$Backup_dir"/image.cue track*.flac

        for file in track*.flac; do
          title=$(metaflac --show-tag=TITLE "$file" | cut -d= -f2)
          tracknum=$(metaflac --show-tag=TRACKNUMBER "$file" | cut -d= -f2)
          tracknum=$((10#$tracknum))

          if [[ -n "$title" && -n "$tracknum" ]]; then
            new_name="$(printf "%02d - %s.flac" "$tracknum" "$title")"
            mv "$file" "$new_name"
          fi
        done
        mesg_info 'i' "Récupération réussie !"
      fi
    fi
  elif [[ "$cdrom_type" = 'dvd' ]]; then
    # Création des répertoires
    Backup_dir="$HOME/My_${cdrom_type}_Backup_${datetime}_${cdrom_mountpoint}"
    if mount | grep "$cdrompath"; then
      umount "$cdrompath"
    fi
      mesg_info 'i' "💿 Début de la copie du DVD !"
      if ! dvdbackup --mirror --progress --input="$cdrompath" --output="$Backup_dir"; then
        mesg_info 'w' "Erreur copie du DVD et tentative de récupération via ddrescue !"
        if ! sudo ddrescue -b 2048 -r3 -d -v "$cdrompath" "$Backup_dir"/"$cdrom_mountpoint".iso "$Backup_dir"/"$cdrom_mountpoint".log ; then
          mesg_info 'w' "Impossible de récupérer le DVD !"
          exit 1
        fi
      else
        # 32 characters
        mkisofs -dvd-video -udf -J -r -V "$cdrom_mountpoint" -v -o "$cdrom_mountpoint".iso "$Backup_dir"
        mesg_info 'i' "Récupération réussie !"
      fi
  fi
  eject
}

mesg_info() {
  mesg_progress="${2}"
  type_info="${1}" # w pour warning et i pour info
  array=()

  # Définir le fichier log
  logfile="${PWD%/}/Logs_${datetime}.log"

  # Ajouter un timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  # Déterminer la couleur et le type de message
  if [[ $type_info == 'w' ]]; then
    log_type="[WARNING] ❌ "

    # Afficher le message à l'écran et l'enregistrer dans le log
    printf "\n %s %s %s \n\n" "$timestamp" "$log_type" "$mesg_progress" | tee -a "$logfile"

    # Générer la ligne de séparation
    nbc_msg="${#mesg_progress}" # Nombre de caractères du message
    nbc_type="${#log_type}"
    nbc_time="${#timestamp}"
    nbc_total="$((nbc_msg + nbc_type + nbc_time))"

    for (( i=0; i <= nbc_total; i++ )); do
      array+=(-)
    done

    printf %s "${array[@]}" $'\n' | tee -a "$logfile"
    echo "" | tee -a "$logfile" # Saut de ligne dans le log

  elif [[ $type_info == 'i' ]]; then
    log_type="[INFO]"
    printf "\n %s %s \n\n" "$log_type" "$mesg_progress"
  fi
}

# Fonction permettant de calculer les index
calculindex() {
  file_start="$1"
  start_track="$2"

  if [[ -n "$start_track" ]]; then
    index_00="$file_start"
    # Extraction des données
    IFS=':' read -r index_00_minutes index_00_seconds index_00_frames <<< "$index_00"
    IFS=':' read -r start_track_minutes start_track_seconds start_track_frames <<< "$start_track"
    # Calcul des frames (00 à 74)
    calcul_frames="$((${index_00_frames#0}+${start_track_frames#0}))"
    if [[ "$calcul_frames" -gt '74' ]]; then
      calcul_frames_rest="$((${calcul_frames#0}-75))"
      if [[ "$calcul_frames_rest" -eq '0' ]]; then
        calcul_frames='00'
        add_seconds='1'
      elif [[ "$calcul_frames_rest" -gt '0' ]]; then
        calcul_frames="$calcul_frames_rest"
        add_seconds='1'
      fi
    else
      add_seconds='0'
    fi
    # Calcul des secondes (00 à 59)
    calcul_seconds="$((${index_00_seconds#0}+${start_track_seconds#0}+add_seconds))"
    if [[ "$calcul_seconds" -gt '59' ]]; then
      calcul_seconds_rest="$((${calcul_seconds#0}-60))"
      if [[ "$calcul_seconds_rest" -eq '0' ]]; then
        calcul_seconds='00'
        add_minutes='1'
      elif [[ "$calcul_seconds_rest" -gt '0' ]]; then
        calcul_seconds="$calcul_seconds_rest"
        add_minutes='1'
      fi
    else
      add_minutes='0'
    fi
    # Calcul des minutes (00 à 99)
    calcul_minutes="$((${index_00_minutes#0}+${start_track_minutes#0}+add_minutes))"
    if [[ "$calcul_minutes" -gt '99' ]]; then
      mesg_info 'w' "Les minutes dépassent 99, valeur calculée : $calcul_minutes"
      exit 1
    fi
    index_01="$(printf "%02d:%02d:%02d" "$calcul_minutes" "$calcul_seconds" "$calcul_frames")"
  else
    index_00="$file_start"
    index_01="$index_00"
    start_value="false"
  fi

  if [[ "$start_value" == 'false' ]]; then
    echo "    INDEX 01 $index_01"
  else
    echo "    INDEX 00 $index_00"
    echo "    INDEX 01 $index_01"
  fi
}

convert_toc2cue() {
  # Vérifier si c'est un fichier toc
  if [[ -f "$1" ]]; then
    type_file="$(file --mime-type -b "$1")"
    if ! [[ "$type_file" == text/* ]]; then
      mesg_info 'w' "Le fichier $1 n'est pas compatible !"
      exit 1
    fi
  else
    mesg_info 'w' "Le fichier $1 n'existe pas !"
    exit 1
  fi

  toc_file="$1"
  cue_file="${toc_file%.toc}.cue"

  # Extraire le nom du fichier bin
  bin_file=$(grep -oP 'FILE "\K[^"]+' "$toc_file" | head -n 1)

  # Extraire la valeur de CATALOG
  catalog_info="$(grep -oP 'CATALOG "\K[0-9]{13}(?=")' "$toc_file" | head -n 1)"

  # Vérifier si un fichier bin a été trouvé
  if [ -z "$bin_file" ]; then
      mesg_info 'w' "Aucun fichier bin trouvé dans le fichier toc !"
      exit 1
  fi

  # Créer le fichier cue
  # REM configuration globale ###
  echo "REM COMMENT \"Ripped from original CD\"" > "$cue_file"
  if [[ -n "$catalog_info" ]]; then
    echo "CATALOG $catalog_info" >> "$cue_file"
  fi

  # FILE configuration globale ###
  if [[ -n "$bin_file" ]]; then
    echo "FILE \"$bin_file\" BINARY" >> "$cue_file"
  else
    mesg_info 'w' "Pas d'indications sur le fichier bin dans le fichier toc !"
    exit 1
  fi

  track_num=0
  start_found=false

  while IFS= read -r toc_line; do
    # TRACK et INDEX ###
    if [[ "$toc_line" =~ TRACK\ AUDIO ]]; then
      # Si une piste précédente n'a pas de ligne START
      if [[ "$track_num" -gt 0 && "$start_found" == false ]]; then
        calculindex "$begin_audio_track" "$track_transition" | grep 'INDEX 01' >> "$cue_file"
      fi
      # Incrémenter track_num permet de détecter la piste courante
      ((track_num++))
      printf "\n  TRACK %02d AUDIO\n" "$track_num" >> "$cue_file"
      start_found=false
    fi

    # ISRC ###
    if [[ "$toc_line" =~ ISRC\ \"(.*)\" ]] && [[ "$track_num" -gt '0' ]]; then
      echo "    ISRC \"${BASH_REMATCH[1]}\"" >> "$cue_file"
    fi

    # TITLE ###
    if [[ "$toc_line" =~ TITLE\ \"(.*)\" ]]; then
      title_info=$(printf "%b" "${BASH_REMATCH[1]}")
      if [[ "$track_num" -gt '0' ]]; then
        echo "    TITLE \"${title_info}\"" >> "$cue_file"
      else
        echo "TITLE \"${title_info}\"" >> "$cue_file"
      fi
    fi

    # PERFORMER configuration globale ou par piste audio ###
    if [[ "$toc_line" =~ PERFORMER\ \"(.*)\" ]]; then
      performer_info=$(printf "%b" "${BASH_REMATCH[1]}")
      if [[ "$track_num" -gt '0' ]]; then
        echo "    PERFORMER \"${performer_info}\"" >> "$cue_file"
      else
        echo "PERFORMER \"${performer_info}\"" >> "$cue_file"
      fi
    fi

    # INDEX ###
    if [[ "$toc_line" =~ FILE\ \".*\"\ (0|[0-9]+:[0-9]+:[0-9]+)\ ([0-9]+:[0-9]+:[0-9]+) ]]; then
      if [[ "${BASH_REMATCH[1]}" == '0' ]]; then
        begin_audio_track='00:00:00'
      else
        begin_audio_track="${BASH_REMATCH[1]}"
      fi
    fi

    # START ###
    # Calcul des INDEX avec ligne START
    if [[ "$toc_line" =~ START\ ([0-9]+:[0-9]+:[0-9]+) ]]; then
      track_transition="${BASH_REMATCH[1]}"
      calculindex "$begin_audio_track" "$track_transition" >> "$cue_file"
      start_found=true
      begin_audio_track=''
      track_transition=''
    fi
  done < "$toc_file"

  # Ajouter la valeur d'INDEX 01 pour la dernière piste si START est manquant
  if [[ "$start_found" == false ]]; then
    calculindex "$begin_audio_track" "$track_transition" | grep 'INDEX 01' >> "$cue_file"
  fi

  mesg_info 'i' "Conversion du fichier $toc_file vers $cue_file terminée !"
}

### Menu
clear
printf "\n -- Menu -- \n\n"
PS3='Votre choix: '
options=("Convert" "KeepVF" "DVD_to_MKV" "VCD_to_MKV" "CD_DVD_Backup" "Quitter")
select opt in "${options[@]}"
do
  case $opt in
    "Convert")
      check_dirfile
      dependencies
      opt_convert
      break
      ;;
    "KeepVF")
      check_dirfile
      dependencies
      opt_keepvf
      break
      ;;
    "DVD_to_MKV")
      detect_disk
      dependencies
      opt_dvdtomkv
      break
      ;;
    "VCD_to_MKV")
      detect_disk
      dependencies
      opt_vcdtomkv
      break
      ;;
    "CD_DVD_Backup")
      detect_disk
      dependencies
      opt_cddvd_backup
      break
      ;;
    "Quitter")
      exit 1
      ;;
    *)
      mesg_info 'w' "Option invalide : ${REPLY}"
      ;;
  esac
done
