# Stack: Python

## Detect

- `pyproject.toml`, `setup.py`, `setup.cfg`, `requirements*.txt`, `Pipfile`.
- `.py` files.
- The lockfile names the runner: `uv.lock` uv, `poetry.lock` poetry, `Pipfile.lock` pipenv. Run tools through it: `uv run ruff check`. Else use the repo's venv.
- Python version: `requires-python` in `pyproject.toml`, `.python-version`, `.tool-versions`, or the CI matrix.

## Lint discovery

The repo's config is the authority. Never add a linter. Look in this order:

1. `pyproject.toml`: `[tool.ruff]`, `[tool.mypy]`, `[tool.pyright]`, `[tool.pylint]`, `[tool.black]`, `[tool.isort]`, `[tool.pytest.ini_options]`.
2. Standalone files: `ruff.toml`, `.ruff.toml`, `mypy.ini`, `.mypy.ini`, `pyrightconfig.json`, `.pylintrc`, `.flake8`.
3. `setup.cfg` and `tox.ini`: `[flake8]`, `[mypy]`, `[tool:pytest]`.
4. Runners: `Makefile`, `noxfile.py`, `tox.ini`, `.pre-commit-config.yaml`.
5. CI: `.github/workflows/*.yml`. CI shows the commands that gate a merge.

No config at all: follow tier 1 docs and PEP 8 only. Do not install anything.

## Tier 1 docs

- Standard library and language: `https://docs.python.org/3/`. Pin the repo's version: `https://docs.python.org/3.12/library/typing.html`.
- Find a page: `https://docs.python.org/3/library/index.html`, `https://docs.python.org/3/reference/index.html`, `https://docs.python.org/3/genindex.html`.
- Style: `https://peps.python.org/pep-0008/`.
- Lint rules: Ruff `https://docs.astral.sh/ruff/rules/<rule-name>/`. Mypy `https://mypy.readthedocs.io/en/stable/error_code_list.html`. Pylint `https://pylint.readthedocs.io/en/stable/user_guide/messages/messages_overview.html`.
- Tests: `https://docs.pytest.org/en/stable/`.
- Other libraries: the vendor `llms.txt`, then `https://gitmcp.io/<owner>/<repo>`.
- AWS SDK (boto3) code: load `aws.md` too.

## Rule packs

Base: `$DJAUNT_SRC_DIR/trailofbits-skills/plugins/`. Read locally. CC-BY-SA: never copy the text.

| Change | Load |
|---|---|
| Mutable defaults, closures, exceptions, subprocess, string formatting | `sharp-edges/skills/sharp-edges/references/lang-python.md` |
| Config flags, auth, tokens, crypto | `sharp-edges/skills/sharp-edges/references/config-patterns.md`, `auth-patterns.md`, `crypto-apis.md` |
| Parsers, serializers, invariants worth a property test | `property-based-testing/skills/property-based-testing/SKILL.md`, then the matching file in its `references/`. Adding Hypothesis needs Tory's OK. |
