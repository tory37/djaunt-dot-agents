## Scripts for Syncing

This is our global store for AI md files.  We want to do the following:

1. Init a repo, and push it to a new repository on my account, no org, named djaunt-dot-agents
2. Write a script in scripts/ that does the following
    - Creates ~/.agents folder if needed on the users machine
    - Copies AGENTS.md and skills/ to ~/.agents
		- Checks for an existing ~/.agents/extensions folder, and populates the extensions portion of AGENTS.md with a reference to whatever extensions are in that folder
    - Makes the following symlinks in both ~/.claude (if present on system) and ~/.gemini (if present on system)
       - .agents/AGENTS.md as CLAUDE.md and GEMINI.md respectively
			 - Copies .agents/skills into ~/.claude/skills
			 - Does whatever it needs to do to get those skills working in gemini, idk if it's the same just putting in a /skills folder please confirm


The overall goal here is that this repo is my completeley portable AI setup.  and that when coming to a new machine, whether it be for work, or for personal work, I can clone the repo, run the script, and have one single place that I modify my setup.  and have a methodology of flowing to the right agents, and picking up machine specific configurations (the extensions folder) along the way.

Also, we should write a README.md in here that explains this completely, and steps, etc.  