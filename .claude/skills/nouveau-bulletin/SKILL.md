---
name: nouveau-bulletin
description: Publier un nouveau numéro du bulletin ICRSP Dijon à partir du PDF source du curé. Use when l'utilisateur veut générer/publier un nouveau bulletin mensuel, ou lance /nouveau-bulletin.
---

# Nouveau bulletin ICRSP Dijon

Génère la page HTML d'un nouveau numéro à partir du PDF source (« Dijon Précurseur N.pdf »)
en respectant SCRUPULEUSEMENT le format de `index.html`, puis publie tout automatiquement.

Architecture : tu (Claude) fais le créatif (lecture multimodale du PDF → écriture du HTML).
Le script `scripts/publier-numero.ps1` fait la plomberie (poppler, copie PDF, git, vérif).

## Procédure

### 1. Localiser le PDF source
Cherche à la racine du dépôt le PDF « Dijon Précurseur N.pdf » le plus récent.
Aucun PDF → STOP, demande son chemin à l'utilisateur.

### 2. Préparer la lecture
Lance :
`./scripts/publier-numero.ps1 -Phase prepare -SourcePdfPath "<chemin du PDF>"`
Cela installe poppler si besoin et copie le PDF vers `_input.pdf`.

### 3. Lire le PDF (multimodal)
Lis `_input.pdf` avec l'outil Read, TOUTES les pages, images comprises.
Les images (affiches d'événements) peuvent porter des dates/lieux/contacts : extrais-les.

### 4. Déduire numéro et mois
- **Numéro** : depuis le nom de fichier (« Dijon Précurseur 2.pdf » → 2), recoupé avec
  l'historique git (`git log` ; dernier « Bulletin n°N » + 1).
- **Mois / année** : lus dans l'en-tête du PDF. Introuvables → demande à l'utilisateur
  (seul arrêt prévu).
- Calcule :
  - `MOIS-SLUG` = mois en minuscules + année, ex. `juin-2026`.
  - `ISSUE` = `n°<N> · <mois> <année>`, ex. `n°2 · juin 2026`.

### 5. Générer le HTML
Pars de `templates/bulletin.html`. NE TOUCHE PAS au `<style>`, à l'en-tête fixe, au
sommaire (hors retraits), aux sections `#apostolat` et `#contacts`, ni au footer (hors lien PDF).
- Remplace `{{ISSUE}}` par la valeur calculée.
- Remplace `{{MOIS-SLUG}}` par le slug.
- Remplis les 5 sections variables (`#editorial`, `#evenements`, `#carnet`, `#icrsp`,
  `#textes`) avec le contenu extrait, en suivant le **cookbook** ci-dessous à la lettre.
- Si une section variable n'a aucun contenu ce mois-ci, supprime la section ENTIÈRE
  ainsi que son `<li class="nav__item">` dans le sommaire.
- Écris le résultat dans :
  - `index.html` (racine) — blason `image.png`, lien PDF `bulletins/bulletin-icrsp-dijon-<slug>.pdf` ;
  - `bulletins/bulletin-icrsp-dijon-<slug>.html` — IDENTIQUE mais blason `../image.png`
    et lien PDF `bulletin-icrsp-dijon-<slug>.pdf` (même dossier).

### 6. Mettre à jour archives.html
Insère, en TÊTE de `<section class="archives-list">`, cette carte (titre = titre de l'éditorial) :

```html
    <article class="bulletin-card">
      <div class="bulletin-card__issue">n°<N> · <Mois Année></div>
      <h3 class="bulletin-card__title"><titre de l'éditorial></h3>
      <div class="bulletin-card__actions">
        <a href="bulletins/bulletin-icrsp-dijon-<slug>.html" class="btn btn--primary">Lire en ligne →</a>
        <a href="bulletins/bulletin-icrsp-dijon-<slug>.pdf" class="btn btn--secondary" download>Télécharger le PDF</a>
      </div>
    </article>
```

### 7. Publier
Lance :
`./scripts/publier-numero.ps1 -Phase publish -Numero <N> -MoisSlug "<slug>" -SourcePdfPath "<chemin du PDF>"`
Le script copie le PDF, commit, push, attend le build Pages et vérifie les liens (200).

### 8. Restituer
Donne le rapport final : URL en ligne, statut des liens. Si un lien échoue, indique la
commande de revert (`git revert HEAD` puis `git push`).

## Cookbook des composants (format à respecter à l'identique)

### §5.1 Éditorial (#editorial)
- `<h2 class="section-title">Éditorial</h2>`.
- `<h3 class="block-title">…</h3>` par sujet (à partir du 2e : `style="margin-top: 36px;"`).
- Premier paragraphe : `<p class="lettrine">…</p>`.
- Citation : `<div class="citation"><p>« … »</p><span class="citation-source">Auteur</span></div>`.
- Signature : `<p class="auteur">Chanoine …</p>`.

### §5.2 Événements (#evenements)
```html
<div class="fiche-evenement">
  <h3 class="block-title">Titre</h3>
  <div class="fiche-meta">
    <div class="fiche-meta__row"><span class="fiche-meta__icon">📅</span><span class="fiche-meta__date">Date</span></div>
    <div class="fiche-meta__row"><span class="fiche-meta__icon">📍</span><span class="fiche-meta__lieu"><a href="https://maps.google.com/?q=...">Lieu</a></span></div>
  </div>
  <p>Description.</p>
  <p class="fiche-contact">Contact : <a href="tel:+33...">Nom — 06 ...</a></p>
  <a href="https://..." target="_blank" class="btn btn--primary">S'inscrire →</a>
</div>
```
Variante note : `style="border-left-color: var(--color-primary);"` + `btn--secondary`.

### §5.3 Carnet familial (#carnet)
```html
<div class="carnet-familial">
  <div class="carnet-section">
    <div class="carnet-section__label">✝ R.I.P.</div>
    <div class="carnet-section__content"><p>… <strong>Nom</strong> …</p></div>
  </div>
  <div class="carnet-separator">✦</div>
  <div class="carnet-section">
    <div class="carnet-section__label">Mariages</div>
    <div class="carnet-section__content"><p><strong>X</strong> avec <strong>Y</strong>, le … en l'église …</p></div>
  </div>
</div>
```
Rubriques selon le PDF : R.I.P., Mariages, Fiançailles, Baptêmes. Une `carnet-separator` ✦ entre chaque.

### §5.4 Vie de l'ICRSP (#icrsp)
Comme §5.2 mais `<div class="fiche-evenement" style="border-left-color: var(--color-accent);">`.

### §5.5 Textes et prières (#textes)
```html
<div class="depliant">
  <details class="depliant-details">
    <summary>
      <h3 class="block-title">Titre du texte</h3>
      <p class="block-subtitle">Source / auteur</p>
      <p>Phrase d'amorce…</p>
      <div class="depliant-toggle">Lire la suite <span class="depliant-toggle__chevron">▾</span></div>
    </summary>
    <div class="depliant-content">
      <p>Texte complet…</p>
    </div>
  </details>
</div>
```

## Règles de fidélité
- Ne modifie JAMAIS le bloc `<style>` ni les sections stables (#apostolat, #contacts, footer).
- Utilise les espaces insécables `&nbsp;` avant `: ; ! ?` comme dans index.html.
- Liens téléphone en `<a href="tel:+33...">`, adresses en liens Google Maps.
- N'intègre AUCUNE image du PDF dans le HTML (texte seul, sauf le blason).
