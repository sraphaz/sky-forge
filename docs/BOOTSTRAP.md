# Bootstrap — Sky-Forge

```powershell
cd C:\Users\rapha\CursorRepos\sky-forge
git init
git add .
git commit -m "feat: Sky-Forge PR1 — intake, índices SKY, UX specialist, sky-elevator"

gh repo create sraphaz/sky-forge --public --source=. --remote=origin `
  --description "Sky-Forge — elevar propostas de software com prosperidade humana e UX digna"
git push -u origin main
```

Validação:

```powershell
./scripts/sky/sky.ps1 intake -Slug piloto-sky
./scripts/harness/run-harness.ps1
```
