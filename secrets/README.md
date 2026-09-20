# secrets/ (not tracked)

Place API tokens, env files, and other private material here. Mode `0700` recommended:

```bash
chmod 700 secrets
```

Only `.gitkeep` and this README are intended to be committed; real secrets are gitignored via `secrets/*` patterns in `.gitignore` where configured. Prefer keeping bulk secrets untracked entirely.
