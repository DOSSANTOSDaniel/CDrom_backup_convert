# CDrom_backup_convert
Script Bash permettant de convertir des fichiers **audio et vidéo** dans différents formats, ainsi que d'effectuer des sauvegardes de **CD/DVD/VCD**.
Il utilise `ffmpeg`, `HandBrakeCLI` et d'autres outils en fonction des options choisies.

## 🚀 Fonctionnalités
### [Convert]
- **Conversion de fichiers audio** 🎵 :
  Vers les formats populaires comme **MP3**, **FLAC**, et **AAC**.
- **Conversion de fichiers vidéo** 🎬 :
  Vers des formats courants tels que **MP4**, **MKV**, et **AVI**.
- **Support des dossiers** :
  Si un dossier est spécifié en entrée, tous les fichiers qu'il contient seront convertis.

### [KeepVF]
- **Extraction et sauvegarde des pistes audio en français** 🇫🇷 :
  L'objectif est de conserver uniquement la piste audio française ("stripping audio"), ce qui permet d'alléger le fichier vidéo.

### [DVD_to_MKV]
- **Récupération d'un DVD au format MKV** :
  Extrait le contenu d'un DVD et le convertit en un fichier MKV compatible avec la plupart des lecteurs multimédia.

### [VCD_to_MKV]
- **Récupération d'un VCD au format MKV** :
  Convertit un VCD en fichier MKV pour une meilleure compatibilité et qualité.

### [CD_DVD_Backup]
- **Sauvegarde de CD/DVD** 💿 :
  - Pour les **DVD**, crée une image ISO du disque.
  - Pour les **CD audio**, extrait toutes les pistes audio (avec leurs métadonnées) et les convertit au format **FLAC** en les renomant avec les titres originaux de l'album.

### Autres fonctionnalités
- **Gestion automatique des dépendances** 📦 :
  Le script détecte le gestionnaire de paquets (`apt`, `dnf`) et installe automatiquement les outils nécessaires.
- **Conversion des fichiers TOC en CUE** :
  Prend en charge les fichiers TOC pour les convertir en format CUE, ce qui permet de récupérer les métadonnées des pistes audios d'un CD audio.

## 🛠️ Prérequis
Le script s'assure que les outils suivants sont installés sur votre système.
S'ils ne sont pas présents, il les installe automatiquement via le gestionnaire de paquets approprié (`apt`, `dnf`) :
- `ffmpeg` (conversion audio/vidéo)
- `HandBrakeCLI` (pour les conversions DVD)
- `dvdbackup`, `cdrdao`, `cdparanoia` (pour les sauvegardes CD/DVD)
- `libdvdcss`, `libaacs`, `libbdplus` (pour le décodage des DVD protégés)

## Utilisation
### Exécution basique
Lancez le script avec :
```bash
./cdrom_backup_convert.bash
```
Un menu interactif vous permettra de sélectionner l'option souhaitée.

### Spécification directe d'un fichier ou dossier
Vous pouvez également spécifier directement un fichier ou un dossier :
```bash
./cdrom_backup_convert.bash /chemin/vers/fichier.avi
```
- Si aucun fichier ou dossier n'est spécifié, le script vous demandera de saisir le chemin manuellement.
- Si un dossier est fourni, le script agira sur **tous les fichiers** qu'il contient sauf sur les fichier non vidéo ou audio.

### Exemples de conversion
- Convertir une vidéo en MP4 :
  ```bash
  ./cdrom_backup_convert.bash /home/daniel/Videos/film.avi
  ```
- Convertir tous les fichiers du dossier `Videos` :
  ```bash
  ./cdrom_backup_convert.bash /home/daniel/Videos
  ```

## Notes importantes
1. **Structure des conversions** :
   Les fichiers convertis sont stockés dans un dossier nommé `Converted_<date>` situé dans le repertoire personnel de l'utilisateur qui exécute le script.

2. **Logs d'exécution** :
   Toutes les erreurs rencontré par le script sont enregistrées dans un fichier `Logs_<date>.log` placé dans le dossier courant.

3. **Préservation des fichiers originaux** :
   Les fichiers sources ne sont jamais modifiés. Une copie convertie est générée à chaque fois dans un dossier(`Converted_<date>`).

## Actions possibles après une sauvegarde DVD
### Graver un fichier ISO sur un autre DVD
Pour graver un fichier ISO sur un DVD vierge :
```bash
growisofs -dvd-compat -Z /dev/dvd=votre_fichier.iso
```
### Monter un fichier ISO
Pour monter un fichier ISO sur un point de montage :
```bash
sudo mount -o loop DVD_Backups/DVD_image.iso /mnt
```
### Interfaces graphiques alternatives
Si vous préférez une interface graphique pour gérer vos médias, voici quelques outils recommandés :
- **K3b** : Un outil complet pour graver des CD/DVD.
- **Brasero** : Une application simple et intuitive pour la gravure sous GNOME.
