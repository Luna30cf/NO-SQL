// Supprime uniquement les nœuds parasites sans label
MATCH (n)
WHERE size(labels(n)) = 0
DETACH DELETE n;


// Récupération des nœuds existants
MATCH
    (p:Project {id: "project_001"}),
    (c1:Chapter {id: "chapter_001"}),
    (c2:Chapter {id: "chapter_002"}),
    (s1:Scene {id: "scene_001"}),
    (s2:Scene {id: "scene_002"}),
    (s3:Scene {id: "scene_003"}),
    (aelric:Character {id: "character_001"}),
    (lyra:Character {id: "character_002"}),
    (darian:Character {id: "character_003"}),
    (mira:Character {id: "character_004"}),
    (thorik:Character {id: "character_005"}),
    (selene:Character {id: "character_006"}),
    (valcor:Location {id: "location_001"}),
    (onyx:Location {id: "location_002"}),
    (foret:Location {id: "location_003"}),
    (monts:Location {id: "location_004"}),
    (couronne:Faction {id: "faction_001"}),
    (ombres:Faction {id: "faction_002"}),
    (gardiens:Faction {id: "faction_003"}),
    (epee:Item {id: "item_001"}),
    (grimoire:Item {id: "item_002"}),
    (couronneItem:Item {id: "item_003"}),
    (exil:Event {id: "event_001"}),
    (retour:Event {id: "event_002"}),
    (conseil:Event {id: "event_003"}),
    (bataille:Event {id: "event_004"})

// Projet et chapitres
MERGE (p)-[:HAS_CHAPTER]->(c1)
MERGE (p)-[:HAS_CHAPTER]->(c2)

// Chapitres et scènes
MERGE (c1)-[:HAS_SCENE]->(s1)
MERGE (c1)-[:HAS_SCENE]->(s2)
MERGE (c2)-[:HAS_SCENE]->(s3)

// Relations entre personnages
MERGE (aelric)-[:SIBLING_OF]->(darian)
MERGE (aelric)-[:ALLY_OF {since: "1028", trustLevel: 9}]->(lyra)
MERGE (aelric)-[:ENEMY_OF {
    reason: "Usurpation du trône",
    intensity: 10
}]->(darian)
MERGE (mira)-[:ALLY_OF {since: "1029", trustLevel: 6}]->(aelric)
MERGE (thorik)-[:ALLY_OF {since: "1025", trustLevel: 8}]->(darian)
MERGE (selene)-[:ALLY_OF {since: "1027", trustLevel: 7}]->(lyra)

// Factions
MERGE (darian)-[:LEADS]->(couronne)
MERGE (thorik)-[:MEMBER_OF {rank: "Général"}]->(couronne)
MERGE (mira)-[:MEMBER_OF {rank: "Agent"}]->(ombres)
MERGE (lyra)-[:MEMBER_OF {rank: "Archimage"}]->(gardiens)
MERGE (selene)-[:MEMBER_OF {rank: "Prêtresse"}]->(gardiens)
MERGE (couronne)-[:RIVAL_OF]->(ombres)

// Objets
MERGE (aelric)-[:OWNS]->(epee)
MERGE (lyra)-[:OWNS]->(grimoire)
MERGE (darian)-[:OWNS]->(couronneItem)

// Personnages dans les scènes
MERGE (s1)-[:FEATURES_CHARACTER]->(aelric)
MERGE (s1)-[:FEATURES_CHARACTER]->(mira)

MERGE (s2)-[:FEATURES_CHARACTER]->(aelric)
MERGE (s2)-[:FEATURES_CHARACTER]->(lyra)
MERGE (s2)-[:FEATURES_CHARACTER]->(selene)

MERGE (s3)-[:FEATURES_CHARACTER]->(aelric)
MERGE (s3)-[:FEATURES_CHARACTER]->(darian)
MERGE (s3)-[:FEATURES_CHARACTER]->(thorik)

// Lieux
MERGE (s1)-[:TAKES_PLACE_IN]->(foret)
MERGE (s2)-[:TAKES_PLACE_IN]->(onyx)
MERGE (s3)-[:TAKES_PLACE_IN]->(monts)

MERGE (exil)-[:OCCURRED_IN]->(valcor)
MERGE (retour)-[:OCCURRED_IN]->(foret)
MERGE (conseil)-[:OCCURRED_IN]->(onyx)
MERGE (bataille)-[:OCCURRED_IN]->(monts)

// Participation aux événements
MERGE (aelric)-[:PARTICIPATED_IN {role: "Exilé"}]->(exil)

MERGE (aelric)-[:PARTICIPATED_IN {role: "Héritier"}]->(retour)
MERGE (mira)-[:PARTICIPATED_IN {role: "Guide"}]->(retour)

MERGE (aelric)-[:PARTICIPATED_IN {role: "Représentant"}]->(conseil)
MERGE (lyra)-[:PARTICIPATED_IN {role: "Organisatrice"}]->(conseil)
MERGE (selene)-[:PARTICIPATED_IN {role: "Conseillère"}]->(conseil)

MERGE (aelric)-[:PARTICIPATED_IN {role: "Commandant"}]->(bataille)
MERGE (darian)-[:PARTICIPATED_IN {role: "Roi"}]->(bataille)
MERGE (thorik)-[:PARTICIPATED_IN {role: "Général"}]->(bataille)

// Chronologie
MERGE (exil)-[:PRECEDES]->(retour)
MERGE (retour)-[:PRECEDES]->(conseil)
MERGE (conseil)-[:PRECEDES]->(bataille)

// Mentions
MERGE (c1)-[:MENTIONS]->(aelric)
MERGE (c1)-[:MENTIONS]->(lyra)
MERGE (c1)-[:MENTIONS]->(mira)
MERGE (c1)-[:MENTIONS]->(selene)

MERGE (c2)-[:MENTIONS]->(aelric)
MERGE (c2)-[:MENTIONS]->(darian)
MERGE (c2)-[:MENTIONS]->(thorik);