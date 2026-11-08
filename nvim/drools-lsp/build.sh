#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
BUILD_DIR="${DROOLS_LSP_BUILD_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/nvim/drools-lsp-build}"
REPO_URL="${KIE_TOOLS_REPO:-https://github.com/apache/incubator-kie-tools.git}"
COMMIT="${KIE_TOOLS_COMMIT:-f3fe2616b7681438c5d2288ee8eaa4c5dcb29b05}"
PATCH="$SCRIPT_DIR/drools-lsp.patch"
OUT="$DATA_DIR/drools-lsp/drools-lsp-server-jar-with-dependencies.jar"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

command -v git >/dev/null || die "git not found"
command -v mvn >/dev/null || die "mvn not found"
command -v java >/dev/null || die "java not found"
[ -f "$PATCH" ] || die "patch not found: $PATCH"

mkdir -p "$(dirname "$BUILD_DIR")"

if [ ! -e "$BUILD_DIR/.git" ]; then
  printf 'Cloning %s (sparse)...\n' "$REPO_URL"
  git clone --filter=blob:none --sparse --no-checkout "$REPO_URL" "$BUILD_DIR"
fi

cd "$BUILD_DIR"
git fetch --depth=1 origin "$COMMIT"
# Set the sparse paths before checking out: checking out first would pull the
# whole tree, which is unnecessary for this build.
git sparse-checkout set \
  packages/drools-lsp \
  packages/maven-base \
  packages/drools-and-kogito \
  packages/root-env
git checkout --detach "$COMMIT"
git reset --hard "$COMMIT"
git clean -fdxq

git apply --check "$PATCH"
git apply "$PATCH"

MAVEN_BASE_DIR="packages/drools-lsp/node_modules/@kie-tools/maven-base"
mkdir -p "$MAVEN_BASE_DIR"
cp packages/maven-base/pom.xml.template "$MAVEN_BASE_DIR/pom.xml"
cp packages/maven-base/not-reproducible-plugins.properties "$MAVEN_BASE_DIR/not-reproducible-plugins.properties"

cd packages/drools-lsp
mvn -q -pl drools-lsp-server -am package \
  -DskipTests \
  -Drevision=1.0.1-SNAPSHOT \
  -Dversion.org.kie.kogito=10.2.0 \
  -Dreproducible=false

mkdir -p "$(dirname "$OUT")"
install -m 0644 \
  drools-lsp-server/target/drools-lsp-server-jar-with-dependencies.jar \
  "$OUT"
printf 'Installed %s\n' "$OUT"
