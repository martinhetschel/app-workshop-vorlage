#!/usr/bin/env bash
# Einrichtung für die Workshop-App, gedacht für die Google Cloud Shell.
#
# Das Skript richtet alles ein, was für den automatischen Deploy nötig ist, und trägt
# die Werte in dein GitHub-Repo ein. Es lässt sich beliebig oft starten: Was schon da
# ist, bleibt, was fehlt oder falsch ist, wird ergänzt oder korrigiert.
#
#   git clone https://github.com/martinhetschel/app-workshop-vorlage
#   cd app-workshop-vorlage
#   bash scripts/setup-wif.sh
#
# Optional mit Angaben: bash setup.sh PROJEKT-ID NAME/REPO
#
# Es wird kein Schlüssel erzeugt. Der Deploy meldet sich per Workload Identity Federation
# an: GitHub beweist bei jedem Lauf kurzzeitig, aus welchem Repo er kommt.

set -euo pipefail

POOL="github-pool"
PROVIDER="github-provider"
SA_NAME="github-deployer"
STATE_FILE="$HOME/.app-workshop-setup"
FIRESTORE_LOCATION="eur3"
WEBAPP_NAME="Meine App"

say()  { printf '\n==> %s\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '    ACHTUNG: %s\n' "$*" >&2; }
die()  { printf '\nFEHLER: %s\n' "$*" >&2; exit 1; }

# Versucht einen Befehl mehrmals, weil Google neue Konten und Rechte erst nach einigen
# Sekunden überall kennt. Bei endgültigem Scheitern wird die letzte Meldung gezeigt.
retry() { # retry ANZAHL BEFEHL...
  local max=$1 i=1 out
  shift
  while true; do
    if out=$("$@" 2>&1); then return 0; fi
    if [ "$i" -ge "$max" ]; then printf '%s\n' "$out" >&2; return 1; fi
    i=$((i + 1))
    sleep 6
  done
}

ask() { # ask VARIABLE "Frage" "Vorgabe"
  local var=$1 question=$2 default=${3:-} answer=""
  if [ -r /dev/tty ]; then
    read -r -p "$question${default:+ [$default]}: " answer </dev/tty || true
  fi
  printf -v "$var" '%s' "${answer:-$default}"
}

yes_no() { # yes_no "Frage" -> 0 bei Ja (Vorgabe Ja)
  local answer=""
  if [ -r /dev/tty ]; then
    read -r -p "$1 [J/n]: " answer </dev/tty || true
  fi
  case "${answer:-j}" in [jJyY]*) return 0 ;; *) return 1 ;; esac
}

# --- Werkzeuge prüfen --------------------------------------------------------------
for tool in gcloud curl python3 git; do
  command -v "$tool" >/dev/null 2>&1 || die "Das Werkzeug \"$tool\" fehlt. Dieses Skript ist für die Google Cloud Shell gedacht."
done
gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null | grep -q . \
  || die "Du bist in gcloud nicht angemeldet. In der Cloud Shell passiert das automatisch, sonst: gcloud auth login"

# --- Eingaben: Argumente, sonst letzte Eingabe, sonst Nachfrage -------------------------
LAST_PROJECT=""; LAST_REPO=""
if [ -f "$STATE_FILE" ]; then
  LAST_PROJECT=$(sed -n 's/^PROJECT_ID=//p' "$STATE_FILE" | head -n1)
  LAST_REPO=$(sed -n 's/^GITHUB_REPO=//p' "$STATE_FILE" | head -n1)
fi
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || true)

PROJECT_ID="${1:-${PROJECT_ID:-}}"
GITHUB_REPO="${2:-${GITHUB_REPO:-}}"
if [ -z "$PROJECT_ID" ]; then
  ask PROJECT_ID "Projekt-ID deines Firebase-Projekts" "${LAST_PROJECT:-$CURRENT_PROJECT}"
fi
if [ -z "$GITHUB_REPO" ]; then
  ask GITHUB_REPO "Dein GitHub-Repo im Format name/repo (genau so geschrieben wie bei GitHub)" "$LAST_REPO"
fi

# Eingaben aufräumen: auch eine kopierte Adresse oder ein ".git" am Ende ist in Ordnung
GITHUB_REPO=$(printf '%s' "$GITHUB_REPO" | sed -E 's#^(https?://)?(www\.)?github\.com/##; s#\.git$##; s#/+$##; s#^[[:space:]]+|[[:space:]]+$##g')
PROJECT_ID=$(printf '%s' "$PROJECT_ID" | tr -d '[:space:]')

[ -n "$PROJECT_ID" ] || die "Es fehlt die Projekt-ID."
printf '%s' "$GITHUB_REPO" | grep -Eq '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' \
  || die "Das GitHub-Repo muss so aussehen: name/repo (zum Beispiel anna-meier/meine-app). Eingegeben wurde: \"$GITHUB_REPO\""

printf 'PROJECT_ID=%s\nGITHUB_REPO=%s\n' "$PROJECT_ID" "$GITHUB_REPO" > "$STATE_FILE"

SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

say "Einrichtung für Projekt $PROJECT_ID und Repo $GITHUB_REPO"
gcloud projects describe "$PROJECT_ID" >/dev/null 2>&1 \
  || die "Das Projekt \"$PROJECT_ID\" gibt es nicht oder du hast keinen Zugriff. Die Projekt-ID steht in der Firebase-Konsole unter Projekteinstellungen."
gcloud config set project "$PROJECT_ID" >/dev/null 2>&1
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
info "Projektnummer: $PROJECT_NUMBER"

# --- 1. Dienste einschalten --------------------------------------------------------------
say "1/8 Google-Dienste einschalten (das dauert ein bis zwei Minuten)"
gcloud services enable \
  iam.googleapis.com iamcredentials.googleapis.com sts.googleapis.com \
  cloudresourcemanager.googleapis.com serviceusage.googleapis.com \
  firebase.googleapis.com firebasehosting.googleapis.com \
  firestore.googleapis.com firebaserules.googleapis.com \
  --project="$PROJECT_ID" >/dev/null
info "Fertig."

# --- 2. Dienstkonto ----------------------------------------------------------------------
say "2/8 Dienstkonto $SA_NAME"
if gcloud iam service-accounts describe "$SA_EMAIL" >/dev/null 2>&1; then
  info "Gibt es schon."
else
  gcloud iam service-accounts create "$SA_NAME" --display-name="GitHub Deploy" >/dev/null
  retry 10 gcloud iam service-accounts describe "$SA_EMAIL" || die "Das Dienstkonto wurde angelegt, ist aber noch nicht abrufbar. Bitte das Skript in einer Minute noch einmal starten."
  info "Angelegt."
fi

# --- 3. Rechte des Dienstkontos ----------------------------------------------------------
say "3/8 Rechte für das Dienstkonto"
for ROLE in roles/firebase.admin roles/serviceusage.apiKeysViewer roles/serviceusage.serviceUsageConsumer; do
  retry 8 gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" --role="$ROLE" --condition=None \
    || die "Das Recht $ROLE konnte nicht vergeben werden. Bist du Inhaber des Projekts?"
  info "$ROLE"
done

# --- 4. Pool und Provider ----------------------------------------------------------------
say "4/8 Anmeldung für GitHub (Pool und Provider), nur für das Repo $GITHUB_REPO"
POOL_STATE=$(gcloud iam workload-identity-pools describe "$POOL" --location=global --format='value(state)' 2>/dev/null || true)
case "$POOL_STATE" in
  "") gcloud iam workload-identity-pools create "$POOL" --location=global --display-name="GitHub Pool" >/dev/null
      info "Pool angelegt." ;;
  DELETED) gcloud iam workload-identity-pools undelete "$POOL" --location=global >/dev/null
      info "Gelöschten Pool wiederhergestellt." ;;
  *) info "Pool gibt es schon." ;;
esac

ATTRIBUTE_MAPPING="google.subject=assertion.sub,attribute.repository=assertion.repository"
ATTRIBUTE_CONDITION="assertion.repository=='${GITHUB_REPO}'"
PROVIDER_STATE=$(gcloud iam workload-identity-pools providers describe "$PROVIDER" \
  --workload-identity-pool="$POOL" --location=global --format='value(state)' 2>/dev/null || true)
case "$PROVIDER_STATE" in
  "")
    retry 6 gcloud iam workload-identity-pools providers create-oidc "$PROVIDER" \
      --workload-identity-pool="$POOL" --location=global \
      --issuer-uri="https://token.actions.githubusercontent.com" \
      --attribute-mapping="$ATTRIBUTE_MAPPING" \
      --attribute-condition="$ATTRIBUTE_CONDITION" >/dev/null \
      || die "Der Provider konnte nicht angelegt werden."
    info "Provider angelegt." ;;
  *)
    if [ "$PROVIDER_STATE" = "DELETED" ]; then
      gcloud iam workload-identity-pools providers undelete "$PROVIDER" \
        --workload-identity-pool="$POOL" --location=global >/dev/null
    fi
    # Bei jedem Lauf angleichen, damit ein geändertes Repo sofort gilt
    retry 6 gcloud iam workload-identity-pools providers update-oidc "$PROVIDER" \
      --workload-identity-pool="$POOL" --location=global \
      --attribute-mapping="$ATTRIBUTE_MAPPING" \
      --attribute-condition="$ATTRIBUTE_CONDITION" >/dev/null \
      || die "Der Provider konnte nicht aktualisiert werden."
    info "Provider aktualisiert." ;;
esac

# --- 5. Repo darf das Dienstkonto verwenden ------------------------------------------------
say "5/8 Dem Repo erlauben, das Dienstkonto zu verwenden"
PRINCIPAL_PREFIX="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL}/attribute.repository/"
retry 6 gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --role="roles/iam.workloadIdentityUser" \
  --member="${PRINCIPAL_PREFIX}${GITHUB_REPO}" >/dev/null \
  || die "Die Berechtigung für das Repo konnte nicht gesetzt werden."
info "Erlaubt: $GITHUB_REPO"

# Frühere Repos aus einem anderen Lauf entfernen, damit nur das aktuelle Repo Zugriff hat
OLD_MEMBERS=$(gcloud iam service-accounts get-iam-policy "$SA_EMAIL" --format=json 2>/dev/null \
  | PREFIX="$PRINCIPAL_PREFIX" KEEP="${PRINCIPAL_PREFIX}${GITHUB_REPO}" python3 -c '
import json, os, sys
policy = json.load(sys.stdin)
for b in policy.get("bindings", []):
    if b.get("role") == "roles/iam.workloadIdentityUser":
        for m in b.get("members", []):
            if m.startswith(os.environ["PREFIX"]) and m != os.environ["KEEP"]:
                print(m)
' || true)
if [ -n "$OLD_MEMBERS" ]; then
  while IFS= read -r member; do
    [ -n "$member" ] || continue
    gcloud iam service-accounts remove-iam-policy-binding "$SA_EMAIL" \
      --role="roles/iam.workloadIdentityUser" --member="$member" >/dev/null 2>&1 \
      && info "Altes Repo entfernt: ${member#"$PRINCIPAL_PREFIX"}"
  done <<< "$OLD_MEMBERS"
fi

WIF_PROVIDER="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL}/providers/${PROVIDER}"

# --- 6. Firebase: Projekt, Hosting-Seite, Datenbank ------------------------------------------
TOKEN=$(gcloud auth print-access-token)
API_CODE=""; API_BODY=""
api() { # api METHOD URL [JSON-KÖRPER]
  local out
  out=$(curl -sS -X "$1" \
    -H "Authorization: Bearer ${TOKEN}" -H "x-goog-user-project: ${PROJECT_ID}" \
    -H "Content-Type: application/json" ${3:+-d "$3"} \
    -w '\n%{http_code}' "$2" 2>&1) || { API_CODE="000"; API_BODY="$out"; return 0; }
  API_CODE=$(printf '%s' "$out" | tail -n1)
  API_BODY=$(printf '%s' "$out" | sed '$d')
}

say "6/8 Firebase-Projekt, Hosting-Seite und Datenbank"
api GET "https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}"
if [ "$API_CODE" != "200" ]; then
  die "Das Projekt \"$PROJECT_ID\" ist noch kein Firebase-Projekt. Bitte in der Firebase-Konsole (console.firebase.google.com) über \"Projekt hinzufügen\" das vorhandene Google-Cloud-Projekt auswählen oder ein neues anlegen und das Skript noch einmal starten."
fi
info "Firebase-Projekt gefunden."

api GET "https://firebasehosting.googleapis.com/v1beta1/projects/${PROJECT_ID}/sites/${PROJECT_ID}"
if [ "$API_CODE" = "200" ]; then
  info "Hosting-Seite ${PROJECT_ID}.web.app gibt es schon."
else
  api POST "https://firebasehosting.googleapis.com/v1beta1/projects/${PROJECT_ID}/sites?siteId=${PROJECT_ID}" '{}'
  case "$API_CODE" in
    200|409) info "Hosting-Seite ${PROJECT_ID}.web.app angelegt." ;;
    *) warn "Die Hosting-Seite konnte nicht angelegt werden (Antwort $API_CODE). Der erste Deploy versucht es selbst noch einmal." ;;
  esac
fi

if gcloud firestore databases describe --database='(default)' --format='value(name)' >/dev/null 2>&1; then
  info "Firestore-Datenbank gibt es schon."
else
  if gcloud firestore databases create --database='(default)' --location="$FIRESTORE_LOCATION" --type=firestore-native >/dev/null 2>&1; then
    info "Firestore-Datenbank in Europa ($FIRESTORE_LOCATION) angelegt."
  else
    warn "Die Datenbank konnte nicht angelegt werden. Bitte in der Firebase-Konsole unter Firestore Database anlegen: Standort eur3, Produktionsmodus."
  fi
fi

# --- 7. Web-App-Werte holen --------------------------------------------------------------------
say "7/8 Web-App-Werte aus Firebase holen"
WEB_APP_ID=""
find_web_app() {
  api GET "https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/webApps"
  [ "$API_CODE" = "200" ] || return 1
  WEB_APP_ID=$(printf '%s' "$API_BODY" | python3 -c '
import json, sys
apps = json.load(sys.stdin).get("apps", [])
print(apps[0]["appId"] if apps else "")
')
}
find_web_app || true
if [ -z "$WEB_APP_ID" ]; then
  api POST "https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/webApps" "{\"displayName\":\"${WEBAPP_NAME}\"}"
  if [ "$API_CODE" = "200" ]; then
    for _ in $(seq 1 20); do
      sleep 3
      find_web_app && [ -n "$WEB_APP_ID" ] && break
    done
  fi
fi

FIREBASE_CONFIG=""
if [ -n "$WEB_APP_ID" ]; then
  api GET "https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/webApps/${WEB_APP_ID}/config"
  if [ "$API_CODE" = "200" ]; then FIREBASE_CONFIG="$API_BODY"; fi
fi
if [ -n "$FIREBASE_CONFIG" ]; then
  info "Web-App $WEB_APP_ID gefunden."
else
  warn "Die Web-App-Werte konnten nicht geholt werden. Bitte in der Firebase-Konsole unter Projekteinstellungen, Web-App kopieren und später Claude Code in die Datei environment.ts eintragen lassen."
fi

# --- 8. Werte ins Repo eintragen --------------------------------------------------------------------
# Trägt die Werte in .github/workflows/deploy.yml, .firebaserc und src/environments/environment.ts ein.
# Es werden die Werte ersetzt, nicht nur Platzhalter, deshalb funktioniert das auch bei jedem weiteren Lauf.
fill_repo() { # fill_repo VERZEICHNIS
  FILL_DIR="$1" FILL_PROJECT="$PROJECT_ID" FILL_PROVIDER="$WIF_PROVIDER" FILL_SA="$SA_EMAIL" \
  FILL_CONFIG="$FIREBASE_CONFIG" python3 - <<'PY'
import json, os, re, sys

root = os.environ["FILL_DIR"]
project = os.environ["FILL_PROJECT"]
provider = os.environ["FILL_PROVIDER"]
sa = os.environ["FILL_SA"]
config_text = os.environ.get("FILL_CONFIG", "").strip()

def read(path):
    with open(os.path.join(root, path), encoding="utf-8") as f:
        return f.read()

def write(path, text):
    with open(os.path.join(root, path), "w", encoding="utf-8") as f:
        f.write(text)

workflow = ".github/workflows/deploy.yml"
if not os.path.exists(os.path.join(root, workflow)):
    print("FEHLT:" + workflow)
    sys.exit(3)

text = read(workflow)
text = re.sub(r"(?m)^(\s*project_id:\s*).*$", lambda m: m.group(1) + project, text)
text = re.sub(r"(?m)^(\s*workload_identity_provider:\s*).*$", lambda m: m.group(1) + provider, text)
text = re.sub(r"(?m)^(\s*service_account:\s*).*$", lambda m: m.group(1) + sa, text)
text = re.sub(r"--project=\S+", "--project=" + project, text)
write(workflow, text)

write(".firebaserc", json.dumps({"projects": {"default": project}}, indent=2) + "\n")

if config_text:
    cfg = json.loads(config_text)
    keys = ["apiKey", "authDomain", "projectId", "storageBucket", "messagingSenderId", "appId"]
    lines = ["export const environment = {", "  firebase: {"]
    for k in keys:
        lines.append("    %s: %s," % (k, json.dumps(cfg.get(k, ""))))
    lines += ["  },", "};", ""]
    out = "\n".join(lines).replace('"', "'")
    os.makedirs(os.path.join(root, "src/environments"), exist_ok=True)
    write("src/environments/environment.ts", out)
PY
}

say "8/8 Werte in dein GitHub-Repo eintragen"
FILLED="nein"
if ! command -v gh >/dev/null 2>&1; then
  info "Das GitHub-Werkzeug (gh) gibt es hier nicht. Die Werte stehen unten zum Kopieren."
elif yes_no "Soll ich die Werte jetzt direkt in $GITHUB_REPO eintragen und auf main speichern?"; then
  if ! gh auth status >/dev/null 2>&1; then
    info "Du musst dich einmal bei GitHub anmelden. Folge den Hinweisen: Es erscheint ein Code, den du im Browser eingibst."
    gh auth login --hostname github.com --git-protocol https --web || warn "Die Anmeldung bei GitHub hat nicht geklappt."
  fi
  if gh auth status >/dev/null 2>&1; then
    gh auth setup-git >/dev/null 2>&1 || true
    WORKDIR=$(mktemp -d)
    trap 'rm -rf "$WORKDIR"' EXIT
    if gh repo clone "$GITHUB_REPO" "$WORKDIR/repo" -- --depth 1 >/dev/null 2>&1; then
      fill_status=0
      fill_out=$(fill_repo "$WORKDIR/repo") || fill_status=$?
      if [ "$fill_status" -eq 3 ]; then
        warn "In $GITHUB_REPO fehlt ${fill_out#FEHLT:}. Ist das Repo aus der Vorlage entstanden? Die Werte stehen unten zum Kopieren."
      elif [ "$fill_status" -ne 0 ]; then
        warn "Das Eintragen der Werte ist fehlgeschlagen. Die Werte stehen unten zum Kopieren."
      elif [ -z "$(git -C "$WORKDIR/repo" status --porcelain)" ]; then
        info "Im Repo stehen schon die richtigen Werte. Nichts zu tun."
        FILLED="ja"
      else
        git -C "$WORKDIR/repo" add -A
        git -C "$WORKDIR/repo" -c user.name="Workshop-Setup" -c user.email="noreply@users.noreply.github.com" \
          commit -q -m "Werte für Deploy und Firebase eingetragen"
        if git -C "$WORKDIR/repo" push -q origin HEAD 2>/dev/null; then
          info "Eingetragen und gespeichert. Der erste Deploy startet jetzt automatisch."
          FILLED="ja"
        else
          warn "Das Speichern auf GitHub ist fehlgeschlagen (Schutzregeln oder fehlende Rechte?). Die Werte stehen unten zum Kopieren."
        fi
      fi
    else
      warn "Das Repo $GITHUB_REPO konnte nicht geladen werden. Stimmt der Name, und bist du bei GitHub mit dem richtigen Konto angemeldet?"
    fi
  fi
else
  info "Alles klar, die Werte stehen unten zum Kopieren."
fi

# --- Zusammenfassung ---------------------------------------------------------------------------------------
ENV_BLOCK=""
if [ -n "$FIREBASE_CONFIG" ]; then
  ENV_BLOCK=$(printf '%s' "$FIREBASE_CONFIG" | python3 -c '
import json, sys
cfg = json.load(sys.stdin)
for k in ["apiKey", "authDomain", "projectId", "storageBucket", "messagingSenderId", "appId"]:
    print("  %s: %s" % (k, cfg.get(k, "")))
')
fi

VALUES_FILE="$HOME/app-workshop-werte.txt"
{
  echo "Trage diese Werte ein und übernimm die Änderung auf main:"
  echo
  echo "In .github/workflows/deploy.yml:"
  echo "  project_id: ${PROJECT_ID}"
  echo "  workload_identity_provider: ${WIF_PROVIDER}"
  echo "  service_account: ${SA_EMAIL}"
  echo "  und bei firebase-tools deploy: --project=${PROJECT_ID}"
  echo
  echo "In .firebaserc: ${PROJECT_ID}"
  if [ -n "$ENV_BLOCK" ]; then
    echo
    echo "In src/environments/environment.ts (firebase):"
    printf '%s\n' "$ENV_BLOCK"
  fi
} > "$VALUES_FILE"

echo
echo "===================================================================="
echo " Fertig. Die Einrichtung ist abgeschlossen."
echo "===================================================================="
if [ "$FILLED" = "ja" ]; then
  echo " Die Werte sind in deinem Repo eingetragen. Im Reiter Actions von"
  echo " $GITHUB_REPO läuft jetzt der erste Deploy."
else
  echo " Gib Claude Code diesen Auftrag (alles zwischen den Linien kopieren):"
  echo "--------------------------------------------------------------------"
  cat "$VALUES_FILE"
  echo "--------------------------------------------------------------------"
  echo " Der Text liegt auch in der Datei $VALUES_FILE."
fi
echo
echo " Noch von Hand (einmalig, in der Firebase-Konsole):"
echo "   Authentication, Anmeldemethode E-Mail/Passwort einschalten:"
echo "   https://console.firebase.google.com/project/${PROJECT_ID}/authentication/providers"
echo
echo " Deine App erscheint nach dem ersten Deploy unter:"
echo "   https://${PROJECT_ID}.web.app"
echo
