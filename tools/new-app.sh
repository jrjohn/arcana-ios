#!/usr/bin/env bash
# Start a new iOS product from this repo's full layered skeleton.
#
#   tools/new-app.sh billing-app ~/Documents/projects/billing-app
#   BUNDLE_ID=com.acme.billing tools/new-app.sh billing-app ~/Documents/projects/billing-app
#
# Copies the committed tree (git archive HEAD), so the product keeps AGENTS.md, CLAUDE.md,
# tools/ (scaffolding + hook + arch-check), the Jenkinsfile and the arch-qube gate. Creating a
# fresh Xcode project and copying a few Sources/ folders into it loses all of that (AGENTS.md §1).
#
# No --no-demo option: the template has no demo-only module. The User feature is the worked
# example tools/new-feature.sh copies, and its anchors (AppDependencies, AppRoute, NavGraph)
# live in it. Replace it feature by feature, not by deleting layers.
set -euo pipefail

[ $# -eq 2 ] || { echo "usage: [BUNDLE_ID=com.acme.x] $0 <app-name> <dest-dir>" >&2; exit 1; }
APP="$1"
DEST="$2"
[[ "$APP" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]] || { echo "app-name: lower-case letters/digits, words joined by '-' (it becomes the Xcode project, target, scheme and CI names)" >&2; exit 1; }
case "$APP" in arcana|arcana-ios|ios-app) echo "app-name must differ from the template's own names" >&2; exit 1 ;; esac
[ ! -e "$DEST" ] || { echo "$DEST already exists — refusing to overwrite" >&2; exit 1; }
command -v perl >/dev/null || { echo "perl is required" >&2; exit 1; }

APP_US="$(printf '%s' "$APP" | tr '-' '_')"                                         # Swift module name
TITLE="$(printf '%s' "$APP" | perl -pe 's/(^|-)([a-z])/($1?" ":"").uc($2)/ge')"     # billing-app → Billing App
BUNDLE_ID="${BUNDLE_ID:-com.example.$(printf '%s' "$APP" | tr -d '-')}"
[[ "$BUNDLE_ID" =~ ^[A-Za-z][A-Za-z0-9-]*(\.[A-Za-z0-9-]+)+$ ]] || { echo "BUNDLE_ID '$BUNDLE_ID' is not a reverse-DNS identifier" >&2; exit 1; }
[ "$BUNDLE_ID" != "com.arcana.example" ] || { echo "BUNDLE_ID must differ from the template's" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
git -C "$ROOT" diff --quiet HEAD -- AGENTS.md tools/ || echo "note: uncommitted changes in AGENTS.md/tools are NOT copied (git archive HEAD)" >&2

mkdir -p "$DEST"
git -C "$ROOT" archive HEAD | tar -x -C "$DEST"
SRC_SHA="$(git -C "$ROOT" rev-parse --short HEAD)"
cd "$DEST"

# ---- Paths. The Xcode project, the app/test folders (synchronized root groups referenced by
# path from project.pbxproj) and the files named after the module are renamed; the pbxproj text
# is rewritten below, so its folder references follow. Per-user Xcode state is dropped.
find . -name xcuserdata -type d -prune -exec rm -rf {} +
find . -depth -name '*arcana-ios*' -not -path './.git/*' -not -path './tools/*' | while IFS= read -r p; do
    d="$(dirname "$p")"; b="$(basename "$p")"; mv "$p" "$d/${b//arcana-ios/$APP}"
done
find . -depth -name '*arcana_ios*' -not -path './.git/*' -not -path './tools/*' | while IFS= read -r p; do
    d="$(dirname "$p")"; b="$(basename "$p")"; mv "$p" "$d/${b//arcana_ios/$APP_US}"
done

# ---- Product identity. Every place the template name is load-bearing:
#  1. Xcode project / app target / scheme / product name "arcana-ios" (project.pbxproj,
#     Jenkinsfile, Makefile, fastlane, Package.swift path) and test targets arcana-iosTests/UITests.
#  2. Swift module arcana_ios (`@testable import arcana_ios` in every test, the App struct).
#  3. Bundle identifier com.arcana.example (+ .tests/.uitests) in project.pbxproj, fastlane
#     Appfile/Matchfile. The SwiftData store has no explicit name (default.store) and lives in
#     the app's sandbox, which is keyed by the bundle id — the new bundle id gives it its own store.
#  4. Sonar key "ios-app" / name "iOS App", the Jenkins PROJECT_NAME and per-build arch-qube
#     container arcana-arch-qube-ios-* (two products on one Jenkins must not `docker rm -f`
#     each other's containers), the GitHub URL in the Jenkins checkout stage.
#  5. Home-screen display name (CFBundleDisplayName, added below; otherwise the target name).
# Not renamed on purpose: the Arcana* layer folders and type names (ArcanaCore, ArcanaTheme, …)
# — they are the architecture, not the product; arcana.boo (registry); fastlane team_id.
# tools/ is excluded: these scripts describe the template and must keep working in the product.
TEXT_FILES="$(grep -rIl -e arcana-ios -e arcana_ios -e com.arcana.example -e ios-app -e "iOS App" . --exclude-dir=.git --exclude-dir=tools --exclude=CHANGELOG.md || true)"
printf '%s\n' "$TEXT_FILES" | while IFS= read -r f; do [ -n "$f" ] && perl -pi -e "
    s/arcana-arch-qube-ios-/${APP}-arch-qube-/g;
    s/arcana-ios/${APP}/g;
    s/arcana_ios/${APP_US}/g;
    s/com\\.arcana\\.example/${BUNDLE_ID}/g;
    s/\\bios-app\\b/${APP}/g;
    s/iOS App/${TITLE}/g;
" "$f"; done
PBX="${APP}.xcodeproj/project.pbxproj"
perl -pi -e "s/^(\\s*)PRODUCT_BUNDLE_IDENTIFIER = \"\\Q${BUNDLE_ID}\\E\";\\n/\$1INFOPLIST_KEY_CFBundleDisplayName = \"${TITLE}\";\\n\$&/" "$PBX"
[ "$(grep -c "INFOPLIST_KEY_CFBundleDisplayName = \"${TITLE}\"" "$PBX")" = 2 ] || { echo "new-app: could not set the display name in $PBX" >&2; exit 1; }

LEFT="$(grep -rInE --exclude-dir=.git --exclude-dir=tools --exclude=CHANGELOG.md "arcana-ios|arcana_ios|com\\.arcana\\.example|\\bios-app\\b|iOS App" . || true)"
LEFT_PATHS="$(find . -name '*arcana-ios*' -o -name '*arcana_ios*' | grep -v '^./tools/' || true)"
if [ -n "$LEFT$LEFT_PATHS" ]; then
    echo "new-app: template identities still present after rename:" >&2
    printf '%s\n%s\n' "$LEFT" "$LEFT_PATHS" | head >&2
    exit 1
fi

# ---- Fresh history: version 0.1.0 (build 1), empty changelog.
rm -f CHANGELOG.md
printf '{\n  ".": "0.1.0"\n}\n' > .release-please-manifest.json
perl -pi -e 's/MARKETING_VERSION = [^;]+;/MARKETING_VERSION = 0.1.0;/; s/CURRENT_PROJECT_VERSION = [^;]+;/CURRENT_PROJECT_VERSION = 1;/' "$PBX"
perl -pi -e "s/^(\\s*VERSION\\s*=\\s*)'[^']*'/\${1}'0.1.0'/" Jenkinsfile
perl -0pi -e 's/("version": ")[^"]+"/${1}0.1.0"/' package.json
grep -q "MARKETING_VERSION = 0.1.0;" "$PBX" || { echo "new-app: could not reset MARKETING_VERSION" >&2; exit 1; }

cat >> AGENTS.md <<EOT

## Origin

Created from arcana-ios @ \`${SRC_SHA}\` by \`tools/new-app.sh\` (Xcode project/target/scheme
\`${APP}\`, module \`${APP_US}\`, bundle id \`${BUNDLE_ID}\`, display name "${TITLE}", Sonar
key and Jenkins names renamed). Set your own fastlane \`team_id\` and the Jenkins checkout URL if
the repo is not github.com/jrjohn/${APP}. The layers, rules and definition of done above apply
unchanged; read "arcana-ios" in them as "${APP}". Replace the User example through
\`AppDependencies.swift\`, \`AppRoute.swift\` and \`NavGraph.swift\`, not by flattening.
EOT

git init -q
tools/install-hooks.sh >/dev/null
git add -A
# --no-verify only for this import commit: every file counts as "added" here, so the hook would
# judge the template's own entry file (<app>/<app>App.swift, outside Sources/) and the stray
# legacy .swift files under the .xcodeproj as new flat files. The template itself passes
# arch-check; every later commit in the product goes through the hook.
git -c user.name="${GIT_AUTHOR_NAME:-new-app}" -c user.email="${GIT_AUTHOR_EMAIL:-new-app@localhost}" \
    commit -q --no-verify -m "chore: start ${APP} from arcana-ios ${SRC_SHA}"

echo "created $DEST (${APP}, ${BUNDLE_ID}) from arcana-ios ${SRC_SHA}; hooks: $(git config core.hooksPath)"
echo "next: cd $DEST && tools/new-feature.sh <Name>"
