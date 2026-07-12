#!/bin/sh
set -e

HOST="redis"

redis-cli -h "$HOST" SET "draft:chapter:chapter_001:user:user_001" \
  "Le vent froid descendait des Monts Noirs lorsque Aelric franchit les portes de Valcor." \
  EX 86400

redis-cli -h "$HOST" SET "cache:project:project_001" \
  '{"id":"project_001","title":"Les Chroniques de Valcor","owner_id":"user_001"}' \
  EX 3600

redis-cli -h "$HOST" ZADD "popular:characters" \
  120 "character_001" \
  95 "character_002" \
  72 "character_003" \
  54 "character_004"

redis-cli -h "$HOST" HSET "session:user_001" \
  user_id "user_001" \
  active_project "project_001" \
  role "owner"

redis-cli -h "$HOST" SADD "project:project_001:online_users" "user_001" "user_002"

echo "Redis seed applied."
