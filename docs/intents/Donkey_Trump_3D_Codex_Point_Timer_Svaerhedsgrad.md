# Donkey Trump 3D — samlet implementeringsopgave til Codex

**Status:** Godkendt ændringsbeskrivelse  
**Dato:** 17. oktober 2026  
**Omfang:** Pointafregning, leveltimer og stigende sværhedsgrad.

## Opgave

Implementér nedenstående i spillets eksisterende kode. Find først den nuværende logik for tøndehop, score, levelskift, tab af liv, pause, tøndekast og highscore. Følg projektets arkitektur og lokale instruktioner.

Denne beskrivelse samler og erstatter de tidligere forslag til disse regler. Lever en fungerende implementation med relevante tests og en kort beskrivelse af ændringer og verificering.

## Formål

Spillere har kunnet blive på en let bane, især på den øverste del, og samle mange point ved at hoppe over langsomme tønder. Det skal betale sig at gennemføre baner og komme hurtigt videre.

Løsningen kombinerer:

- En gennemførelsesbonus, der vokser med levelnummeret.
- Færre point pr. tøndehop og højst 20 pointgivende tønder på hvert level.
- En tidsbonus for hurtig gennemførelse.
- En timer på tre minutter pr. forsøg.
- Stadig hyppigere og hurtigere tønder baseret på samlet aktiv tid på samme level.

## 1. Begreber og tilstand

Brug spillerens synlige levelnummer `L`, hvor første level er **1**. Konvertér korrekt, hvis koden internt bruger et indeks fra 0.

Hold to tidsbegreber adskilt:

| Tilstand | Betydning |
|---|---|
| Samlet aktiv leveltid, `T` | Aktiv spilletid på det aktuelle level, summeret på tværs af liv. Styrer sværhedsgrad og tidsbonus. |
| Resterende forsøgstid, `R` | Nedtælling fra 180 sekunder på det aktuelle forsøg. Timeout medfører tab af liv. |

Derudover skal tilstanden kunne repræsentere antal pointgivende tønder på levellet, hvilke tønder der allerede har udløst point, samt om forsøget eller levellet allerede er afsluttet.

Tilpas felter og navne til eksisterende kode. Tilføj ikke en ny parallel spilmotor eller unødvendig arkitektur.

## 2. Pointafregning

### 2.1 Gennemførelsesbonus

Når spilleren gennemfører et level:

```text
gennemførelsesbonus = 1000 × L
```

Bonussen lægges til den samlede score præcis én gang pr. gennemført level.

### 2.2 Point for tøndehop

Et vellykket hop over en tønde giver:

```text
tøndepoint = 10 × L
```

Regler:

- Kun de første **20 forskellige tønder**, som spilleren hopper vellykket over på det aktuelle level, giver point.
- Grænsen gælder samlet på tværs af alle liv på samme level.
- En tønde må højst udløse point én gang på levellet, også ved gentagne krydsninger eller registrering over flere frames.
- En ny tønde fra en genbrugt objektpulje er en ny tøndeinstans og skal have en entydig identitet for sin levetid. Undgå at genbrugte identifikatorer giver fejl.
- Efter 20 pointgivende tønder kan spilleren stadig hoppe over tønder, men modtager ingen yderligere tøndepoint på dette level.
- Et almindeligt hop uden passage af en tønde giver ikke tøndepoint.
- Vis kort den optjente pointværdi ved et pointgivende hop. Vis ikke en positiv pointindikator for hop, der ikke giver point.
- Ved overgang til næste level nulstilles grænsen og registreringen af pointgivende tønder.

Maksimale tøndepoint pr. level er dermed:

```text
maksimale tøndepoint = 20 × 10 × L = 200 × L
```

### 2.3 Tidsbonus ved gennemførelse

Tidsbonussen bruger **samlet aktiv leveltid**, ikke den aktuelle forsøgstimer:

```text
bonussekunder = floor(max(0, 180 − T))
tidsbonus = 5 × L × bonussekunder
```

- Brug hele tilbageværende bonussekunder og afrund ned.
- Bonussen gives kun ved gennemførelse, præcis én gang.
- Efter mindst 180 sekunders samlet aktiv tid på samme level er tidsbonussen 0.
- Tab af liv genskaber ikke tidsbonussen.
- Gennemførelsesbonus og tidsbonus lægges til den allerede optjente score.

### 2.4 Pointoversigt

| Level | Gennemførelse | Pr. pointgivende tønde | Maks. tøndepoint | Tidsbonus pr. bonussekund |
|---|---:|---:|---:|---:|
| 1 | 1.000 | 10 | 200 | 5 |
| 2 | 2.000 | 20 | 400 | 10 |
| 3 | 3.000 | 30 | 600 | 15 |
| L | 1.000 × L | 10 × L | 200 × L | 5 × L |

Eksempel A: Level 1 gennemføres efter præcis 60 sekunder med 10 pointgivende tøndehop:

```text
1000 + (10 × 10) + (5 × 120) = 1700 point
```

Eksempel B: Level 2 gennemføres efter præcis 120 sekunder med 5 pointgivende tøndehop:

```text
2000 + (5 × 20) + (10 × 60) = 2700 ekstra point
```

Efter begge disse levels er samlet score **4.400 point**, forudsat ingen andre pointkilder.

### 2.5 Integration med eksisterende score

Erstat den gamle beregning for tøndehop og gennemførelse. Undgå at gamle og nye belønninger bliver lagt oven i hinanden. Fjern eventuelle gamle bonusser for de samme hændelser, så de beskrevne formler er autoritative.

Undersøg eventuelle øvrige pointkilder og rapportér dem. De må ikke omgå tøndepointgrænsen eller fortsætte med at belønne passiv ventetid.

Brug én autoritativ samlet score i HUD, levelresultat, Game Over og highscoreindsendelse. Der indføres ingen ny pointstraf ved tab af liv; allerede optjente point bevares.

## 3. Timer: tre minutter pr. forsøg

- Et nyt level starter med `R = 180` sekunder.
- Vis timeren tydeligt i HUD som `M:SS`, begyndende med **3:00**.
- Når forsøgstiden når 0, mister spilleren præcis ét liv.
- Har spilleren liv tilbage, bruges spillets eksisterende genstart af det aktuelle level. Det nye forsøg starter med `R = 180`.
- Genstart efter andre former for tab af liv starter også med 180 sekunder.
- Er der ikke flere liv, udløses det eksisterende Game Over.
- Ingen gennemførelsesbonus eller tidsbonus gives ved timeout.
- Stop nedtællingen, så snart forsøget er afsluttet. Timeren må ikke fortsætte under dødsanimation eller levelovergang og udløse flere tab af liv.

### Aktiv spilletid

Både `T` og forsøgstimeren opdateres kun under aktivt gameplay:

- Pause og app i baggrunden tæller ikke med.
- Dødsanimation, respawn, levelovergang og Game Over tæller ikke med.
- Tiden skal være uafhængig af billedfrekvensen og baseres på en monoton tidskilde eller spillets eksisterende korrekte tidsstyring.
- Ved genoptagelse må tidsrummet i pause eller baggrund ikke blive behandlet som aktiv spilletid.
- Gem tiden med tilstrækkelig præcision internt; afrund kun ved visning og ved beregning af hele bonussekunder.

## 4. Stigende sværhedsgrad på samme level

Brug hvert levels eksisterende grundsværhedsgrad som udgangspunkt. Gem eller udled uændrede grundværdier for kastinterval og tøndehastighed.

Sværhedsgraden vokser glidende over de første 180 sekunders samlede aktive leveltid:

```text
p = clamp(T / 180, 0, 1)

kastintervalMultiplikator = 1 − 0.60 × p
tøndehastighedMultiplikator = 1 + 0.25 × p

ønsketKastinterval = levelletsGrundinterval × kastintervalMultiplikator
ønsketTøndehastighed = levelletsGrundhastighed × tøndehastighedMultiplikator
```

| Samlet aktiv tid | Kastinterval i forhold til grundinterval | Hastighed i forhold til grundhastighed |
|---|---:|---:|
| 0 sekunder | 100 % | 100 % |
| 60 sekunder | 80 % | ca. 108,33 % |
| 120 sekunder | 60 % | ca. 116,67 % |
| 180 sekunder og senere | 40 % | 125 % |

Et interval på 40 % betyder kortere tid mellem kast, ikke 40 % færre kast.

Regler:

- Øg hyppigheden af kast og tøndernes bevægelseshastighed glidende.
- Beregn altid ud fra levellets grundværdier. Gang ikke multiplikatorer på den allerede ændrede værdi hver frame.
- Brug samme model konsekvent for nye og aktive tønder, hvor deres bevægelsestype tillader det.
- Tab af liv nulstiller ikke `T` eller intensiteten.
- Efter 180 sekunder fastholdes maksimal intensitet, også hvis forsøgstimeren senere nulstilles efter tab af liv.
- Et nyt level starter ved sin egen grundsværhedsgrad med `T = 0`.
- Intensiteten afhænger af tid på levellet, ikke af spillerens placering.
- Pause eller genoptagelse må ikke skabe en bunke forsinkede kast på én gang.

### Spilbarhed

De godkendte multiplikatorer er startværdier til spiltest. Hyppigheden skal skabe pres, samtidig med at der stadig er fysisk mulige hop og landinger.

Undersøg figurens hop, landing og tøndernes afstand i den eksisterende implementation. Tilføj et passende minimumsinterval, hvis det er nødvendigt for spilbarheden. Bevar den ønskede stigning inden for denne grænse. Beskriv enhver sådan begrænsning og begrund den konkret.

## 5. Nulstilling af tilstand

| Hændelse | Forsøgstid R | Samlet leveltid T | Pointgivende tønder / grænse | Samlet score |
|---|---|---|---|---|
| Helt nyt spil | 180 sekunder | 0 | Nulstilles | 0 |
| Nyt level | 180 sekunder | 0 | Nulstilles | Bevares og tilføres optjente bonusser fra forrige level |
| Tab af liv med liv tilbage | 180 sekunder ved nyt forsøg | Bevares | Bevares | Bevares |
| Pause / baggrund | Fryses | Fryses | Bevares | Bevares |
| Game Over | Stoppes | Stoppes | Ingen yderligere optjening | Endelig score |

Hvis spillet allerede kan gemme og genoptage en igangværende runde, skal de nye felter følge samme gemte spiltilstand. Genoptagelse af samme runde må ikke genskabe bonussekunder eller tøndepoint. Der kræves ikke et helt nyt system til gemte spil.

## 6. Hændelser og dobbelttælling

Brug det eksisterende hændelses- eller tilstandssystem til at sikre, at:

- Samme tønde ikke giver point flere gange.
- Samme gennemførelse ikke giver bonus flere gange.
- Timeout og kollision i samme opdatering ikke koster to liv.
- Afsluttede forsøg ikke kan fortsætte med at optjene point.
- Et level ikke både gennemføres og genstartes på grund af timeout.
- Hvis tiden er udløbet, før målet nås, behandles hændelsen som timeout.
- En gyldigt registreret gennemførelse før udløb stopper timeren og anvender tidsbonussen ved gennemførelsestidspunktet.

Undgå, at rækkefølgen af callbacks giver tilfældige resultater ved samme hændelsesgrænse.

## 7. HUD, resultater og highscore

- Vis den aktuelle samlede score og forsøgstimeren tydeligt.
- Vis pointfeedback kun ved faktiske pointtildelinger.
- Hvis en levelresultatvisning findes, vis gennemførelsesbonus og tidsbonus med korrekte værdier.
- Highscoreindsendelsen skal bruge den endelige autoritative score.
- Opdatér eksisterende hjælpetekster om point og tid, hvor det er relevant.
- Slet eller omregn ikke eksisterende highscores automatisk.

Den nye pointmodel kan give andre resultater end den gamle. Undersøg eksisterende støtte til versionering af highscorelister. Beskriv eventuelle problemer med sammenlignelighed og en konkret anbefaling i leverancen; opret ikke en ny tjeneste eller slet data som del af denne opgave.

## 8. Acceptkriterier og relevante tests

Brug projektets eksisterende testopsætning. Test beregninger og kritiske overgange; undgå tests, der kun gentager implementationen.

1. **Level 1:** 10 forskellige tøndehop og gennemførelse efter præcis 60 aktive sekunder giver 1.700 point.
2. **Level 2:** 5 forskellige tøndehop og gennemførelse efter præcis 120 aktive sekunder giver 2.700 ekstra point.
3. **Levelnummer:** Første synlige level beregnes med L = 1, uanset internt indeks.
4. **Tøndegrænse:** 20 forskellige pointgivende tønder på level 1 giver samlet 200 tøndepoint. Tønde 21 og senere giver 0.
5. **Samme tønde:** Gentagne callbacks eller senere hop over samme tønde giver ingen ekstra point.
6. **Objektpulje:** Genbrug af et tøndeobjekt til en ny tøndeinstans giver korrekt identitet uden dobbelttælling eller utilsigtet manglende point.
7. **Tab af liv:** Efter 12 pointgivende tønder og tab af liv er der kun 8 pointgivende tønder tilbage på samme level.
8. **Timeout:** 180 aktive sekunder i ét forsøg trækker præcis ét liv og giver et nyt forsøg med 3:00, hvis der er liv tilbage.
9. **Sidste liv:** Timeout på sidste liv giver Game Over og ingen ny aktiv timer.
10. **Bevaret tid:** Efter 60 aktive sekunder, tab af liv og yderligere 60 aktive sekunder er T = 120. Tidsbonus og intensitet bruger 120, selvom forsøgstimeren er blevet nulstillet.
11. **Ingen ny tidsbonus:** Efter mindst 180 samlede aktive sekunder på samme level er tidsbonussen 0, også efter tab af liv.
12. **Sværhedsgrad:** Formlerne giver de angivne multiplikatorer ved T = 0, 60, 120 og 180 og fastholder maksimum efter 180.
13. **Grundværdier:** Mange opdateringer med samme T må ikke få hastigheden til at vokse yderligere eller intervallet til at falde yderligere.
14. **Pause / baggrund:** Hverken forsøgstid, samlet aktiv tid eller intensitet ændres under pause eller baggrund.
15. **Billedfrekvens:** Samme aktive varighed giver samme tid og pointberegning ved forskellige opdateringsfrekvenser, inden for relevant numerisk tolerance.
16. **Samtidige hændelser:** Timeout og kollision koster højst ét liv; gennemførelse og timeout kan ikke begge anvendes.
17. **Nyt level:** Tællere nulstilles korrekt, mens samlet score bevares og det nye levels egne grundværdier anvendes.
18. **Highscore:** HUD, slutresultat og indsendt highscore viser samme autoritative score.
19. **Spiltest:** Afprøv ophold på øverste del gennem et helt forsøg, og kontrollér stigende pres, maksimal tøndepointoptjening og fysisk mulige hop ved høj intensitet.

## 9. Afsluttende leverance fra Codex

- Implementér ændringerne i de relevante eksisterende filer.
- Kør relevante tests og de buildkontroller, som projektet og miljøet understøtter.
- Beskriv kort, hvad der er ændret, samt hvilke tests og kontroller der er udført.
- Angiv præcist, hvis build eller visuel spiltest ikke kan gennemføres i miljøet.
- Rapportér relevante øvrige pointkilder, eventuel begrænsning af kastinterval og forholdet til eksisterende highscores.
- Opgaven omfatter implementation og verificering, ikke udgivelse til App Store.

