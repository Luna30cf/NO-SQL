// 1. Tous les personnages d’un chapitre
MATCH (chapter:Chapter {id: "chapter_001"})-[:MENTIONS]->(character:Character)
RETURN character.id, character.name, character.role
ORDER BY character.name;


// 2. Tous les personnages présents dans les scènes d’un chapitre
MATCH (chapter:Chapter {id: "chapter_001"})
      -[:HAS_SCENE]->(:Scene)
      -[:FEATURES_CHARACTER]->(character:Character)
RETURN DISTINCT character.id, character.name
ORDER BY character.name;


// 3. Les alliés directs d’Aelric
MATCH (:Character {id: "character_001"})
      -[relation:ALLY_OF]-
      (ally:Character)
RETURN ally.id, ally.name, relation.since, relation.trustLevel;


// 4. Les ennemis des alliés d’Aelric
MATCH (:Character {id: "character_001"})
      -[:ALLY_OF]-
      (ally:Character)
      -[:ENEMY_OF]-
      (enemy:Character)
RETURN DISTINCT enemy.id, enemy.name;


// 5. Le chemin le plus court entre deux personnages
MATCH path = shortestPath(
    (:Character {id: "character_004"})
    -[*..6]-
    (:Character {id: "character_003"})
)
RETURN path;


// 6. Les membres de chaque faction
MATCH (character:Character)-[relation:MEMBER_OF]->(faction:Faction)
RETURN faction.name, character.name, relation.rank
ORDER BY faction.name, character.name;


// 7. Les objets possédés par les personnages
MATCH (character:Character)-[:OWNS]->(item:Item)
RETURN character.name, item.name, item.type
ORDER BY character.name;


// 8. Chronologie des événements
MATCH (event:Event {project_id: "project_001"})
OPTIONAL MATCH (event)-[:PRECEDES]->(next:Event)
RETURN event.id, event.name, event.date, collect(next.name) AS nextEvents
ORDER BY event.date;


// 9. Participants à la bataille
MATCH (character:Character)
      -[relation:PARTICIPATED_IN]->
      (:Event {id: "event_004"})
RETURN character.name, relation.role
ORDER BY character.name;


// 10. Lieux utilisés dans les scènes
MATCH (scene:Scene)-[:TAKES_PLACE_IN]->(location:Location)
RETURN scene.name, location.name, location.type
ORDER BY scene.name;


// 11. Réseau relationnel d’un personnage sur deux niveaux
MATCH path =
    (:Character {id: "character_001"})
    -[*1..2]-
    (related)
RETURN DISTINCT path
LIMIT 50;


// 12. Détection d’une incohérence familiale simple
MATCH (a:Character)-[:SIBLING_OF]->(b:Character)
WHERE (a)-[:PARENT_OF]->(b)
RETURN a.name, b.name;