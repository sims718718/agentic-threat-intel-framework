# HTML Report Shell

**Fits at:** the final write step of `intel-report` (Step 3) and `hunt-planner` (Output Checklist) — after the Markdown file is written, render this same content as a styled HTML sibling in the same turn.
**Purpose:** Give the user a clean, self-contained, double-clickable HTML rendering of the report next to its Markdown source, with zero build tooling — the Markdown-writing agent fills this shell directly, no pandoc/npm/build step involved.

## Rule

The Markdown file remains the source of truth for downstream skills — never change what you write there. In the same turn, additionally translate that Markdown into the shell below and save it as a sibling file: same directory, same slug/base name, `.html` extension instead of `.md` (e.g. `<slug>-report.md` → `<slug>-report.html`; `<slug>-hunt-plan.md` → `<slug>-hunt-plan.html`).

Translation rules:
- `# Heading` → the page's single `<h1>`
- `## Heading` / `### Heading` → `<h2>` / `<h3>`
- Markdown tables → `<table>` with `<thead>`/`<tbody>`
- Bullet lists → `<ul><li>`; numbered lists → `<ol><li>`
- `**bold**`, `[FILL IN: ...]` placeholders, and `Unknown`/`Not assessed` markers stay as emphasis (`<strong>`/`<em>`) — do not strip or resolve them
- Fenced code blocks → `<pre><code>`
- Blockquotes (e.g. an Express Plan warning) → `<blockquote>`

## Shell

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>[TITLE]</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; max-width: 860px; margin: 2rem auto; padding: 0 1.5rem; line-height: 1.5; color: #1a1a1a; }
  h1, h2, h3 { line-height: 1.25; }
  h1 { border-bottom: 2px solid #ddd; padding-bottom: 0.3rem; }
  h2 { border-bottom: 1px solid #eee; padding-bottom: 0.2rem; margin-top: 2rem; }
  table { border-collapse: collapse; width: 100%; margin: 1rem 0; }
  th, td { border: 1px solid #ddd; padding: 0.5rem 0.75rem; text-align: left; vertical-align: top; }
  th { background: #f5f5f5; }
  code, pre { background: #f5f5f5; border-radius: 4px; }
  pre { padding: 0.75rem; overflow-x: auto; }
  blockquote { border-left: 4px solid #f0ad4e; margin: 1rem 0; padding: 0.5rem 1rem; background: #fffaf0; }
  em { color: #555; }
</style>
</head>
<body>
[CONTENT]
</body>
</html>
```

Replace `[TITLE]` with the document's `# ` heading text. Replace `[CONTENT]` with the translated body (the `# ` title becomes `<body>`'s leading `<h1>`, not a duplicate `<title>` copy).
