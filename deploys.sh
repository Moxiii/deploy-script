#!/bin/bash

set -e

WEB_DIR="/home/ubuntu/web"
PROJECT_NAME="$1"
REPO_URL="$2"

if [ -z "$PROJECT_NAME" ] || [ -z "$REPO_URL" ]; then
    echo "Usage: $0 <project> <git-repository>"
    exit 1
fi

PROJECT_DIR="$WEB_DIR/$PROJECT_NAME"

if [[ "$PROJECT_NAME" == */* || "$PROJECT_NAME" == .* ]]; then
    echo "Nom de projet invalide : $PROJECT_NAME"
    exit 1
fi

if [ ! -d "$PROJECT_DIR" ]; then

    echo "==> Projet inexistant : $PROJECT_NAME"

    SIMILAR=$(find "$WEB_DIR" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -printf '%f\n' 2>/dev/null |
        grep -iE "${PROJECT_NAME:0:4}" || true)

    if [ -n "$SIMILAR" ]; then
        echo "ERREUR : projet similaire détecté :"
        echo "$SIMILAR"
        exit 1
    fi

    echo "==> Clonage du dépôt"
    git clone "$REPO_URL" "$PROJECT_DIR"

else

    echo "==> Projet existant : $PROJECT_DIR"

    cd "$PROJECT_DIR"

    if [ ! -d ".git" ]; then
        echo "ERREUR : $PROJECT_DIR existe mais n'est pas un dépôt Git."
        exit 1
    fi

    echo "==> Fetch"
    git fetch origin

    echo "==> Reset sur prod"
    git reset --hard origin/prod

fi

cd "$PROJECT_DIR"

echo "==> Projet : $PROJECT_DIR"

echo "==> Build / deploy"
docker compose \
    -f compose.prod.yaml up -d \
     --build \
     --remove-orphans

echo "==> Nettoyage"
docker image prune -f

echo "==> Deployment terminé"