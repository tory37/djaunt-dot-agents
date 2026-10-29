# Stack: React

Load `js-ts.md` too. This file adds only the React parts.

## Detect

- `package.json` lists `react` or `react-dom`.
- `.jsx` or `.tsx` files.
- `next` in `package.json`, or `"use client"` / `"use server"` directives, means React Server Components (RSC).
- Read the React major version from `package.json`. Rules differ for 18 and 19.

## Lint discovery

Follow `js-ts.md`. Then look in the ESLint config for:

- `eslint-plugin-react-hooks`. Rule docs: `https://react.dev/reference/eslint-plugin-react-hooks`.
- `eslint-plugin-react`, `eslint-plugin-jsx-a11y`. Cite each rule's page from the plugin repo.

## Tier 1 docs

- Index: `curl -s https://react.dev/llms.txt`. It lists every page.
- Add `.md` to a page URL for markdown: `curl -s https://react.dev/reference/react/useMemo.md`.
- Cite the HTML URL with the heading anchor: `https://react.dev/reference/react/useMemo#skipping-expensive-recalculations`.
- Rules of React: `https://react.dev/reference/rules`.

## Rule packs

Base: `$DJAUNT_SRC_DIR/agent-skills/skills/`. Load only the files the change needs. `react-best-practices/rules/_sections.md` describes each category.

| Change | Load |
|---|---|
| State, effects, memo, re-renders | `react-best-practices/rules/rerender-*.md` |
| JSX output, conditional render, hydration | `react-best-practices/rules/rendering-*.md` |
| Data fetching, Suspense, awaits | `react-best-practices/rules/async-*.md` |
| Imports, code splitting, third-party scripts | `react-best-practices/rules/bundle-*.md` |
| Event listeners, localStorage, SWR | `react-best-practices/rules/client-*.md` |
| Refs, effect events, init-once | `react-best-practices/rules/advanced-*.md` |
| Loops and data transforms in hot paths | `react-best-practices/rules/js-*.md` |
| Server components, server actions | `react-best-practices/rules/server-*.md`. Skip unless the repo uses RSC or Next.js. |
| Component API, props, context, compound components | `composition-patterns/rules/*.md`. `react19-no-forwardref.md` applies to React 19 only. |
| Markup, accessibility, forms, focus | `html-css.md` rule packs |

Pick files by name inside a category. Do not load a whole category for one hook.
