const dbName = "loregraph";
const lore = db.getSiblingDB(dbName);

lore.createCollection("characters");


lore.characters.createIndex({ project_id: 1 });
lore.characters.createIndex({ name: 1 });
lore.characters.createIndex({ aliases: 1 });

const characters = [
  {
    _id: "character_001",
    project_id: "project_001",
    name: "Aelric de Valcor",
    aliases: ["Le Prince ExilÃ©"],
    description: "HÃ©ritier dÃ©chu du royaume de Valcor.",
    physical_attributes: { age: 31, species: "Humain" },
    personality: { role: "protagoniste", alignment: "loyal neutre" },
    abilities: [{ name: "MaÃ®trise de l'Ã©pÃ©e" }, { name: "Commandement" }],
    appearances: [{ chapter_id: "chapter_001", role: "principal" }],
    custom_fields: { origin: "Valcor", faction: "La Couronne de Valcor" }
  },
  {
    _id: "character_002",
    project_id: "project_001",
    name: "Lyra d'Onyx",
    aliases: ["L'Ombre d'Onyx"],
    description: "Mage et stratÃ¨ge liÃ©e aux Gardiens d'Onyx.",
    physical_attributes: { age: 28, species: "Humaine" },
    personality: { role: "alliÃ©e", alignment: "neutre bon" },
    abilities: [{ name: "Magie d'ombre" }, { name: "Divination" }],
    appearances: [{ chapter_id: "chapter_001", role: "secondaire" }],
    custom_fields: { origin: "Citadelle d'Onyx", faction: "Les Gardiens d'Onyx" }
  },
  {
    _id: "character_003",
    project_id: "project_001",
    name: "Darian Valcor",
    aliases: ["Le RÃ©gent"],
    description: "Rival politique d'Aelric et dirigeant de fait du royaume.",
    physical_attributes: { age: 39, species: "Humain" },
    personality: { role: "antagoniste", alignment: "loyal mauvais" },
    abilities: [{ name: "Intrigue politique" }],
    appearances: [{ chapter_id: "chapter_002", role: "principal" }],
    custom_fields: { origin: "Valcor" }
  },
  {
    _id: "character_004",
    project_id: "project_001",
    name: "Mira Solis",
    aliases: ["La Flamme Claire"],
    description: "GuÃ©risseuse itinÃ©rante et alliÃ©e d'Aelric.",
    physical_attributes: { age: 26, species: "Humaine" },
    personality: { role: "alliÃ©e", alignment: "neutre bon" },
    abilities: [{ name: "GuÃ©rison" }],
    appearances: [],
    custom_fields: { origin: "Solis" }
  },
  {
    _id: "character_005",
    project_id: "project_001",
    name: "Thorik Barbe-de-Fer",
    aliases: [],
    description: "Guerrier nain vÃ©tÃ©ran des Monts Noirs.",
    physical_attributes: { age: 84, species: "Nain" },
    personality: { role: "alliÃ©", alignment: "chaotique bon" },
    abilities: [{ name: "Combat Ã  la hache" }],
    appearances: [],
    custom_fields: { origin: "Monts Noirs" }
  },
  {
    _id: "character_006",
    project_id: "project_001",
    name: "SÃ©lÃ¨ne Noctis",
    aliases: ["La Voix des Murmures"],
    description: "Espionne affiliÃ©e Ã  la ConfrÃ©rie des Ombres.",
    physical_attributes: { age: 33, species: "Humaine" },
    personality: { role: "ambiguÃ«", alignment: "neutre" },
    abilities: [{ name: "Infiltration" }],
    appearances: [],
    custom_fields: { faction: "La ConfrÃ©rie des Ombres" }
  }
];

characters.forEach(character => {
  lore.characters.updateOne(
    { _id: character._id },
    { $set: character },
    { upsert: true }
  );
});

