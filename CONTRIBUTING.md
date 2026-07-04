# Contribuindo

1. Leia [AGENTS.md](AGENTS.md) e [docs/_meta/SKY_OPERATION.md](docs/_meta/SKY_OPERATION.md).
2. Mudanças de comportamento exigem atualização de `docs/CHANGELOG.md` e specs em `docs/specs/`.
3. Padrões aprendidos vão em `docs/patterns/` ou `docs/outcomes/` — nunca na raiz.
4. Atribua influências externas em `docs/attribution/` e `NOTICE`.
5. Não copie código de projetos sem licença compatível (ver NOTICE).

Validação local:

```powershell
./scripts/harness/run-harness.ps1
./scripts/sky/sky.ps1 validate -Slug example-horta
```
