// ======================================================
// PROJET ET CHAPITRES
// ======================================================

MERGE (p:Project {id: "project_001"})
SET p.title = "Les Royaumes Brisés";

MERGE (c1:Chapter {id: "chapter_001"})
SET c1.title = "Le réveil du royaume",
    c1.number = 1;

MERGE (c2:Chapter {id: "chapter_002"})
SET c2.title = "La citadelle d'Onyx",
    c2.number = 2;

MERGE (p)-[:HAS_CHAPTER]->(c1);
MERGE (p)-[:HAS_CHAPTER]->(c2);


// ======================================================
// SCÈNES
// ======================================================

MERGE (s1:Scene {id: "scene_001"})
SET s1.name = "Le retour d'Aelric";

MERGE (s2:Scene {id: "scene_002"})
SET s2.name = "Le conseil secret";

MERGE (s3:Scene {id: "scene_003"})
SET s3.name = "La bataille des Monts Noirs";

MERGE (c1)-[:HAS_SCENE]->(s1);
MERGE (c1)-[:HAS_SCENE]->(s2);
MERGE (c2)-[:HAS_SCENE]->(s3);


// ======================================================
// PERSONNAGES
// ======================================================

MERGE (aelric:Character {id: "character_001"})
SET aelric.name = "Aelric de Valcor",
    aelric.role = "Prince déchu",
    aelric.project_id = "project_001";

MERGE (lyra:Character {id: "character_002"})
SET lyra.name = "Lyra d'Onyx",
    lyra.role = "Mage",
    lyra.project_id = "project_001";

MERGE (darian:Character {id: "character_003"})
SET darian.name = "Darian Valcor",
    darian.role = "Roi",
    darian.project_id = "project_001";

MERGE (mira:Character {id: "character_004"})
SET mira.name = "Mira Solis",
    mira.role = "Espionne",
    mira.project_id = "project_001";

MERGE (thorik:Character {id: "character_005"})
SET thorik.name = "Thorik Barbe-de-Fer",
    thorik.role = "Chef militaire",
    thorik.project_id = "project_001";

MERGE (selene:Character {id: "character_006"})
SET selene.name = "Sélène Noctis",
    selene.role = "Prêtresse",
    selene.project_id = "project_001";


// ======================================================
// LIEUX
// ======================================================

MERGE (valcor:Location {id: "location_001"})
SET valcor.name = "Royaume de Valcor",
    valcor.type = "Royaume";

MERGE (onyx:Location {id: "location_002"})
SET onyx.name = "Citadelle d'Onyx",
    onyx.type = "Forteresse";

MERGE (foret:Location {id: "location_003"})
SET foret.name = "Forêt des Murmures",
    foret.type = "Forêt";

MERGE (monts:Location {id: "location_004"})
SET monts.name = "Monts Noirs",
    monts.type = "Montagne";


// ======================================================
// FACTIONS
// ======================================================

MERGE (couronne:Faction {id: "faction_001"})
SET couronne.name = "La Couronne de Valcor";

MERGE (ombres:Faction {id: "faction_002"})
SET ombres.name = "La Confrérie des Ombres";

MERGE (gardiens:Faction {id: "faction_003"})
SET gardiens.name = "Les Gardiens d'Onyx";


// ======================================================
// OBJETS
// ======================================================

MERGE (epee:Item {id: "item_001"})
SET epee.name = "Lame de Valcor",
    epee.type = "Épée";

MERGE (grimoire:Item {id: "item_002"})
SET grimoire.name = "Grimoire d'Onyx",
    grimoire.type = "Livre magique";

MERGE (couronneItem:Item {id: "item_003"})
SET couronneItem.name = "Couronne brisée",
    couronneItem.type = "Relique";


// ======================================================
// ÉVÉNEMENTS
// ======================================================

MERGE (exil:Event {id: "event_001"})
SET exil.name = "Exil d'Aelric",
    exil.date = "1024-03-14",
    exil.project_id = "project_001";

MERGE (retour:Event {id: "event_002"})
SET retour.name = "Retour d'Aelric",
    retour.date = "1030-06-01",
    retour.project_id = "project_001";

MERGE (conseil:Event {id: "event_003"})
SET conseil.name = "Conseil secret",
    conseil.date = "1030-06-03",
    conseil.project_id = "project_001";

MERGE (bataille:Event {id: "event_004"})
SET bataille.name = "Bataille des Monts Noirs",
    bataille.date = "1030-06-10",
    bataille.project_id = "project_001";


// ======================================================
// RELATIONS ENTRE PERSONNAGES
// ======================================================

MERGE (aelric)-[:SIBLING_OF]->(darian);

MERGE (aelric)-[:ALLY_OF {
    since: "1028",
    trustLevel: 9
}]->(lyra);

MERGE (aelric)-[:ENEMY_OF {
    reason: "Usurpation du trône",
    intensity: 10
}]->(darian);

MERGE (mira)-[:ALLY_OF {
    since: "1029",
    trustLevel: 6
}]->(aelric);

MERGE (thorik)-[:ALLY_OF {
    since: "1025",
    trustLevel: 8
}]->(darian);

MERGE (selene)-[:ALLY_OF {
    since: "1027",
    trustLevel: 7
}]->(lyra);


// ======================================================
// APPARTENANCE AUX FACTIONS
// ======================================================

MERGE (darian)-[:LEADS]->(couronne);

MERGE (thorik)-[:MEMBER_OF {
    rank: "Général"
}]->(couronne);

MERGE (mira)-[:MEMBER_OF {
    rank: "Agent"
}]->(ombres);

MERGE (lyra)-[:MEMBER_OF {
    rank: "Archimage"
}]->(gardiens);

MERGE (selene)-[:MEMBER_OF {
    rank: "Prêtresse"
}]->(gardiens);

MERGE (couronne)-[:RIVAL_OF]->(ombres);


// ======================================================
// OBJETS POSSÉDÉS
// ======================================================

MERGE (aelric)-[:OWNS]->(epee);
MERGE (lyra)-[:OWNS]->(grimoire);
MERGE (darian)-[:OWNS]->(couronneItem);


// ======================================================
// PERSONNAGES DANS LES SCÈNES
// ======================================================

MERGE (s1)-[:FEATURES_CHARACTER]->(aelric);
MERGE (s1)-[:FEATURES_CHARACTER]->(mira);

MERGE (s2)-[:FEATURES_CHARACTER]->(aelric);
MERGE (s2)-[:FEATURES_CHARACTER]->(lyra);
MERGE (s2)-[:FEATURES_CHARACTER]->(selene);

MERGE (s3)-[:FEATURES_CHARACTER]->(aelric);
MERGE (s3)-[:FEATURES_CHARACTER]->(darian);
MERGE (s3)-[:FEATURES_CHARACTER]->(thorik);


// ======================================================
// LIEUX DES SCÈNES ET ÉVÉNEMENTS
// ======================================================

MERGE (s1)-[:TAKES_PLACE_IN]->(foret);
MERGE (s2)-[:TAKES_PLACE_IN]->(onyx);
MERGE (s3)-[:TAKES_PLACE_IN]->(monts);

MERGE (exil)-[:OCCURRED_IN]->(valcor);
MERGE (retour)-[:OCCURRED_IN]->(foret);
MERGE (conseil)-[:OCCURRED_IN]->(onyx);
MERGE (bataille)-[:OCCURRED_IN]->(monts);


// ======================================================
// PARTICIPATION AUX ÉVÉNEMENTS
// ======================================================

MERGE (aelric)-[:PARTICIPATED_IN {role: "Exilé"}]->(exil);

MERGE (aelric)-[:PARTICIPATED_IN {role: "Héritier"}]->(retour);
MERGE (mira)-[:PARTICIPATED_IN {role: "Guide"}]->(retour);

MERGE (aelric)-[:PARTICIPATED_IN {role: "Représentant"}]->(conseil);
MERGE (lyra)-[:PARTICIPATED_IN {role: "Organisatrice"}]->(conseil);
MERGE (selene)-[:PARTICIPATED_IN {role: "Conseillère"}]->(conseil);

MERGE (aelric)-[:PARTICIPATED_IN {role: "Commandant"}]->(bataille);
MERGE (darian)-[:PARTICIPATED_IN {role: "Roi"}]->(bataille);
MERGE (thorik)-[:PARTICIPATED_IN {role: "Général"}]->(bataille);


// ======================================================
// CHRONOLOGIE
// ======================================================

MERGE (exil)-[:PRECEDES]->(retour);
MERGE (retour)-[:PRECEDES]->(conseil);
MERGE (conseil)-[:PRECEDES]->(bataille);


// ======================================================
// MENTIONS DANS LES CHAPITRES
// ======================================================

MERGE (c1)-[:MENTIONS]->(aelric);
MERGE (c1)-[:MENTIONS]->(lyra);
MERGE (c1)-[:MENTIONS]->(mira);
MERGE (c1)-[:MENTIONS]->(selene);

MERGE (c2)-[:MENTIONS]->(aelric);
MERGE (c2)-[:MENTIONS]->(darian);
MERGE (c2)-[:MENTIONS]->(thorik);