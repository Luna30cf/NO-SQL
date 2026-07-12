const state = {
  api: localStorage.getItem("loregraph_api") || "http://127.0.0.1:8000/api/v1",
  activeProject: localStorage.getItem("loregraph_project") || "project_001",
  projects: [],
  chapters: [],
  characters: [],
  currentPage: "dashboard"
};

const pageMeta = {
  dashboard: ["Tableau de bord", "Vue d’ensemble de la plateforme"],
  projects: ["Projets", "Créer et sélectionner les univers narratifs"],
  chapters: ["Chapitres", "Organiser et publier les chapitres"],
  characters: ["Personnages", "Gérer les fiches riches de l’univers"],
  drafts: ["Éditeur", "Rédaction collaborative avec Redis"],
  graph: ["Graphe", "Explorer les relations Neo4j"],
  settings: ["Configuration", "Paramètres du frontend"]
};

function $(id) { return document.getElementById(id); }

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function notify(message, error = false) {
  const zone = $("notification-zone");
  const node = document.createElement("div");
  node.className = `notification${error ? " error" : ""}`;
  node.textContent = message;
  zone.appendChild(node);
  setTimeout(() => node.remove(), 4200);
}

async function api(path, options = {}) {
  const response = await fetch(`${state.api}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(options.headers || {})
    }
  });

  const text = await response.text();
  let payload = null;
  if (text) {
    try { payload = JSON.parse(text); }
    catch { payload = text; }
  }

  if (!response.ok) {
    const detail = payload?.detail ?? payload ?? `${response.status} ${response.statusText}`;
    throw new Error(typeof detail === "string" ? detail : JSON.stringify(detail));
  }
  return payload;
}

function emptyState(message = "Aucune donnée disponible.") {
  return `<div class="empty-state"><h4>Aucune donnée</h4><p>${escapeHtml(message)}</p></div>`;
}

function setPage(name) {
  state.currentPage = name;
  document.querySelectorAll(".page").forEach(x => x.classList.remove("active"));
  document.querySelectorAll(".nav-item").forEach(x => x.classList.remove("active"));
  $(`page-${name}`).classList.add("active");
  document.querySelector(`.nav-item[data-page="${name}"]`)?.classList.add("active");
  $("page-title").textContent = pageMeta[name][0];
  $("page-subtitle").textContent = pageMeta[name][1];
  refreshCurrentPage();
}

async function refreshCurrentPage() {
  const loaders = {
    dashboard: loadDashboard,
    projects: loadProjects,
    chapters: loadChapters,
    characters: loadCharacters,
    drafts: loadDraftContext,
    graph: () => Promise.allSettled([loadTimeline(), loadNetwork()]),
    settings: () => { $("api-base-url").value = state.api; }
  };
  await loaders[state.currentPage]?.();
}

function setActiveProject(projectId) {
  state.activeProject = projectId;
  localStorage.setItem("loregraph_project", projectId);
  $("chapter-project-id").value = projectId;
  $("character-project-id").value = projectId;
  $("timeline-project-id").value = projectId;
  $("chapter-active-project").textContent = projectId;
  notify(`Projet actif : ${projectId}`);
}

async function loadHealth() {
  try {
    const health = await api("/health");
    $("global-status-dot").className = "status-dot ok";
    $("global-status-label").textContent = "Toutes les bases connectées";
    $("service-cards").innerHTML = Object.entries(health.services).map(([name, ok]) => `
      <article class="service-card ${ok ? "ok" : "error"}">
        <div class="service-name">${escapeHtml(name)}</div>
        <div class="service-value">${ok ? "Connecté" : "Indisponible"}</div>
      </article>
    `).join("");
    return health;
  } catch (error) {
    $("global-status-dot").className = "status-dot error";
    $("global-status-label").textContent = "API indisponible";
    $("service-cards").innerHTML = emptyState(error.message);
    throw error;
  }
}

async function loadDashboard() {
  try {
    await loadHealth();
    const [projects, characters] = await Promise.all([
      api("/projects"),
      api("/characters")
    ]);
    state.projects = projects;
    state.characters = characters;

    let chapters = [];
    try { chapters = await api(`/chapters/project/${state.activeProject}`); }
    catch {}

    $("content-stats").innerHTML = `
      <div class="stat"><strong>${projects.length}</strong><span>projets</span></div>
      <div class="stat"><strong>${chapters.length}</strong><span>chapitres actifs</span></div>
      <div class="stat"><strong>${characters.length}</strong><span>personnages</span></div>
    `;
    await loadDashboardTimeline();
  } catch (error) {
    notify(error.message, true);
  }
}

async function loadProjects() {
  const target = $("projects-list");
  target.classList.add("loading");
  try {
    state.projects = await api("/projects");
    target.innerHTML = state.projects.length ? state.projects.map(project => `
      <article class="entity-card">
        <div class="entity-card-header">
          <div>
            <h4>${escapeHtml(project.title)}</h4>
            <p>${escapeHtml(project.description || "Aucune description")}</p>
          </div>
          ${project.id === state.activeProject ? '<span class="badge success">Actif</span>' : ""}
        </div>
        <div class="meta">
          <span class="badge">${escapeHtml(project.id)}</span>
          <span class="badge">Propriétaire : ${escapeHtml(project.owner_id)}</span>
        </div>
        <div class="actions">
          <button class="primary" onclick="selectProject('${escapeHtml(project.id)}')">Sélectionner</button>
          <button class="secondary" onclick="openProjectChapters('${escapeHtml(project.id)}')">Voir les chapitres</button>
        </div>
      </article>
    `).join("") : emptyState("Créez votre premier projet.");
  } catch (error) {
    target.innerHTML = emptyState(error.message);
    notify(error.message, true);
  } finally {
    target.classList.remove("loading");
  }
}

window.selectProject = id => {
  setActiveProject(id);
  loadProjects();
};

window.openProjectChapters = id => {
  setActiveProject(id);
  setPage("chapters");
};

async function createProject(event) {
  event.preventDefault();
  const payload = {
    id: $("project-id").value.trim(),
    title: $("project-title").value.trim(),
    owner_id: $("project-owner").value.trim(),
    description: $("project-description").value.trim() || null
  };
  try {
    await api("/projects", { method: "POST", body: JSON.stringify(payload) });
    setActiveProject(payload.id);
    event.target.reset();
    $("project-owner").value = "user_001";
    notify("Projet créé dans PostgreSQL.");
    await loadProjects();
  } catch (error) { notify(error.message, true); }
}

async function loadChapters() {
  $("chapter-active-project").textContent = state.activeProject;
  $("chapter-project-id").value = state.activeProject;
  const target = $("chapters-list");
  target.classList.add("loading");
  try {
    state.chapters = await api(`/chapters/project/${state.activeProject}`);
    target.innerHTML = state.chapters.length ? state.chapters.map(chapter => `
      <article class="entity-card">
        <div class="entity-card-header">
          <div>
            <h4>${escapeHtml(chapter.chapter_number)}. ${escapeHtml(chapter.title)}</h4>
            <p>Créé par ${escapeHtml(chapter.author_id)}</p>
          </div>
          <span class="badge ${chapter.status === "published" ? "success" : chapter.status === "review" ? "warning" : ""}">
            ${escapeHtml(chapter.status)}
          </span>
        </div>
        <div class="meta">
          <span class="badge">${escapeHtml(chapter.id)}</span>
          <span class="badge">${escapeHtml(chapter.project_id)}</span>
        </div>
        <div class="actions">
          <button class="primary" onclick="editChapterDraft('${escapeHtml(chapter.id)}','${escapeHtml(chapter.title)}')">Écrire</button>
          ${chapter.status !== "published" ? `<button class="danger" onclick="publishChapter('${escapeHtml(chapter.id)}')">Publier</button>` : ""}
        </div>
      </article>
    `).join("") : emptyState("Aucun chapitre dans le projet actif.");
  } catch (error) {
    target.innerHTML = emptyState(error.message);
    notify(error.message, true);
  } finally { target.classList.remove("loading"); }
}

async function createChapter(event) {
  event.preventDefault();
  const payload = {
    id: $("chapter-id").value.trim(),
    project_id: $("chapter-project-id").value.trim(),
    author_id: $("chapter-author-id").value.trim(),
    title: $("chapter-title").value.trim(),
    chapter_number: Number($("chapter-number").value),
    status: $("chapter-status").value
  };
  try {
    await api("/chapters", { method: "POST", body: JSON.stringify(payload) });
    notify("Chapitre créé dans PostgreSQL.");
    await loadChapters();
  } catch (error) { notify(error.message, true); }
}

window.editChapterDraft = (id, title) => {
  $("draft-chapter-id").value = id;
  $("draft-title-display").value = title;
  setPage("drafts");
  loadDraft();
};

window.publishChapter = async id => {
  if (!confirm("Publier définitivement ce chapitre ?")) return;
  try {
    await api(`/chapters/${id}/publish`, { method: "POST" });
    notify("Chapitre publié.");
    await loadChapters();
  } catch (error) { notify(error.message, true); }
};

function parseJsonField(value, fallback = {}) {
  const trimmed = value.trim();
  if (!trimmed) return fallback;
  return JSON.parse(trimmed);
}

function characterPayload() {
  const age = $("character-age").value;
  const abilities = $("character-abilities").value
    .split("\n").map(x => x.trim()).filter(Boolean)
    .map(name => ({ name }));

  return {
    id: $("character-id").value.trim(),
    project_id: $("character-project-id").value.trim(),
    name: $("character-name").value.trim(),
    aliases: $("character-aliases").value.split(",").map(x => x.trim()).filter(Boolean),
    description: $("character-description").value.trim() || null,
    physical_attributes: {
      ...(age ? { age: Number(age) } : {}),
      ...($("character-species").value.trim() ? { species: $("character-species").value.trim() } : {})
    },
    personality: {
      ...($("character-role").value.trim() ? { role: $("character-role").value.trim() } : {}),
      ...($("character-alignment").value.trim() ? { alignment: $("character-alignment").value.trim() } : {})
    },
    abilities,
    appearances: [],
    custom_fields: parseJsonField($("character-custom-fields").value, {})
  };
}

async function loadCharacters() {
  const target = $("characters-list");
  target.classList.add("loading");
  try {
    state.characters = await api("/characters");
    renderCharacters();
  } catch (error) {
    target.innerHTML = emptyState(error.message);
    notify(error.message, true);
  } finally { target.classList.remove("loading"); }
}

function renderCharacters() {
  const term = $("character-search").value.trim().toLowerCase();
  const list = state.characters.filter(c =>
    [c.name, c.description, ...(c.aliases || [])].join(" ").toLowerCase().includes(term)
  );

  $("characters-list").innerHTML = list.length ? list.map(character => `
    <article class="entity-card">
      <div class="entity-card-header">
        <div>
          <h4>${escapeHtml(character.name)}</h4>
          <p>${escapeHtml(character.description || "Aucune description")}</p>
        </div>
        <span class="badge">${escapeHtml(character.id || "ID absent")}</span>
      </div>
      <div class="meta">
        <span class="badge">${escapeHtml(character.project_id)}</span>
        ${(character.aliases || []).map(x => `<span class="badge">${escapeHtml(x)}</span>`).join("")}
      </div>
      <div class="actions">
        <button class="primary" onclick="startEditCharacter('${escapeHtml(character.id)}')">Modifier</button>
        <button class="secondary" onclick="openCharacterNetwork('${escapeHtml(character.id)}')">Réseau</button>
        <button class="danger" onclick="deleteCharacter('${escapeHtml(character.id)}')">Supprimer</button>
      </div>
    </article>
  `).join("") : emptyState("Aucun personnage ne correspond à la recherche.");
}

async function submitCharacter(event) {
  event.preventDefault();
  try {
    const payload = characterPayload();
    const editingId = $("character-editing-id").value;

    if (editingId) {
      const { id, project_id, ...update } = payload;
      await api(`/characters/${editingId}`, { method: "PATCH", body: JSON.stringify(update) });
      notify("Personnage mis à jour.");
    } else {
      await api("/characters", { method: "POST", body: JSON.stringify(payload) });
      notify("Personnage créé dans MongoDB et synchronisé dans Neo4j.");
    }
    resetCharacterForm();
    await loadCharacters();
  } catch (error) {
    notify(error.message.includes("JSON") ? "Le JSON des champs personnalisés est invalide." : error.message, true);
  }
}

window.startEditCharacter = async id => {
  try {
    const c = await api(`/characters/${id}`);
    $("character-editing-id").value = id;
    $("character-id").value = c.id;
    $("character-id").disabled = true;
    $("character-project-id").value = c.project_id;
    $("character-project-id").disabled = true;
    $("character-name").value = c.name || "";
    $("character-aliases").value = (c.aliases || []).join(", ");
    $("character-description").value = c.description || "";
    $("character-age").value = c.physical_attributes?.age ?? "";
    $("character-species").value = c.physical_attributes?.species ?? "";
    $("character-role").value = c.personality?.role ?? "";
    $("character-alignment").value = c.personality?.alignment ?? "";
    $("character-abilities").value = (c.abilities || []).map(x => x.name || JSON.stringify(x)).join("\n");
    $("character-custom-fields").value = Object.keys(c.custom_fields || {}).length ? JSON.stringify(c.custom_fields, null, 2) : "";
    $("character-form-title").textContent = "Modifier le personnage";
    $("character-submit-btn").textContent = "Enregistrer";
    $("character-cancel-edit-btn").classList.remove("hidden");
    window.scrollTo({ top: 0, behavior: "smooth" });
  } catch (error) { notify(error.message, true); }
};

function resetCharacterForm() {
  $("character-form").reset();
  $("character-editing-id").value = "";
  $("character-id").disabled = false;
  $("character-project-id").disabled = false;
  $("character-project-id").value = state.activeProject;
  $("character-form-title").textContent = "Créer un personnage";
  $("character-submit-btn").textContent = "Créer";
  $("character-cancel-edit-btn").classList.add("hidden");
}

window.deleteCharacter = async id => {
  if (!confirm(`Supprimer ${id} de MongoDB et Neo4j ?`)) return;
  try {
    await api(`/characters/${id}`, { method: "DELETE" });
    notify("Personnage supprimé.");
    await loadCharacters();
  } catch (error) { notify(error.message, true); }
};

window.openCharacterNetwork = id => {
  $("network-character-id").value = id;
  setPage("graph");
  loadNetwork();
};

async function loadDraftContext() {
  const chapterId = $("draft-chapter-id").value.trim();
  if (!chapterId) return;
  try {
    const chapter = await api(`/chapters/${chapterId}`);
    $("draft-title-display").value = chapter.title;
  } catch {}
  updateWordCount();
}

async function loadDraft() {
  const chapterId = $("draft-chapter-id").value.trim();
  const userId = $("draft-user-id").value.trim();
  try {
    const result = await api(`/chapters/${chapterId}/draft/${userId}`);
    $("draft-content").value = result.content || "";
    $("draft-save-indicator").textContent = `Chargé — TTL ${result.ttl_seconds}s`;
    $("draft-state").textContent = `Brouillon Redis actif pour ${userId}.`;
    updateWordCount();
    notify("Brouillon chargé.");
  } catch (error) {
    $("draft-content").value = "";
    $("draft-state").textContent = "Aucun brouillon existant pour cet utilisateur.";
    $("draft-save-indicator").textContent = "Nouveau brouillon";
  }
}

async function saveDraft() {
  const chapterId = $("draft-chapter-id").value.trim();
  const payload = {
    user_id: $("draft-user-id").value.trim(),
    content: $("draft-content").value
  };
  if (!payload.content.trim()) return notify("Le brouillon ne peut pas être vide.", true);
  try {
    const result = await api(`/chapters/${chapterId}/draft`, {
      method: "PUT",
      body: JSON.stringify(payload)
    });
    $("draft-save-indicator").textContent = `Enregistré — TTL ${result.ttl_seconds}s`;
    $("draft-state").textContent = `Brouillon sauvegardé pour ${result.user_id}.`;
    notify("Brouillon enregistré dans Redis.");
  } catch (error) { notify(error.message, true); }
}

async function lockDraft() {
  const chapterId = $("draft-chapter-id").value.trim();
  const userId = $("draft-user-id").value.trim();
  try {
    const result = await api(`/chapters/${chapterId}/lock`, {
      method: "POST",
      body: JSON.stringify({ user_id: userId })
    });
    $("draft-state").textContent = result.acquired
      ? `Verrou acquis par ${result.owner_id} pour ${result.ttl_seconds}s.`
      : `Verrou déjà détenu par ${result.owner_id}.`;
    notify(result.acquired ? "Verrou d’édition acquis." : "Verrou indisponible.", !result.acquired);
  } catch (error) { notify(error.message, true); }
}

async function publishCurrentDraft() {
  const id = $("draft-chapter-id").value.trim();
  if (!confirm("Publier ce chapitre ? Le statut PostgreSQL passera à published.")) return;
  try {
    await api(`/chapters/${id}/publish`, { method: "POST" });
    notify("Chapitre publié.");
  } catch (error) { notify(error.message, true); }
}

function updateWordCount() {
  const text = $("draft-content").value.trim();
  const count = text ? text.split(/\s+/).length : 0;
  $("draft-word-count").textContent = `${count} mot${count > 1 ? "s" : ""}`;
  $("draft-save-indicator").textContent = "Modifications non enregistrées";
}

async function createRelationship(event) {
  event.preventDefault();
  try {
    const payload = {
      source_id: $("relation-source").value.trim(),
      target_id: $("relation-target").value.trim(),
      relationship_type: $("relation-type").value,
      properties: parseJsonField($("relation-properties").value, {})
    };
    await api("/graph/relationships", { method: "POST", body: JSON.stringify(payload) });
    notify("Relation créée dans Neo4j.");
    $("network-character-id").value = payload.source_id;
    await loadNetwork();
  } catch (error) {
    notify(error.message.includes("JSON") ? "Le JSON des propriétés est invalide." : error.message, true);
  }
}

async function loadPath() {
  const source = $("path-source").value.trim();
  const target = $("path-target").value.trim();
  const container = $("path-result");
  try {
    const result = await api(`/graph/path/${encodeURIComponent(source)}/${encodeURIComponent(target)}`);
    container.innerHTML = `
      <div class="entity-card">
        <h4>Chemin trouvé</h4>
        <p>${result.nodes.map(n => escapeHtml(n.name || n.id)).join(" → ")}</p>
        <pre>${escapeHtml(JSON.stringify(result.relationships, null, 2))}</pre>
      </div>
    `;
  } catch (error) {
    container.innerHTML = emptyState(error.message);
    notify(error.message, true);
  }
}

async function loadNetwork() {
  const id = $("network-character-id").value.trim();
  const target = $("network-result");
  if (!id) return;
  try {
    const result = await api(`/graph/characters/${encodeURIComponent(id)}/network`);
    target.innerHTML = result.relations.length ? result.relations.map(r => `
      <article class="entity-card">
        <div class="entity-card-header">
          <h4>${escapeHtml(r.name || r.target_id)}</h4>
          <span class="badge">Distance ${escapeHtml(r.distance)}</span>
        </div>
        <div class="meta">
          ${(r.labels || []).map(l => `<span class="badge">${escapeHtml(l)}</span>`).join("")}
          <span class="badge">${escapeHtml(r.target_id)}</span>
        </div>
      </article>
    `).join("") : emptyState("Aucune relation trouvée.");
  } catch (error) {
    target.innerHTML = emptyState(error.message);
    notify(error.message, true);
  }
}

async function loadTimeline() {
  const projectId = $("timeline-project-id").value.trim() || state.activeProject;
  const target = $("timeline-result");
  try {
    const list = await api(`/graph/projects/${encodeURIComponent(projectId)}/timeline`);
    target.innerHTML = renderTimeline(list);
  } catch (error) {
    target.innerHTML = emptyState(error.message);
  }
}

async function loadDashboardTimeline() {
  const target = $("dashboard-timeline");
  try {
    const list = await api(`/graph/projects/${encodeURIComponent(state.activeProject)}/timeline`);
    target.innerHTML = renderTimeline(list);
  } catch (error) {
    target.innerHTML = emptyState("Aucune timeline pour le projet actif.");
  }
}

function renderTimeline(list) {
  return list?.length ? list.map(e => `
    <div class="timeline-item">
      <strong>${escapeHtml(e.name)}</strong>
      <span>${escapeHtml(e.date)} · ${escapeHtml(e.event_id)}</span>
    </div>
  `).join("") : emptyState("Aucun événement trouvé.");
}

function bindEvents() {
  document.querySelectorAll(".nav-item").forEach(btn =>
    btn.addEventListener("click", () => setPage(btn.dataset.page))
  );
  document.querySelectorAll("[data-go]").forEach(btn =>
    btn.addEventListener("click", () => setPage(btn.dataset.go))
  );

  $("refresh-page-btn").addEventListener("click", refreshCurrentPage);
  $("projects-refresh-btn").addEventListener("click", loadProjects);
  $("chapters-refresh-btn").addEventListener("click", loadChapters);
  $("characters-refresh-btn").addEventListener("click", loadCharacters);
  $("dashboard-timeline-btn").addEventListener("click", loadDashboardTimeline);

  $("project-form").addEventListener("submit", createProject);
  $("chapter-form").addEventListener("submit", createChapter);
  $("character-form").addEventListener("submit", submitCharacter);
  $("character-cancel-edit-btn").addEventListener("click", resetCharacterForm);
  $("character-search").addEventListener("input", renderCharacters);

  $("draft-load-btn").addEventListener("click", loadDraft);
  $("draft-lock-btn").addEventListener("click", lockDraft);
  $("draft-save-btn").addEventListener("click", saveDraft);
  $("draft-publish-btn").addEventListener("click", publishCurrentDraft);
  $("draft-content").addEventListener("input", updateWordCount);

  $("relationship-form").addEventListener("submit", createRelationship);
  $("path-load-btn").addEventListener("click", loadPath);
  $("network-load-btn").addEventListener("click", loadNetwork);
  $("timeline-load-btn").addEventListener("click", loadTimeline);

  $("settings-form").addEventListener("submit", event => {
    event.preventDefault();
    state.api = $("api-base-url").value.replace(/\/$/, "");
    localStorage.setItem("loregraph_api", state.api);
    notify("Configuration enregistrée.");
    loadHealth();
  });
}

async function init() {
  bindEvents();
  setActiveProject(state.activeProject);
  $("api-base-url").value = state.api;
  await loadDashboard();
}

init();
