# Meowdical Notes

Ceren Bingöl's cat-themed study diary on the road to TUS, built with Flutter (web).

- **Home** (`/`): a greeting from a blinking study cat, the roadmap as a board-game trail of paw prints, what's being studied now, the latest ticked-off topics, and the newest posts
- **Roadmap** (`/roadmap`): every TUS subject (basic sciences, clinical sciences and the minor clerkships), and a page per subject with its topic checklist (`/roadmap/anatomy`)
- **Blog** (`/blog`): posts with tag filters and a pinned post
- **Profile** (`/profile`): about Ceren, quick facts, milestones and her progress
- Three themes from the palette button: Strawberry Milk, Matcha Latte and Midnight Kitty (picked automatically for dark-mode fans)

Everything Ceren writes is plain Markdown in `content/`. Updating the blog never means touching Dart code.

## Run it

```bash
flutter run -d chrome
```

Markdown files are bundled with the app, so after editing content, stop the app and run it again (in VS Code: Shift+F5, then F5). Drafts (`draft: true`) show only while running it like this.

## Tick off a topic

Every subject is a file in `content/roadmap/<part>/`, and its topics are a checklist:

```markdown
## Topics

- [x] Upper limb (2026-11-02)
- [/] Lower limb
- [ ] Thorax
```

| Write | Means |
| --- | --- |
| `- [ ] Topic` | not started |
| `- [/] Topic` | studying it now (the cat on the roadmap sits on this subject) |
| `- [x] Topic (2026-11-02)` | done on that day; it shows up under *Recent paw-prints* |

A subject is finished when all its topics are ticked. Or tick it from the terminal:

```bash
dart run tool/content.dart done anatomy "upper limb"
```

`done` writes today's date (or `--date 2026-11-02`), `doing` marks a topic as being studied, `undo` unticks it. The subject can be its id, its title, or the start of either (`anat`), and the topic only needs part of its name.

```bash
dart run tool/content.dart status
```

prints the whole roadmap, with every subject's id.

## Write a blog post

```bash
dart run tool/content.dart new-post "How I studied the upper limb" --tags "Anatomy, Study tips" --subjects anatomy
```

This makes `content/blog/2026-11-02-how-i-studied-the-upper-limb.md`, a draft with a few headings to fill in. Add `--folder` to get a folder (`…/index.md`) so pictures can sit next to the post.

```markdown
---
title: How I studied the upper limb
description: Shown on the post's card. Falls back to the text above <!-- truncate -->.
tags: [Anatomy, Study tips]
subjects: [anatomy]     # roadmap subjects the post is about: it shows on their pages
emoji: 🦴               # on the cover when there's no picture
color: pink             # cover colour: pink, peach, butter, mint, sky, lilac, coral or sage
image: cover.jpg        # optional cover picture, next to the file
featured: true          # optional: pin it as the big post at the top of the blog
draft: true             # remove to publish
---

The first paragraph is the hook.

<!-- truncate -->

## The rest of the post
```

The date comes from the file name (`YYYY-MM-DD-…`). The draft post **Writing cheat sheet** shows every kind of formatting: headings, paw checklists, cat callouts (`:::tip` … `:::`), tables, quotes and pictures.

## Add a subject or a part

```bash
dart run tool/content.dart new-subject minor "Forensic Medicine" --tr "Adli Tıp" --emoji 🔍
```

Subjects are ordered by the number in front of their file name (`07-orthopedics.md`). A new folder in `content/roadmap/` is a new part of the roadmap, described by its `_part_.yaml` (`title`, `title_tr`, `short`, `emoji`, `position`, `description`).

Subject front matter: `title`, `title_tr` (Turkish name), `emoji`, `color`, `description`, and optionally `status: done` to mark the whole subject finished regardless of its checklist. Anything else written in a subject's file (notes, resources, tips) shows on its page.

## Profile

`content/profile.md`: name, title, the home page intro, photo (`avatar:`; without one, a drawn cat stands in), location, exam and **exam date** (shows a countdown), social links, quick facts and milestones, then the bio. Switched-off lines start with `#`; remove the `#` to use one.

## Check before publishing

```bash
dart run tool/content.dart check
```

finds front matter that isn't valid, missing pictures, and posts about subjects that don't exist.

```bash
flutter test
```

`test/site_test.dart` renders every page at phone, tablet and desktop sizes in every theme, with and without progress, and fails on any overflow or error. `test/content_test.dart` checks the checklist rules and that every link to a page of the site leads somewhere.

## Customize

| To change | Edit |
| --- | --- |
| Blog name, tagline, footer line, nav items | `lib/config/site_config.dart` |
| Colours, or add a theme | `lib/theme/app_themes.dart` (each preset appears in the theme menu) |
| Fonts, buttons | `lib/theme/app_theme.dart` (Fredoka, Nunito, Caveat) |
| Spacing, corners, breakpoints | `lib/theme/tokens.dart` |
| The cats | `lib/widgets/cats/cat_painter.dart` (drawn in code: no image files) |
| Loading screen | `web/index.html` |
| App icons and favicon | redraw them from the cat with `flutter test tool/generate_icons.dart` |

## Project layout

```
content/            profile.md, roadmap/<part>/*.md, blog/*.md
lib/
  config/           site_config.dart
  content/          Markdown and front matter parsing (plain Dart, shared with the tool)
  theme/            palettes, ThemeData, tokens, theme switching
  router/           go_router routes
  widgets/          cats, roadmap board, cards, Markdown renderer, layout
  pages/            home, roadmap, subject, blog, post, profile, 404
tool/content.dart   content commands
test/               content rules and full-site rendering
```

Packages: `go_router`, `flutter_markdown_plus`, `google_fonts`, `shared_preferences` (remembers the theme), `url_launcher`, `yaml`.

## Publish (GitHub Pages)

**Every push to `main` goes live.** `.github/workflows/deploy.yml` checks the content, runs the tests, bundles the content into one file for a faster start, builds the site with Flutter 3.29.3 and publishes it on GitHub Pages. If any step fails, nothing is published and the previous version stays online; the failure shows in the repository's **Actions** tab.

- The site is at `https://<owner>.github.io/<repository>/`. Direct links such as `…/roadmap/anatomy` work too: Pages shows `404.html` for addresses that aren't files, and the build makes that page the app as well.
- Your own domain: add it in the repository's **Settings → Pages → Custom domain**. The build picks up the new address by itself.
- Pages is switched on once, in **Settings → Pages**, with **GitHub Actions** as the source.

To see the release build on your computer first:

```bash
flutter run -d chrome --release
```
