#!/bin/bash
set -e
COMPOSE="docker compose -f docker-compose.prod.yaml"
PROJECT_PATH="$1"

if [ -z "$PROJECT_PATH" ]; then
  echo "❌ Veuillez spécifier le dossier du projet"
  exit 1
fi

cd "$PROJECT_PATH"

echo "📦 Pull des dernières images..."
docker compose pull || true

echo "🛑 Arrêt des anciens conteneurs..."
docker compose down --remove-orphans

echo "🚀 Lancement des conteneurs..."
docker compose up -d --build

echo "⏳ Attente que tous les services deviennent 'healthy'..."
MAX_WAIT=60
i=0
while [ $i -lt $MAX_WAIT ]; do
  unhealthy=$($COMPOSE --filter "health=unhealthy" -q | wc -l)
  starting=$($COMPOSE --filter "health=starting" -q | wc -l)

  if [ "$unhealthy" -eq 0 ] && [ "$starting" -eq 0 ]; then
    echo "✅ Tous les conteneurs sont 'healthy'."

    echo "🧹 Nettoyage sécurisé des conteneurs/images/volumes inutilisés..."
    docker container prune -f
    docker volume prune -f
    docker image prune -f

    break
  fi

  echo "🕐 En attente... ($i/$MAX_WAIT sec)"
  sleep 2
  i=$((i + 2))
done
if [ $i -ge $MAX_WAIT ]; then
  echo "❌ Les conteneurs ne sont pas devenus sains dans les temps."
  docker compose logs
  exit 1
fi
echo "✅ Déploiement terminé avec succès."
