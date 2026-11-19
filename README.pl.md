# Agent Factory

[English](README.md) | Polski

Zestaw 14 agentów i 15 ogólnych skilli działających jako jeden pipeline w
**Claude Code** i **GitHub Copilot**. Jeden orchestrator planuje i deleguje,
wyspecjalizowani agenci wykonują pracę, a człowiek sprawdza każdą zmianę: na bramce
przed pull requestem albo w samym pull requeście (domyślnie).

Każdy agent to jeden plik, który oba narzędzia ładują bez zmian. Agenci są
generyczni: checklisty, formaty i procedury pochodzą ze skilli w tym
repozytorium, a wiedza o konkretnym projekcie (stack, architektura, design
system) ze skilli trzymanych w tym projekcie.

## Łańcuch

```mermaid
flowchart LR
  U([Zadanie]) --> O{{orchestrator}}
  O -->|dev| A1[analyst] --> SR[spec-reviewer] --> AR[architect] --> D[developer] --> T[tester]
  T --> RS[review-security] & RP[review-performance] & RY[review-style]
  RS & RP & RY --> DSY[docs-writer: sync] --> G{Bramka człowieka: tylko tryb gate}
  O -->|content| BW[brief-writer] --> CW[copywriter] --> CA[copywriter × platforma] --> G
  O -->|docs| DW[docs-writer] --> AD[architect: recenzja] --> G
  O -->|design| A2[analyst] --> DS[designer] --> G
  G -->|akceptuj| P[publisher] --> PR([Pull request])
  DSY & CA & AD & DS -.->|tryb pr: bez bramki| P
  G -.->|odrzuć z uwagą| O
```

Interaktywna wersja tej mapy, z rolą, narzędziami i skillami każdego agenta,
jest w [docs/agent-chain.html](docs/agent-chain.html) (otwórz lokalnie w
przeglądarce, przełącznik PL w prawym górnym rogu).

## Pipeline'y

| Pipeline | Kiedy | Etapy | Pętle |
|---|---|---|---|
| **dev** | zmiana kodu | analyst → spec-reviewer → architect → developer → tester → trzy przeglądy równolegle → docs-writer (sync) → [bramka] → publisher | spec niejasna → analyst (`spec` ≤ 3); błąd testu lub ustalenie blokujące → developer (`code` ≤ 3); błąd środowiska → 2 ponowienia |
| **content** | tekst dla odbiorców | brief-writer → copywriter → copywriter per platforma (równolegle) → [bramka] → publisher | bramka → autor (`revision` ≤ 3) |
| **docs** | opis istniejącego | docs-writer → architect (recenzja) → [bramka] → publisher | architect → docs-writer (`revision` ≤ 3) |
| **design** | „design", makieta, UI/UX, redesign, `/design` | analyst → designer → [bramka] → publisher | bramka → designer lub analyst (`revision` ≤ 3) |

`[bramka]` obowiązuje tylko w trybie przeglądu `gate`. Domyślnie (tryb `pr`)
publisher otwiera pull request, gdy testy i przeglądy są czyste, a punktem
przeglądu jest sam pull request; orchestrator przełącza na `gate` przy zmianach
trudnych do cofnięcia przez zamknięcie PR (umowy właściciela, wdrożenia,
poświadczenia, migracje danych, koszty, publikacja poza PR) albo na Twoją
prośbę. Po wyczerpaniu licznika przebieg zatrzymuje się i czeka na człowieka.

## Agenci

| Agent | Rola | Narzędzia | Zapisuje | Skille |
|---|---|---|---|---|
| `orchestrator` | klasyfikuje zadanie, deleguje etapy, liczy próby, prowadzi stan i pamięć | wszystkie (dziedziczone) | `runs/`, `memory/` | `task-classification`, `findings-merge`, `retrospective`, `factory`, `karpathy-guidelines`, `subagent-driven-development`, `dispatching-parallel-agents`, `requesting-code-review`, `mem-search` |
| `analyst` | wymagania i testowalne kryteria akceptacji | Read, Grep, Glob, Write, Skill | własny plik wyniku w `runs/` | `ac-format`, `karpathy-guidelines`, `brainstorming` |
| `spec-reviewer` | zatwierdza spec albo zwraca z pytaniami | Read, Grep, Glob, Write, Skill | własny plik wyniku w `runs/` | `spec-checklist`, `karpathy-guidelines` |
| `architect` | projekt techniczny i plan; recenzja dokumentacji względem kodu | Read, Grep, Glob, Write, Skill | własny plik wyniku w `runs/` | `architecture-patterns`, `stack-and-style`, `karpathy-guidelines`, `writing-plans`, `ponytail` |
| `developer` | implementuje plan test-first; jedyny agent edytujący kod produktu | Read, Grep, Glob, Edit, Write, Bash, Skill | kod | `stack-and-style`, `ponytail`, `karpathy-guidelines`, `test-driven-development`, `systematic-debugging`, `receiving-code-review`, `security-checklist`, `verification-before-completion` |
| `tester` | sprawdza każde kryterium akceptacji z dowodem | Read, Grep, Glob, Bash, Edit, Write, Skill | pliki testów | `test-strategy`, `stack-and-style`, `test-driven-development`, `systematic-debugging`, `webapp-testing`, `verification-before-completion` |
| `review-security` | niezależny przegląd bezpieczeństwa diffu | Read, Grep, Glob, Skill | nic | `security-checklist`, `stack-and-style` |
| `review-performance` | niezależny przegląd wydajności diffu | Read, Grep, Glob, Skill | nic | `performance-checklist`, `stack-and-style` |
| `review-style` | konwencje, czytelność, prostota, zakres | Read, Grep, Glob, Skill | nic | `style-checklist`, `stack-and-style`, `ponytail-review` |
| `designer` | flow użytkownika, makiety, tokeny, handoff | Read, Grep, Glob, Edit, Write, Skill | `runs/<id>/design/` | `design-system`, `brand-guidelines`, `frontend-design`, `web-artifacts-builder`, `canvas-design`, `theme-factory`, `ponytail` |
| `brief-writer` | brief: cel, odbiorca, przekaz | Read, Grep, Glob, Skill | nic | `brief-format`, `brand-guidelines`, `brainstorming` |
| `copywriter` | tekst główny i adaptacje per platforma | Read, Grep, Glob, Skill | nic | `platform-rules`, `brand-guidelines`, `internal-comms`, `doc-coauthoring` |
| `docs-writer` | pisze nową dokumentację; utrzymuje ją zgodną ze zmianami kodu | Read, Grep, Glob, Edit, Write, Skill | dokumentacja | `docs-template`, `doc-coauthoring`, `stack-and-style` |
| `publisher` | gałąź, commit, pull request (w trybie gate tylko po zapisanej akceptacji człowieka) | Read, Grep, Glob, Bash, Skill | git | `commit-conventions`, `pr-template`, `finishing-a-development-branch` |

Brak skilla nigdy nie blokuje agenta: używa on domyślnej checklisty ze swojego
pliku i zgłasza brak.

## Skille

**W tym repozytorium** (`skills/`, instalowane razem z agentami):

| Skill | Co daje | Używa |
|---|---|---|
| `task-classification` | wybór dev, content, docs lub design; kiedy dzielić lub pytać | orchestrator |
| `findings-merge` | jedna lista ustaleń bez duplikatów, blokujące osobno od ostrzeżeń | orchestrator |
| `retrospective` | przegląd po przebiegu; kandydaci po trzech powtórzeniach | orchestrator |
| `factory` | tworzenie agenta lub skilla w formacie uniwersalnym | orchestrator |
| `ac-format` | kryteria akceptacji: jeden obserwowalny warunek, id, sposób weryfikacji | analyst |
| `spec-checklist` | niejednoznaczność, testowalność, sprzeczności, zakres, przypadki brzegowe | spec-reviewer |
| `test-strategy` | poziomy testów, mapowanie testów na kryteria, klasyfikacja błędów | tester |
| `security-checklist` | wejście, kontrola dostępu, sekrety, ekspozycja danych, zależności | developer, review-security |
| `performance-checklist` | dostęp do danych, koszt, oczekiwanie, pamięć, cache, współbieżność | review-performance |
| `style-checklist` | zakres, prostota, konwencje, czytelność, testy, komentarze | review-style |
| `brief-format` | szablon briefu | brief-writer |
| `platform-rules` | adaptacja jednego tekstu pod różne platformy | copywriter |
| `docs-template` | typy dokumentów, sekcje, utrzymanie dokumentacji zgodnej z kodem | docs-writer |
| `commit-conventions` | komunikaty commitów i nazwy gałęzi | publisher |
| `pr-template` | tytuł i opis pull requesta | publisher |

**W repozytorium konkretnego projektu**, bo opisują ten projekt:
`stack-and-style`, `architecture-patterns`, `design-system`. Skill projektowy
o tej samej nazwie co ogólny ma w tym projekcie pierwszeństwo.

**Zewnętrzne, instalowane jako pluginy** (nie są tu kopiowane):

| Źródło | Skille | Używa |
|---|---|---|
| [Zasady Karpathy'ego](https://github.com/multica-ai/andrej-karpathy-skills) | `karpathy-guidelines` | orchestrator, analyst, spec-reviewer, architect, developer |
| [Superpowers](https://github.com/obra/superpowers) | `subagent-driven-development`, `dispatching-parallel-agents`, `requesting-code-review` | orchestrator |
| | `brainstorming` | analyst, brief-writer |
| | `writing-plans` | architect |
| | `test-driven-development`, `systematic-debugging` | developer, tester |
| | `receiving-code-review` | developer |
| | `verification-before-completion` | developer, tester |
| | `finishing-a-development-branch` | publisher |
| [Ponytail](https://github.com/DietrichGebert/ponytail) | `ponytail`, `ponytail-review` | architect, developer, designer, review-style |
| [Skille Anthropic](https://github.com/anthropics/skills) | `frontend-design`, `canvas-design`, `web-artifacts-builder`, `theme-factory`, `brand-guidelines`, `doc-coauthoring`, `internal-comms`, `webapp-testing` | designer, brief-writer, copywriter, docs-writer, tester |
| [claude-mem](https://github.com/thedotmack/claude-mem) | `mem-search` | orchestrator |

Komendy instalacji są w
[docs/ORCHESTRATION.pl.md](docs/ORCHESTRATION.pl.md#8-instalacja-i-synchronizacja).

## Elementy wspólne

| Element | Co robi |
|---|---|
| **Stan** | `runs/<run-id>/state.json` to jedyne źródło prawdy. Zapisuje tylko orchestrator. |
| **Tryb przeglądu** | `pr` (domyślny): punktem przeglądu jest pull request. `gate`: przebieg zatrzymuje się przed publikacją; akceptuj, odrzuć z uwagą albo poproś o drobną zmianę. |
| **Rozmowa z właścicielem** | Krótkie wiadomości, najwyżej 3 połączone pytania z rekomendowanym wyborem i blok `Waiting for you` dla każdego pytania bez odpowiedzi. |
| **Pamięć** | Po każdym przebiegu orchestrator zapisuje wnioski do `memory/runs/<run-id>.md` i czyta pasujące zapisy przy kolejnym starcie. [claude-mem](https://github.com/thedotmack/claude-mem) dodaje wyszukiwanie między sesjami. Agenci współdzielą też pamięć długoterminową przez serwer MCP [Mem0](https://mem0.ai) (`mcp__mem0__*`, bez usuwania). |
| **Świeży branch** | Przed pierwszym etapem edytującym pliki orchestrator robi fetch, fast-forward domyślnego brancha i tworzy z niego branch przebiegu. |
| **Dokumentacja idzie ze zmianą** | Przed bramką `docs-writer` aktualizuje dokumenty, które zmiana kodu czyni nieaktualnymi. Trafiają do tego samego pull requesta. |
| **Podgląd** | [Claude Code Agent Monitor](https://github.com/hoangsonww/Claude-Code-Agent-Monitor) pokazuje drzewo przebiegu; każde wywołanie ma nazwę `[run-id] agent #próba`. |
| **Zasady pracy** | [Zasady Karpathy'ego](https://github.com/multica-ai/andrej-karpathy-skills) u orchestratora, [Ponytail](https://github.com/DietrichGebert/ponytail) dla najmniejszej kompletnej zmiany, kontrakt między agentami z [Superpowers](https://github.com/obra/superpowers). |

## Szybki start

Instalacja agentów i skilli dla wszystkich projektów (kopiuje je do
`~/.claude/{agents,skills}/` i `~/.copilot/{agents,skills}/`):

```bash
git clone https://github.com/luk98j/agent-factory.git && cd agent-factory
scripts/install.sh
```

Uruchom sesję z orchestratorem jako głównym agentem, w projekcie, nad którym
chcesz pracować:

```bash
claude --agent orchestrator
```

```bash
copilot --agent orchestrator
```

Potem opisz zadanie zwykłym językiem. Orchestrator wybierze pipeline:

- „Dodaj walidację e-maila w formularzu rejestracji" → dev
- „Zaprojektuj ekran logowania" albo `/design ekran logowania` → design
- „Opisz, jak działa moduł płatności" → docs
- „Napisz post na LinkedIn o nowej funkcji" → content

W trybie `pr` (domyślnym) orchestrator sam otwiera pull request, gdy testy i
przeglądy są czyste, a Ty sprawdzasz go tam. W trybie `gate` przebieg zatrzymuje
się z raportem, a pull request powstaje dopiero po akceptacji. Publisher wymaga repozytorium git z remote i zalogowanego `gh`.

## Synchronizacja repozytorium z Twoimi agentami

| Kierunek | Komenda | Co robi |
|---|---|---|
| repozytorium → foldery użytkownika | `scripts/install.sh` | kopiuje `agents/*.agent.md` i `skills/<nazwa>/`; niczego innego w folderach docelowych nie rusza |
| folder użytkownika → repozytorium | `scripts/sync-back.sh` | tworzy gałąź `sync/<znacznik-czasu>` i commituje zmienionych agentów i skille |

Przydatne opcje:

- `scripts/install.sh --dry-run` pokazuje, co by się zmieniło.
- `scripts/sync-back.sh --push` dodatkowo wypycha gałąź i otwiera pull request
  przez `gh`.
- `scripts/sync-back.sh --from copilot` czyta z folderu Copilota zamiast
  Claude.
- `scripts/sync-back.sh --add moj-agent` dodaje agenta, którego repozytorium
  jeszcze nie śledzi; `--add-skill moj-skill` robi to samo dla folderu skilla.

Przed commitem `sync-back.sh` skanuje zmienione pliki pod kątem ścieżek
domowych, adresów e-mail i formatów kluczy; jeśli coś znajdzie, zatrzymuje się.

Skrypty są w Bashu i działają na macOS, Linuksie, WSL i Git Bash. Foldery
docelowe można nadpisać zmiennymi `CLAUDE_HOME_DIR` i `COPILOT_HOME_DIR`.

## Dokumentacja

- [docs/ORCHESTRATION.pl.md](docs/ORCHESTRATION.pl.md): pełny opis: format,
  kontrakt między agentami, pętle, stan, pamięć, skille, zależności, znane
  ograniczenia.
- [docs/agent-chain.html](docs/agent-chain.html): interaktywna mapa.

## Status

Definicje agentów przechodzą `claude plugin validate`. Format jest zgodny z
dokumentacją Claude Code i GitHub Copilot; pełny przebieg w każdym z narzędzi
wymaga jeszcze weryfikacji. Znane ograniczenia są w
[docs/ORCHESTRATION.pl.md](docs/ORCHESTRATION.pl.md#9-ograniczenia-i-rzeczy-do-sprawdzenia).

## Licencja

[Apache License 2.0](LICENSE).
