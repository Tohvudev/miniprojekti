# miniprojekti
Haaga-Helian Palvelinten hallinta ICI001AS3A-3012 kurssin miniprojekti


Projektin tavoitteena on rakentaa kehitysympäristö, jossa kaksi virtuaalikonetta konfiguroidaan Saltin avulla:

### 1. Devbox

Automaattisesti Saltilla provisionoitu ympäristö kehitystyöhön

Ajaa VS Code Serveriä, jota voidaan käyttää selaimen kautta

Projektia voi muokata suoraan devboxissa ilman paikallista editoria

Devboxissa on Git ja työkalut joiden avulla kehittäjä voi puskea muutokset GitHubiin

### 2. Web-palvelin

Toinen virtuaalikone toimii tuotantopalvelimena/testipalvelimena

Noutaa sivuston tiedostot GitHub-reposta (tässä index.html) Saltin avulla

Päivittää ja julkaisee sivut

### Eli kokonaisuudessaan

Devboxissa kehitetään → muutokset GitHubiin → webserveri päivittää ne → päivitetyt sivut näkyvät


## Asennus

Toteutus on tehty Vagrantin avulla luomalla tarvittavat virtuaalikoneet, joista Devbox vaatii enemmän RAM muistia raskaan kehitysympäristön vuoksi. Järjestelmässä on määritelty ennaltaan sekä Salt Master että Minionit, ja kaikille koneille on asennettu tarvittavat Salt paketit.
