# Orkiestracja agentów: dokumentacja stacku

[English](ORCHESTRATION.md) | Polski

Opis 14 agentów z katalogu `agents/`, tego jak się łączą, z jakich skilli
korzystają i jak wpięte są pamięć, Ponytail, zasady Karpathy'ego i monitor.
Wersja wizualna: [agent-chain.html](agent-chain.html).

## 1. Agenci

| Agent | Pipeline | Rola | Narzędzia | Zapis |
|---|---|---|---|---|
| `orchestrator` | wszystkie | klasyfikuje, planuje, deleguje, liczy próby, prowadzi stan i pamięć, wybiera tryb przeglądu, zatrzymuje na bramce (tryb gate) i przy eskalacjach | wszystkie (dziedziczone) | tylko `runs/` i `memory/` |
| `analyst` | dev, design | wymagania i kryteria akceptacji | Read, Grep, Glob, Write, Skill | tylko własny plik wyniku `runs/<id>/analyst.md` |
| `spec-reviewer` | dev | zatwierdza spec albo zwraca z pytaniami | Read, Grep, Glob, Write, Skill | tylko własny plik wyniku `runs/<id>/spec-review.md` |
| `architect` | dev, docs | projekt techniczny i plan; recenzja dokumentacji | Read, Grep, Glob, Write, Skill | tylko własny plik wyniku `runs/<id>/architect.md` |
| `developer` | dev | kod test-first, poprawki | Read, Grep, Glob, Edit, Write, Bash, Skill | kod |
| `tester` | dev | weryfikacja per AC z dowodem | Read, Grep, Glob, Bash, Edit, Write, Skill | tylko testy |
| `review-security` | dev | przegląd bezpieczeństwa | Read, Grep, Glob, Skill | nie |
| `review-performance` | dev | przegląd wydajności | Read, Grep, Glob, Skill | nie |
| `review-style` | dev | konwencje, prostota, zakres | Read, Grep, Glob, Skill | nie |
| `designer` | design | flow, makiety, tokeny, handoff | Read, Grep, Glob, Edit, Write, Skill | tylko `runs/<id>/design/` |
| `brief-writer` | content | brief: cel, odbiorca, przekaz | Read, Grep, Glob, Skill | nie |
| `copywriter` | content | tekst główny i adaptacje per platforma | Read, Grep, Glob, Skill | nie |
| `docs-writer` | docs, dev | nowy dokument (docs) oraz aktualizacja dokumentacji po zmianie (dev, tryb `sync`) | Read, Grep, Glob, Edit, Write, Skill | tylko dokumentacja |
| `publisher` | wszystkie | gałąź, commit, PR (w trybie gate po zapisanej akceptacji) | Read, Grep, Glob, Bash, Skill | git |

## 2. Format uniwersalny

Jeden plik na agenta, ta sama treść dla obu narzędzi: `<nazwa>.agent.md`.

```yaml
---
name: review-security
description: jedno zdanie, kiedy używać
tools: [Read, Grep, Glob, Skill]
---
```

Dlaczego to działa w obu:

- **Rozszerzenie `.agent.md`** kończy się na `.md`, więc Claude Code ładuje plik
  z `.claude/agents/`, a Copilot z `.github/agents/`. Copilot CLI czyta też
  `.claude/agents/`, więc wystarczy jeden katalog.
- **Nazwy narzędzi w konwencji Claude** (`Read`, `Grep`, `Glob`, `Edit`,
  `Write`, `Bash`) są w Copilocie oficjalnymi aliasami `read`, `search`,
  `edit`, `execute`. Nierozpoznane nazwy Copilot ignoruje.
- **Brak pola `model`.** Agent dziedziczy model sesji w obu narzędziach.
  Identyfikatory modeli różnią się między hostami, więc wpisanie jednego
  zepsułoby drugi. Jeśli chcesz tańszy model dla recenzentów, dodaj pojedynczy
  string per host (Copilot CLI odrzuca tablicę w `model`).
- **Tylko pola wspólne.** Bez `skills`, `hooks`, `handoffs`, `mcp-servers`.
  Skille są wskazane w treści agenta, nie we frontmatterze.
- **Orchestrator nie ma listy `tools`**, bo potrzebuje narzędzi pamięci (MCP)
  i delegowania, których nazwy różnią się między hostami. Jego ograniczenia
  wynikają z treści: nie pisze kodu, nie publikuje.

Instalacja po przeniesieniu:

| Host | Katalog | Uruchomienie |
|---|---|---|
| Claude Code | `.claude/agents/` lub `~/.claude/agents/` | `claude --agent orchestrator` |
| Copilot CLI | `.github/agents/`, `.claude/agents/` lub `~/.copilot/agents/` | `copilot --agent orchestrator` |
| Copilot w VS Code | `.github/agents/` | wybór `orchestrator` w selektorze agentów |

## 3. Pipeline'y

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

| Pipeline | Kiedy | Etapy |
|---|---|---|
| dev | zmiana kodu | analyst → spec-reviewer → architect → developer → tester → 3 przeglądy równolegle → docs-writer (sync) → [bramka] → publisher |
| content | tekst dla odbiorców | brief-writer → copywriter → copywriter per platforma (równolegle) → [bramka] → publisher |
| docs | opis istniejącego | docs-writer → architect (recenzja) → [bramka] → publisher |
| design | „design", makieta, wireframe, UI/UX, redesign, `/design` | analyst → designer → [bramka] → publisher |

`[bramka]` jest tylko w trybie gate, patrz niżej. Każda prośba przechodzi
najpierw listę „Before the analyst” ze skilla `task-classification`: co już
istnieje poza repozytorium, co właściciel musi zrobić ręcznie, koszt,
oczekujące scalenia, niewypełnione placeholdery. Wszystkie otwarte pytania
trafiają do właściciela w jednej wiadomości na starcie (najwyżej 4, każde z
rekomendowanym domyślnym wyborem).

### Tryb przeglądu: `pr` albo `gate`

Po klasyfikacji orchestrator wybiera, kto robi przegląd, zanim powstanie pull
request, zapisuje to jako `task.review_mode` z uzasadnieniem i informuje Cię
jedną linią. Twoja wiadomość z nazwą trybu wygrywa („otwórz PR od razu” to
`pr`, „pokaż mi najpierw” to `gate`).

| Tryb | Punkt przeglądu | Publisher |
|---|---|---|
| `pr` (domyślny) | sam pull request; Ty go sprawdzasz i scalasz | uruchamiany automatycznie, gdy warunki są spełnione |
| `gate` | przebieg zatrzymuje się na bramce z raportem | dopiero po Twojej zapisanej akceptacji |

Orchestrator wybiera `gate`, gdy o to prosisz albo gdy zmiana edytuje AGENTS.md
lub odwraca zapisaną decyzję, dotyka wdrożeń, infrastruktury, poświadczeń lub
kodu istotnego dla bezpieczeństwa, migruje lub usuwa dane, ma skutek kosztowy
albo nowego dostawcę, publikuje gdziekolwiek poza pull requestem, który można
zamknąć (zawsze `gate`), albo zakres jest niejednoznaczny. W trakcie
przebiegu tryb może się tylko zaostrzyć, z `pr` do `gate`; wrócić może tylko
człowiek.

Zaakceptowany design nie uruchamia sam pipeline'u dev. Orchestrator proponuje
to na bramce i startuje nowy przebieg dopiero po Twojej zgodzie, z designem
jako wejściem.

### Dokumentacja idzie razem ze zmianą

Zmiana nie trafia na bramkę ani do pull requesta, dopóki dokumentacja opisuje stare zachowanie. W
pipeline dev, po czystych testach i przeglądach, orchestrator uruchamia
`docs-writer` w trybie `sync` z diffem i specyfikacją. Agent szuka miejsc w
dokumentacji, które zmiana czyni nieaktualnymi (README, katalog docs, notatki
architektoniczne, diagramy, changelog), i poprawia tylko je. Jeśli nic nie
wymaga zmiany, odpowiada `DOCS_AFFECTED: none` z listą przeszukanych miejsc.

Zaktualizowane dokumenty trafiają do tego samego PR co kod, a raport na bramce
je wymienia. Gdy późniejsza poprawka znów zmienia kod, sync jest powtarzany.
Ta sama reguła dotyczy samej orkiestracji: gdy `factory` dodaje lub zmienia
agenta, skill albo pipeline, ten dokument i mapa są aktualizowane w tym samym
przebiegu.

### Pętle w pipeline dev

```mermaid
flowchart TD
  AN[analyst] --> SR[spec-reviewer]
  SR -->|zwrot: spec niejasna · licznik spec| AN
  SR -->|zatwierdzona| AR[architect] --> DV[developer] --> TS[tester]
  TS -->|test nie przechodzi · licznik code| DV
  TS -->|AC niejednoznaczne · licznik spec| AN
  TS -->|błąd środowiska · max 2 ponowienia| TS
  TS -->|wszystkie AC pass| RV[przeglądy równoległe]
  RV -->|ustalenie blokujące · licznik code| DV
  RV -->|tylko ostrzeżenia| GT{Bramka}
  GT -->|drobna zmiana · licznik code| DV
```

| Co się stało | Dokąd wraca | Licznik |
|---|---|---|
| Spec niejasna | analyst | `spec`, max 3 |
| Test nie przechodzi | developer | `code`, max 3 |
| Ustalenie blokujące z przeglądu | developer | `code`, max 3 |
| Ostrzeżenie z przeglądu | raport na bramce | brak |
| Błąd środowiska | ponowienie kroku | bez licznika, max 2 |
| Poprawka content, docs lub design | agent-autor | `revision`, max 3 |

Po wyczerpaniu licznika etap przechodzi w `waiting_human`, a orchestrator
oddaje raport: cel, co zrobiono, wynik każdej próby, ostatni stan, otwarte
pytanie.

## 4. Kontrakt między agentami

Wzorowany na Superpowers (subagent-driven-development):

- **Brief** od orchestratora to cały kontekst agenta: id przebiegu, etap, numer
  próby, cel i sposób weryfikacji, ścieżki wejść, AC, co jest poza zakresem.
- **Status** w ostatniej wiadomości: `DONE`, `DONE_WITH_CONCERNS`,
  `NEEDS_CONTEXT`, `BLOCKED`. `NEEDS_CONTEXT` nie zużywa próby.
- **Raport to twierdzenie, nie dowód.** Orchestrator i tester sprawdzają
  dowody (wynik testu, diff), zanim etap dostanie `ok`.
- **Agenci robocze nie delegują.** Tylko orchestrator uruchamia agentów.
- **Recenzenci są niezależni:** dostają diff, spec i AC, nigdy raport ani
  rozumowanie developera. Są tylko do odczytu, poprawki robi developer.
  Synchronizacja dokumentacji działa po recenzjach: brak aktualizacji
  dokumentów nie jest uwagą, chyba że diff błędnie zmienia udokumentowane
  zachowanie lub zostawia sprzeczne dokumenty.
- **Pliki wyników.** Analyst, architect i spec-reviewer zapisują własny
  `runs/<run-id>/<stage>.md` (jedyny plik, który mogą zapisać) i zwracają
  ścieżkę z krótkim podsumowaniem; orchestrator czyta go z powrotem. Agenci
  bez narzędzia zapisu (recenzenci, brief-writer, copywriter) zwracają pełny
  raport w końcowej wiadomości, a orchestrator zapisuje go dosłownie.
- **Wymagania właściciela są śledzone.** Brief podaje je dosłownie jako
  R1..Rn. Analyst zaczyna wynik tabelą R → AC, a spec-reviewer zwraca spec, w
  której jakieś R nie ma AC.
- **Fakty pochodzą z plików.** Liczby, numery linii i wersje w briefie lub
  raporcie pochodzą z komendy albo pliku odczytanego w tej turze, nie z pamięci.
- **Agenci bez powłoki** (analyst, architect, spec-reviewer, docs-writer,
  recenzenci) nie zweryfikują komend; orchestrator daje im fakty i sprawdza ich
  diffy przez `git diff`.
- **CI wchodzi w „zielone”.** Tester czyta, co uruchamia CI, i wykonuje każdy
  krok albo zgłasza `NOT RUN` z powodem; liczby testów obejmują passed, failed
  i skipped, każdy pominięty z wyjaśnieniem.
- **Produkty zewnętrzne** opisuje się ogólnie, chyba że zweryfikowano je w
  sesji.
- **Zrzuty ekranu** zmian w UI trafiają tylko do opisu pull requesta;
  dołącza je orchestrator albo prosi o to właściciela. Nigdy do repozytorium.
- **`ERROR_CLASS`** (`implementation`, `spec_unclear`, `environment`) decyduje,
  dokąd wraca przebieg.

## 5. Stan i bramka

`runs/<run-id>/state.json` jest jedynym źródłem prawdy. Zapisuje tylko
orchestrator; wyniki etapów trafiają do `runs/<run-id>/<etap>.md`. Pełny
schemat jest w [wersji angielskiej](ORCHESTRATION.md#5-state-and-gate) i w
pliku `agents/orchestrator.agent.md`.

W trybie gate bramka jest przed publikacją, w każdym pipeline. W trybie `pr`
te same warunki (wszystkie AC `pass` z dowodem, brak otwartego ustalenia
blokującego, zielony pełny przebieg testów, zsynchronizowana dokumentacja, brak
sekretu w diffie, żaden licznik nie wyczerpany) od razu uruchamiają publishera.

| Decyzja | Skutek |
|---|---|
| Akceptuj | wpis w `decisions` (`by: human`), potem publisher |
| Odrzuć z uwagą | orchestrator wybiera etap i ponawia |
| Drobna zmiana | wraca do autora na liczniku `code` lub `revision` |

W trybie gate publisher sam czyta `state.json` i bez wpisu akceptacji zwraca
`BLOCKED`. Nie
pushuje na gałąź domyślną, nie robi force-push, nie scala PR.

Gdy pull request jest otwarty, orchestrator od razu zapisuje rekord przebiegu i
robi retrospektywę (wynik `pr_open`). Gdy zgłosisz scalenie, zapisuje `merged` i
jedną linią mówi, które scalone gałęzie czekają na usunięcie; sprzątanie
gałęzi nie należy do publishera.

### Rozmowa z właścicielem

Wiadomości są krótkie: najpierw wynik albo jedyna potrzebna rzecz, najwyżej
ok. 10 linii, szczegóły w plikach `runs/` i w opisie pull requesta.
Orchestrator pyta tylko o to, co blokuje postęp lub zmienia kryterium
akceptacji; w pozostałych przypadkach bierze rozsądną wartość domyślną,
zapisuje ją w `decisions` i wspomina o tym jedną linią. Pytania etapu łączy w
jedną wiadomość, najwyżej 3, każde z opcjami i rekomendowanym wyborem.

Pytania bez odpowiedzi są w `state.json` (`open_questions`) i w
`runs/<run-id>/open-questions.md`. Dopóki któreś jest otwarte, każda
wiadomość kończy się blokiem `Waiting for you: Q1 … (default: …)`, podanym w
całości, żeby wynik z tła nie zepchnął go z widoku. Praca niezależna od
odpowiedzi trwa dalej.

## 6. Skille

Agent ładuje skill, gdy pasuje do kroku. Gdy skilla nie ma, używa domyślnej
checklisty wpisanej w swój plik i zgłasza brak w polu `SKILLS_MISSING`. Dzięki
temu agenci są generyczni, a wiedza o projekcie (stack, konwencje) mieszka w
skillach.

**Skille ogólne (w tym repozytorium, w `skills/`, instalowane razem z agentami):**

| Skill | Używa |
|---|---|
| `task-classification`, `findings-merge`, `retrospective`, `factory` | orchestrator |
| `ac-format` | analyst |
| `spec-checklist` | spec-reviewer |
| `test-strategy` | tester |
| `security-checklist` | developer, review-security |
| `performance-checklist` | review-performance |
| `style-checklist` | review-style |
| `brief-format` | brief-writer |
| `platform-rules` | copywriter |
| `docs-template` | docs-writer |
| `commit-conventions`, `pr-template` | publisher |

**Skille projektowe (w repozytorium konkretnego projektu):** `stack-and-style`
(architect, developer, tester, recenzenci, docs-writer), `architecture-patterns`
(architect) i `design-system` (designer). Opisują jeden projekt, więc nie należą
do tego repozytorium. Skill projektowy o tej samej nazwie co ogólny ma w tym
projekcie pierwszeństwo.

**Skille zewnętrzne (instalowane jako pluginy, nie są tu kopiowane):**

| Źródło | Skille | Używa |
|---|---|---|
| multica-ai/andrej-karpathy-skills | `karpathy-guidelines` | orchestrator, analyst, spec-reviewer, architect, developer |
| obra/superpowers | `brainstorming` | analyst, brief-writer |
| | `writing-plans` | architect |
| | `test-driven-development`, `systematic-debugging` | developer, tester |
| | `receiving-code-review` | developer |
| | `verification-before-completion` | developer, tester |
| | `subagent-driven-development`, `dispatching-parallel-agents`, `requesting-code-review` | orchestrator |
| | `finishing-a-development-branch` | publisher |
| anthropics/skills | `frontend-design`, `web-artifacts-builder`, `canvas-design`, `theme-factory`, `brand-guidelines` | designer |
| | `brand-guidelines` | brief-writer, copywriter |
| | `internal-comms`, `doc-coauthoring` | copywriter, docs-writer |
| | `webapp-testing` | tester |
| DietrichGebert/ponytail | `ponytail` | architect, developer, designer |
| | `ponytail-review` | review-style |
| thedotmack/claude-mem | `mem-search` | orchestrator |

## 7. Co z którego rozwiązania

**Zasady Karpathy'ego.** Orchestrator stosuje cztery reguły na poziomie
delegowania: pomyśl przed delegowaniem (jawne założenia, jedno pytanie zamiast
cichego wyboru), najkrótszy pipeline, zakres chirurgiczny w każdym briefie, cel
weryfikowalny zamiast polecenia. Agenci, którzy analizują i decydują (analyst,
spec-reviewer, architect), oraz developer ładują ten sam skill do własnej pracy.

**Superpowers.** Kontrakt z sekcji 4, test-first u developera, dowód przed
werdyktem u testera, plan w małych zadaniach u architekta.

**Ponytail.** Drabina „najmniejszej kompletnej zmiany" u developera,
architekta i designera: czy to w ogóle potrzebne, czy już jest w kodzie,
biblioteka standardowa, zainstalowana zależność, jedna linia, dopiero potem
nowy kod. Nigdy nie tnie walidacji, obsługi błędów, bezpieczeństwa ani
dostępności. Skróty oznaczane komentarzem `shortcut:` trafiają do opisu PR.
`review-style` używa `ponytail-review`.

**Pamięć: zapis po każdym przebiegu.** Pamięć ma dwie warstwy i pisze do niej
tylko orchestrator.

Warstwa plikowa działa na każdym hoście. Po każdym przebiegu (opublikowanym,
odrzuconym lub eskalowanym) orchestrator zapisuje `memory/runs/<run-id>.md` i
dopisuje linię do `memory/INDEX.md`. Zapis ma mniej niż stronę i zawiera:
prośbę i wynik, decyzje z powodami (w tym Twoje z bramki), co się zapętliło i
co w końcu zadziałało, odrzucone podejścia, poznane konwencje projektu,
brakujące skille i kandydatów z retrospektywy. To wnioski, nie log; log jest w
`state.json`. Na starcie kolejnego przebiegu orchestrator czyta indeks i
otwiera tylko pasujące zapisy. Pliki pamięci nie wchodzą do PR przebiegu.

**claude-mem (pamięć przeszukiwalna, gdy zainstalowana).**

| Moment | Działanie |
|---|---|
| start przebiegu | przypomnienie w trzech krokach: `search` → `timeline` → `get_observations`; wcześniejsze decyzje, odrzucone podejścia, uwagi z bramek, powtarzające się ustalenia |
| w trakcie | do briefów trafia tylko kilka istotnych linii; nic z rozumowania developera nie idzie do recenzentów |
| bramka, eskalacja, koniec | świadoma notatka (`save_memory`): decyzja człowieka z powodem, przyczyna eskalacji, kandydaci z retrospektywy |

Pamięć jest doradcza: `state.json` i bieżące polecenie mają pierwszeństwo.
Brak pamięci nie zatrzymuje przebiegu: na starcie orchestrator raz sprawdza
każdą skonfigurowaną pamięć, zapisuje to w `trace`, od razu informuje
człowieka o awarii (mem0: `/mcp`) i w każdym briefie każe agentom pominąć
pamięć bez ponawiania. Retrospektywa używa pamięci do liczenia „trzech
powtórzeń" między przebiegami.

**Claude Code Agent Monitor (podgląd).** Działa przez hooki hosta, więc nie
wymaga niczego w agentach poza czytelnymi przebiegami: orchestrator zawsze
deleguje do nazwanych agentów i nazywa każde wywołanie
`[<run-id>] <agent> #<próba>`. W monitorze widać drzewo orchestrator → agenci,
narzędzia, tokeny i koszt.

## 8. Instalacja i synchronizacja

Instalacja agentów i skilli dla wszystkich projektów:

```bash
scripts/install.sh
```

Skrypt kopiuje `agents/*.agent.md` i każdy folder `skills/<nazwa>/` do
`~/.claude/` i `~/.copilot/` (do ich folderów `agents/` i `skills/`) i niczego
innego tam nie rusza. `--dry-run` pokazuje, co
by się zmieniło.

Przeniesienie zmian z folderu użytkownika z powrotem do repozytorium:

```bash
scripts/sync-back.sh
```

Skrypt porównuje folder użytkownika z `agents/` i `skills/`, tworzy gałąź
`sync/<znacznik-czasu>` i commituje to, co się zmieniło. `--add NAZWA` i
`--add-skill NAZWA` dodają agenta lub skill, którego repozytorium jeszcze nie
śledzi. `--push`
dodatkowo wypycha gałąź i otwiera pull request. Przed commitem skanuje
zmienione pliki pod kątem ścieżek domowych, adresów e-mail i formatów kluczy;
jeśli coś znajdzie, zatrzymuje się. Uruchamiaj go z aktualnej gałęzi domyślnej.

Zależności w Claude Code:

```
/plugin marketplace add forrestchang/andrej-karpathy-skills
/plugin install andrej-karpathy-skills@karpathy-skills
/plugin install superpowers@claude-plugins-official
/plugin marketplace add anthropics/skills
/plugin install example-skills@anthropic-agent-skills
/plugin marketplace add DietrichGebert/ponytail
/plugin install ponytail@ponytail
```

Copilot CLI:

```
copilot plugin marketplace add obra/superpowers-marketplace
copilot plugin install superpowers@superpowers-marketplace
copilot plugin marketplace add DietrichGebert/ponytail
copilot plugin install ponytail@ponytail
```

Pamięć i monitor:

```
npx claude-mem install
git clone https://github.com/hoangsonww/Claude-Code-Agent-Monitor.git
cd Claude-Code-Agent-Monitor && npm run setup && npm run dev
```

Monitor działa pod `http://localhost:5173` i przy pierwszym uruchomieniu
proponuje instalację hooków.

## 9. Ograniczenia i rzeczy do sprawdzenia

- **Monitor nie obsługuje Copilota.** Według README widzi sesje Claude Code,
  Cursor i Codex. Przebiegi w Copilocie nie pojawią się w panelu.
- **Monitor nie jest bramką.** Pokazuje sesje, nie czyta `state.json`. Decyzję
  podajesz orchestratorowi w rozmowie.
- **claude-mem w Copilot CLI tylko wyszukuje.** Sesje Copilota nie są
  nagrywane, więc pamięć przeszukiwalna rośnie z pracy w Claude Code. Warstwa
  plikowa w `memory/` działa wszędzie. Instalator prosi o
  logowanie i proponuje płatny okres próbny; da się to pominąć flagą
  `--provider` lub zmienną `CLAUDE_MEM_ONLINE_OPTIN=false`.
- **Skille w Copilocie.** Nazwa `Skill` na liście `tools` jest nazwą Claude
  Code. Trzeba sprawdzić, czy agent Copilota z zawężoną listą narzędzi nadal
  ładuje skille; jeśli nie, dopisz nazwę narzędzia skilli Copilota.
- **VS Code.** Format `.agent.md` w `.github/agents/` jest potwierdzony w
  dokumentacji GitHuba i Copilot CLI, jeszcze nie testowany w VS Code.
  `install.sh` nie obejmuje agentów użytkownika dla VS Code.
- **Nazwy skilli z pluginów** mogą mieć prefiks (np. `superpowers:brainstorming`).
  Agenci podają nazwę bez prefiksu; host dopasowuje po nazwie i opisie.
- Frontmattery przechodzą `claude plugin validate`. Pełny przebieg nie był
  jeszcze wykonany; przed użyciem załaduj każdego agenta w CLI i w VS Code.

## 10. Decyzje projektowe

| Decyzja | Powód |
|---|---|
| Jeden plik zamiast osobnych frontmatterów | Copilot przyjmuje nazwy narzędzi Claude jako aliasy i czyta `.claude/agents/` |
| `developer` ma `Bash` | test-first wymaga uruchamiania testów |
| `tester` ma `Edit`/`Write` | pisze brakujące testy per AC; tylko pliki testów |
| Licznik `revision` | poprawki content, docs i design nie są błędem kodu |
| `docs-writer` ma `Edit`/`Write` i etap `sync` w dev | dokumentacja ma się aktualizować razem ze zmianą; tylko pliki dokumentacji |
| `pr` jako domyślny tryb przeglądu | pull request już jest punktem przeglądu; bramka zostaje dla zmian trudnych do cofnięcia przez zamknięcie PR |
| `analyst`, `architect`, `spec-reviewer` mają `Write` | długie wyniki nie obciążają kontekstu orchestratora; każdy zapisuje jeden własny plik wyniku w `runs/` |
| Zapis przebiegu w `memory/` | dokument na przyszłość po każdym przebiegu, niezależny od hosta |
| Brak stacku w agentach | wiedza o projekcie należy do skilla `stack-and-style` |
