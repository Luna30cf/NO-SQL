CREATE CONSTRAINT project_id_unique IF NOT EXISTS
FOR (p:Project)
REQUIRE p.id IS UNIQUE;

CREATE CONSTRAINT chapter_id_unique IF NOT EXISTS
FOR (c:Chapter)
REQUIRE c.id IS UNIQUE;

CREATE CONSTRAINT scene_id_unique IF NOT EXISTS
FOR (s:Scene)
REQUIRE s.id IS UNIQUE;

CREATE CONSTRAINT character_id_unique IF NOT EXISTS
FOR (c:Character)
REQUIRE c.id IS UNIQUE;

CREATE CONSTRAINT location_id_unique IF NOT EXISTS
FOR (l:Location)
REQUIRE l.id IS UNIQUE;

CREATE CONSTRAINT item_id_unique IF NOT EXISTS
FOR (i:Item)
REQUIRE i.id IS UNIQUE;

CREATE INDEX character_name_index IF NOT EXISTS
FOR (c:Character)
ON (c.name);

CREATE INDEX location_name_index IF NOT EXISTS
FOR (l:Location)
ON (l.name);

CREATE INDEX item_name_index IF NOT EXISTS
FOR (i:Item)
ON (i.name);

CREATE CONSTRAINT faction_id_unique IF NOT EXISTS
FOR (f:Faction)
REQUIRE f.id IS UNIQUE;

CREATE CONSTRAINT event_id_unique IF NOT EXISTS
FOR (e:Event)
REQUIRE e.id IS UNIQUE;

CREATE INDEX faction_name_index IF NOT EXISTS
FOR (f:Faction)
ON (f.name);

CREATE INDEX event_name_index IF NOT EXISTS
FOR (e:Event)
ON (e.name);