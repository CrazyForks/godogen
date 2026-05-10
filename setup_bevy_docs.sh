#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
DOCS_ROOT=""
RUSTDOC_DIR=""
BEVY_DIR=""
BEVY_WEBSITE_DIR=""
BUILD_TARGET_DIR=""
KEEP_TARGET=0
BEVY_REMOTE="https://github.com/bevyengine/bevy.git"
BEVY_WEBSITE_REMOTE="https://github.com/bevyengine/bevy-website.git"

usage() {
    cat >&2 <<EOF
Usage: $0 [--keep-target] <shared_bevy_docs_dir>

Options:
  --keep-target  Keep Cargo build artifacts after rustdoc is copied.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --keep-target) KEEP_TARGET=1; shift ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "error: unknown option $1" >&2; usage; exit 1 ;;
        *) break ;;
    esac
done

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

resolve_path() {
    local raw_path="$1"
    python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).expanduser().resolve())' "$raw_path"
}

dir_has_entries() {
    local dir_path="$1"
    [ -n "$(find "$dir_path" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]
}

ensure_clean_repo() {
    local repo_dir="$1"
    if [ ! -d "$repo_dir/.git" ]; then
        return 0
    fi

    if [ -n "$(git -C "$repo_dir" status --short --untracked-files=no)" ]; then
        echo "error: $repo_dir has tracked local changes; refusing to update it" >&2
        exit 1
    fi
}

clone_or_update_repo() {
    local url="$1"
    local dest="$2"
    local ref="$3"
    local required="$4"

    if [ ! -d "$dest/.git" ]; then
        if [ -e "$dest" ] && dir_has_entries "$dest"; then
            echo "error: $dest exists but is not a git checkout; move it aside or use an empty docs folder." >&2
            exit 1
        fi
        rmdir "$dest" 2>/dev/null || true
        if [ -n "$ref" ]; then
            if remote_tag_exists "$url" "$ref"; then
                git clone --depth 1 --branch "$ref" "$url" "$dest"
                return
            fi

            if [ "$required" = "required" ]; then
                echo "error: could not find required ref $ref in $url" >&2
                exit 1
            fi

            echo "warning: ref $ref not found in $url; cloning default branch" >&2
        fi

        git clone --depth 1 "$url" "$dest"
        return
    fi

    ensure_clean_repo "$dest"

    if [ -z "$ref" ]; then
        git -C "$dest" fetch --depth 1 origin
        return
    fi

    if git -C "$dest" rev-parse -q --verify "refs/tags/$ref" >/dev/null; then
        git -C "$dest" checkout --detach "$ref"
        return
    fi

    if git -C "$dest" fetch --depth 1 origin "refs/tags/$ref:refs/tags/$ref"; then
        git -C "$dest" checkout --detach "$ref"
        return
    fi

    if [ "$required" = "required" ]; then
        echo "error: could not find required ref $ref in $dest" >&2
        exit 1
    fi

    echo "warning: ref $ref not found in $dest; keeping current checkout" >&2
}

remote_tag_exists() {
    local url="$1"
    local ref="$2"
    git ls-remote --exit-code --tags --refs "$url" "refs/tags/$ref" >/dev/null 2>&1
}

latest_stable_tag() {
    local url="$1"
    git ls-remote --tags --refs --sort=-v:refname "$url" 'refs/tags/v*' \
        | awk '{ sub("refs/tags/", "", $2); print $2 }' \
        | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
        | head -n 1
}

ensure_docs_gitignore() {
    local docs_dir="$1"
    mkdir -p "$docs_dir"
    if [ ! -f "$docs_dir/.gitignore" ]; then
        printf '*\n!.gitignore\n' > "$docs_dir/.gitignore"
    fi
}

link_docs_subdir() {
    local docs_dir="$1"
    local shared_root="$2"
    local name="$3"
    local link_path="$docs_dir/$name"
    local shared_path="$shared_root/$name"

    if [ -L "$link_path" ]; then
        if [ "$(resolve_path "$link_path")" = "$shared_path" ]; then
            mkdir -p "$shared_path"
            return 0
        fi
        rm "$link_path"
    elif [ -d "$link_path" ]; then
        if dir_has_entries "$link_path"; then
            if [ -e "$shared_path" ]; then
                if dir_has_entries "$shared_path"; then
                    echo "error: both $link_path and $shared_path contain data; move one side manually." >&2
                    exit 1
                fi
                rmdir "$shared_path"
            fi
            mv "$link_path" "$shared_path"
        else
            rmdir "$link_path"
            mkdir -p "$shared_path"
        fi
    elif [ -e "$link_path" ]; then
        echo "error: $link_path exists and is not a directory or symlink" >&2
        exit 1
    else
        mkdir -p "$shared_path"
    fi

    ln -s "$shared_path" "$link_path"
}

link_skill_docs() {
    local skill_dir="$1"
    local docs_dir="$skill_dir/docs"
    ensure_docs_gitignore "$docs_dir"
    link_docs_subdir "$docs_dir" "$DOCS_ROOT" rustdoc
    link_docs_subdir "$docs_dir" "$DOCS_ROOT" bevy
    link_docs_subdir "$docs_dir" "$DOCS_ROOT" bevy-website
}

sync_rustdoc() {
    local source_doc_root="$1"

    if [ ! -d "$source_doc_root" ]; then
        echo "error: rustdoc output not found at $source_doc_root" >&2
        exit 1
    fi

    mkdir -p "$RUSTDOC_DIR"
    rsync -a --delete "$source_doc_root/" "$RUSTDOC_DIR/"
}

build_rustdoc() {
    CARGO_TARGET_DIR="$BUILD_TARGET_DIR" cargo doc \
        --manifest-path "$BEVY_DIR/Cargo.toml" \
        -p bevy \
        -p bevy_app \
        -p bevy_ecs \
        -p bevy_asset \
        -p bevy_ui \
        --no-deps
    sync_rustdoc "$BUILD_TARGET_DIR/doc"

    if [ "$KEEP_TARGET" -eq 0 ]; then
        echo "Removing Cargo build artifacts from $BUILD_TARGET_DIR"
        rm -rf "$BUILD_TARGET_DIR"

        if [ -d "$BEVY_DIR/target" ] && [ "$(resolve_path "$BEVY_DIR/target")" != "$(resolve_path "$BUILD_TARGET_DIR")" ]; then
            echo "Removing legacy Cargo build artifacts from $BEVY_DIR/target"
            rm -rf "$BEVY_DIR/target"
        fi
    else
        echo "Kept Cargo build artifacts at $BUILD_TARGET_DIR"
    fi
}

DOCS_ROOT="$(resolve_path "$1")"
RUSTDOC_DIR="$DOCS_ROOT/rustdoc"
BEVY_DIR="$DOCS_ROOT/bevy"
BEVY_WEBSITE_DIR="$DOCS_ROOT/bevy-website"
BUILD_TARGET_DIR="${BEVY_DOCS_TARGET_DIR:-$DOCS_ROOT/.bevy-doc-target}"

mkdir -p "$DOCS_ROOT"

echo "Using shared Bevy docs folder: $DOCS_ROOT"
echo "Bevy docs are heavy, about 2 GB after population."
echo "Pass --keep-target to trade about 4 GB more disk for faster rustdoc rebuilds."
echo "Use a separate permanent folder outside this repo."

link_skill_docs "$REPO_ROOT/bevy/skills/bevy-help"

STABLE_TAG="$(latest_stable_tag "$BEVY_REMOTE" || true)"
if [ -z "$STABLE_TAG" ]; then
    echo "error: unable to determine latest stable Bevy tag" >&2
    exit 1
fi

clone_or_update_repo "$BEVY_REMOTE" "$BEVY_DIR" "$STABLE_TAG" required
clone_or_update_repo "$BEVY_WEBSITE_REMOTE" "$BEVY_WEBSITE_DIR" "$STABLE_TAG" optional
build_rustdoc

echo "Configured Bevy docs root: $DOCS_ROOT"
echo "Linked bevy/skills/bevy-help/docs/*"
echo "Populated shallow Bevy repo, Bevy website, and rustdoc for ${STABLE_TAG#v}"
