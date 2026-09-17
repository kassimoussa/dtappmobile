#!/usr/bin/env bash
# Cherche des secrets dans des fichiers avant qu'ils n'entrent dans Git.
#
# Sans argument : examine les fichiers indexés (usage du hook pre-commit).
# Avec des chemins en argument : examine ces fichiers (utile en CI ou à la main
# sur tout le dépôt : tool/check_secrets.sh $(git ls-files)).
#
# Un secret commité reste dans l'historique et doit être considéré comme
# compromis : le but est de l'attraper avant, pas de nettoyer après.
set -uo pipefail

cd "$(git rev-parse --show-toplevel)" || exit 1

ALLOWLIST="tool/secrets_allowlist.txt"

# Motifs à forte valeur : peu de faux positifs, jamais légitimes dans le code.
PATTERNS=(
  'AIza[0-9A-Za-z_-]{35}'                        # clé d'API Google
  'AKIA[0-9A-Z]{16}'                             # clé AWS
  'ghp_[A-Za-z0-9]{36}'                          # jeton GitHub
  'github_pat_[A-Za-z0-9_]{22,}'                 # jeton GitHub (nouveau format)
  'xox[abprs]-[A-Za-z0-9-]{10,}'                 # jeton Slack
  '(sk|rk)_live_[A-Za-z0-9]{10,}'                # clé Stripe de production
  'BEGIN [A-Z ]*PRIVATE KEY'                     # clé privée
  '[a-z][a-z0-9+.-]*://[^/[:space:]:]+:[^/[:space:]@]+@'  # identifiants dans une URL
  '(password|passwd|secret|api[_-]?key|apikey|access[_-]?token)[[:space:]]*[:=][[:space:]]*.?["'"'"'][^"'"'"'$]{8,}["'"'"']'
)

# mapfile n'existe pas dans le bash 3.2 livré avec macOS : boucle portable.
files=()
if [ "$#" -gt 0 ]; then
  files=("$@")
else
  while IFS= read -r staged; do
    [ -n "$staged" ] && files+=("$staged")
  done < <(git diff --cached --name-only --diff-filter=ACM)
fi

[ "${#files[@]}" -eq 0 ] && exit 0

# Une ligne contenant un fragment de la liste d'exceptions est ignorée.
allowed() {
  [ -f "$ALLOWLIST" ] || return 1
  while IFS= read -r entry; do
    case "$entry" in '' | '#'*) continue ;; esac
    case "$1" in *"$entry"*) return 0 ;; esac
  done < "$ALLOWLIST"
  return 1
}

hits=""
for file in "${files[@]}"; do
  [ -f "$file" ] || continue
  # Fichiers binaires et dossiers générés : rien à y lire.
  case "$file" in
    build/* | ios/Pods/* | */build/* | .dart_tool/* | *.png | *.jpg | *.jpeg | *.webp | *.ttf | *.otf | *.keystore | *.jks | *.lock) continue ;;
  esac

  for pattern in "${PATTERNS[@]}"; do
    while IFS= read -r hit; do
      [ -n "$hit" ] || continue
      allowed "$hit" && continue
      hits+="  $file:$(echo "$hit" | cut -c1-180)"$'\n'
    done < <(grep -nEi -- "$pattern" "$file" 2>/dev/null)
  done
done

hits=$(printf '%s' "$hits" | sort -u)

found=0
if [ -n "$hits" ]; then
  found=1
  echo "⛔ Secret possible détecté :"
  echo
  printf '%s\n' "$hits"
fi

if [ "$found" -eq 1 ]; then
  cat <<'MSG'

Si c'est un vrai secret : sors-le du code (variable d'environnement, fichier
non suivi, secret côté serveur) avant de committer. S'il a déjà été poussé,
change-le : l'historique Git le garde pour toujours.

Si c'est un faux positif ou une valeur publique assumée, ajoute la portion de
ligne concernée à tool/secrets_allowlist.txt, avec un commentaire qui explique
pourquoi elle est sans risque.
MSG
  exit 1
fi

exit 0
