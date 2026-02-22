#let en(body) = text(lang: "en", [#{ body }])

= Obiettivi

== Obiettivi primari
Il progetto ha come scopo principale il realizzare un #en[cluster] Docker Swarm
eterogeneo composto da nodi x86_64 e ARM64. In particolare si vuole
automatizzare la creazione e la configurazione delle macchine virtuali e fisiche
che comporranno il #en[cluster], automatizzare la creazione e configurazione del
#en[cluster] Docker Swarm, e testare il tutto per assicurarsi il funzionamento
del sistema e la riproducibilità delle procedure di #en[deployment].

== Obiettivi secondari
Si è voluto sfruttare la realizzazione di questo progetto per sperimentare con
tecnologie e strumenti quali Ansible e Terraform (OpenTofu) per le procedure di
#en[deploy], #en[`just`] come strumento di supporto per ottenere comandi
personalizzati e alias per semplificare e rendere più intuitivi i passaggi per
le procedure di #en[deployment], Proxmox #en[Virtual Environment] (ProxmoxVE o
PVE) come #en[hypervisor] per la creazione di macchine virtuali (VM) x86_64, Nix
per gestire in modo centralizzato e riproducibile l'ambiente di sviluppo e
#en[Continuous Integration] (CI), e Typst per la realizzazione di questa
relazione.

= Tecnologie e strumenti

== Macchine
L'hardware utilizzato come #en[target] per testare nella pratica le procedure di
#en[deploy] del #en[cluster] Docker Swarm si compone di un mini PC con CPU
x86_64 e abbastanza RAM per poter ospitare almeno 2 VM (nel dettaglio questa
macchina monta una CPU Intel N95 e 8GB RAM LPDDR5), e di un computer con CPU
ARM64 (in questo caso un RaspberryPi 3 Model B, che monta una CPU Broadcom
BCM2837 e 1GB RAM LPDDR2).

Il mini PC utilizza come #en[hypervisor] ProxmoxVE 8.4, distribuzione Linux
basata su Debian 12 che permette di gestire in maniera semplificata VM e
#en[container] LXC sia tramite SSH che interfaccia web, oltre ad avere delle API
utilizzabili da software terzi. Il RaspberryPi invece utilizza una versione di
Debian 12 ottimizzata dai produttori del SBC #footnote[#en[Single Board
  Computer]] per questa piattaforma.

== Strumenti utilizzati

=== Creazione e gestione delle macchine virtuali
La creazione delle macchine virtuali è stata automatizzata mediante l'uso di
OpenTofu, uno strumento per definire infrastruttura tramite file di
configurazione scritti in un linguaggio dichiarativo (#en[Infrastructure as
  Code], IaC). OpenTofu è ospitato dalla Linux Foundation ed è un #en[fork] di
Terraform, uno strumento per IaC molto diffuso ma dibattuto a causa del cambio
dalla licenza FOSS #footnote[#en[Free and Open Source Software]] #link(
  "https://www.mozilla.org/en-US/MPL/2.0/",
)[MPL-2.0] alla licenza #en[open-source] #link(
  "https://www.hashicorp.com/en/bsl",
)[BSL], cosa che ha alienato una buona parte della #en[community]. OpenTofu,
tramite le API di ProxmoxVE, è in grado di creare, clonare, e distruggere
macchine virtuali, template, dischi virtuali e altre risorse; in questo caso
specifico è utilizzato per creare e configurare delle VM a partire da un
template precedentemente creato, a cui vengono poi collegati un piccolo disco
virtuale ulteriore contenente i file di configurazione per #link(
  "https://cloud-init.io/",
)[cloud-init], servizio preinstallato nelle VM che permette di configurare
all'avvio le interfacce di rete, un utente di default con relative credenziali
per l'accesso (remoto e non), e altro ancora che in questo caso specifico non è
stato sfruttato.

=== Configurazione delle macchine
La configurazione delle macchine virtuali e del RaspberryPi, ad eccezione delle
intefacce di rete e del utente, è stata effettuata usando Ansible che permette
tramite dei file in formato YAML di definire una sequenza di istruzioni e/o
dichiarazioni in cui si definisce lo stato di componenti del sistema, così da
astrarre dettagli implementativi (esempio: "il pacchetto X deve essere
installato e aggiornato all'ultima versione", poi ci penserà Ansible ad
effettuare i vari controlli ed eventualmente l'installazione o aggiornamento del
pacchetto).

=== Docker Swarm
Docker Swarm, o più propriamente "Docker Swarm mode", è una funzionalità
nativamente presente nel #en[engine] Docker che permette di gestire nativamente
un #en[cluster] di molteplici Docker Engine. Docker Swarm è caratterizzato dal
permettere una gestione semplificata del #en[cluster], con un rudimentale
bilanciamento del carico e sistema di #en[scaling] per gestire istanze multiple
di un #en[container] su più macchine, mantenendo l'approccio dichiarativo per la
definizione dei servizi ed espandendo le reti virtuali per funzionare su più
nodi.

=== Strumenti per il supporto allo sviluppo
Per la gestione del ambiente di sviluppo è stato scelto l'uso di Nix, in quanto
permette di definire in modo dichiarativo (tramite un linguaggio funzionale)
quali pacchetti devono essere disponibili allo sviluppatore e la relativa
versione, permettendo quindi di costruire un ambiente riproducibile. Nix,
inoltre, è stato utilizzato per facilitare la definizione di #en[pipeline] per
#en[Continuous Integration] (CI) e per impostare in Git l'esecuzione automatica
di controlli #en[pre-commit] e #en[pre-push] relativi alla formattazione e
#en[linting] dei file modificati. Per semplicità non è stato utilizzato Nix per
la creazione delle immagini delle macchine virtuali e del OS per RaspberryPi.
Per semplificare le procedure di dispiegamento e distruzione delle VM e per il
lancio dei vari #en[playbook] Ansible si è scelto di utilizzare #link(
  "https://github.com/casey/just",
)[#en[just]], #en[command launcher] moderno ispirato da `make` ma con
l'obiettivo di risolvere o evitare alcune sue #link(
  "https://github.com/casey/just?tab=readme-ov-file#what-are-the-idiosyncrasies-of-make-that-just-avoids",
)[idiosincrasie] e allo stesso tempo semplificando il file di configurazione.

=== Cenni su altre tecnologie coinvolte

=== SSH
SSH è un protocollo estremamente diffuso per l'accesso remoto a
#en[shell]/terminali su computer remoti in maniera sicura e crittografata. In
questo progetto è stato utilizzato per accedere manualmente alle singole
macchine durante lo sviluppo, e viene utilizzato da Ansible per l'esecuzione dei
#en[playbook].

==== QCOW2
QCOW2 (#en[QEMU Copy On Write]) è uno dei formati standard per le immagini di
dischi virtuali in ambienti Linux, caratterizzato dal poter allocare spazio solo
quando effettivamente necessario (invece di dover pre-allocare dall'inizio tutto
lo spazio necessario al disco virtuale come per le immgini RAW) così da
risparmiare spazio su disco, sopratutto se il #en[filesystem] sottostante non
supporta e/o ottimizza file sparsi #footnote([#link(
  "https://it.wikipedia.org/wiki/File_sparso",
)]). Permette inoltre il salvare le sole differenze rispetto a un'immagine QCOW2
in modalità sola lettura presa come riferimento, così da poter avere molteplici
VM che utilizzano lo stesso disco base senza però dover avere un'intera copia
per ogni singola VM.

=== LVM
LVM (#en[Logical Volume Manager]) è un #en[framework] per mappare blocchi di
dischi fisici in blocchi di dischi virtuali (chiamati "volumi"), fornendo
inoltre funzionalità come l'unire in un disco virtuale più dischi fisici,
#en[snapshot] dei dischi per poterne facilmente eseguire il #en[backup],
ridimensionamento semplificato delle partizioni, e RAID software. ProxmoxVE può
utilizzare volumi LVM come immagini per dischi delle VM.

=== Typst
Typst (pronunciato #en[typist]) è un linguaggio di marcatura (#en[markup
  language]) per la preparazione di testi e uno strumento per il suo rendering
in formato PDF o HTML. È un'alternativa a LaTeX più moderna e semplice.

= Scelte progettuali e implementative

Visto l'hardware a disposizione si è scelto per la creazione di un cluster
formato da 3 nodi, in particolare il RaspberryPi come nodo fisico ARM64 con
ruolo "#en[worker]" e 2 VM sul mini PC di cui una con ruolo "#en[manager]" e
l'altra "#en[worker]", in quanto le VM potenzialmente hanno a disposizione più
risorse.

La creazione delle VM è stata automatizzata tramite OpenTofu, ma i file di
configurazione dovrebbero essere interamente compatibili con Terraform. Si è
scelto OpenTofu sopra Terraform solo per motivi filosofici relativi alla
licenza: in questo caso, essendo un progetto personale e non a scopo di lucro,
la licenza non comporta impatti pratici, e non ci sono altre differenze
sostanziali tra le due soluzioni. Per le VM si è scelto di allocare 2 #en[core]
virtuali, 2GiB di RAM e 3GiB di disco ciascuna, valori modificabili tramite il
file `terraform/main.tf`. Tramite il file `terraform/credential.auto.tfvars`,
bisogna dichiarare le credenziali per l'accesso alle API di ProxmoxVE, il
#en[path] di una chiave pubblica SSH e una password per la configurazione del
utente root, eventrualmente un server DNS e un dominio; infine permette di
dichiarare i nodi che verranno creati e configurati specificando per ognuno un
nome univoco, un eventuale ID numerico univoco (di default viene preso il primo
ID disponibile), il template di partenza e le impostazioni di rete (di default
viene impostato l'uso di DHCP per IPv4 e SLAAC #footnote[#link(
  "https://en.wikipedia.org/wiki/IPv6#Stateless_address_autoconfiguration_(SLAAC)",
)] per IPv6). Qui sotto è stato riportato un esempio di configurazione.

```tfvars
proxmox_api_url          = "https://a.b.c.d:8006/api2/json"
proxmox_api_token_id     = "user@pam!name"
proxmox_api_token_secret = "secret-token"

ssh_public_keys = [
  ~/.ssh/id_rsa.pub
]
password = "secret_password"

proxmox_node = "pve"

nameserver   = "1.1.1.1" # Optional
#searchdomain = "mydomain.com" # Optional

nodes = [
  {
    name     = "swarm1" # Must be unique
    # id: unset or 0 means "the first available"
    id       = 0
    template = "debian12"
    #network  = "ip=dhcp,ip6=auto" # Default network settings
    network  = "ip=10.0.0.25/16,gw=10.0.0.1,ip6=fabc::25/64,gw6=fabc::1"
  },
  # other nodes
]
```

La configurazione del RaspberryPi e delle VM (dopo il #en[provisioning]) avviene
tramite Ansible, scelto in quanto strumento #en[open source] molto diffuso, ben
documentato e supportato, utile per la gestione e configurazione parallela di
molteplici macchine tramite "#en[playbook]" definiti in modo dichiarativo. In
questa fase le azioni principali che svolge Ansible è l'installazione e
abilitazione di `qemu-guest-agent` all'interno delle VM così da permettere un
miglior monitoraggio da parte del #en[hypervisor], poi su tutti i nodi procede
con l'installazione di Docker e la configurazione del #en[cluster] Docker Swarm.
Tramite il file `ansible/inventory` bisogna configurare gli IP (o #en[hostname]
risolvibili da un server DNS) delle varie macchine e relativi ruoli così da
permettere ad Ansible di agire in modo diverso in base al fatto che un nodo sia
fisico o virtuale e in base al ruolo che avrà nel #en[cluster] ("#en[worker]" di
default), e la chiave privata SSH che dovrà venir usata da Ansible per
comunicare con i nodi. Questo file è stato strutturato in modo da permettere una
configurazione elastica, per esempio permette l'uso di solo nodi virtuali (o
solo nodi fisici) e la presenza di più nodi "#en[manager]". Qui sotto è
riportato un esempio di configurazione.

```ini
[baremetal]
10.0.0.10

[vm]
10.0.0.20
10.0.0.21

[cluster_manager]
10.0.0.20

[all:vars]
ansible_ssh_user=root
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

Sempre tramite Ansible sono stati creati dei #en[playbook] per il dispiegamento
di alcuni container come test.

= Spiegazione utilizzo e funzionamento

Dopo aver ottenuto una copia del repository git
(`git clone https://github.com/as3ii/heterogeneous-swarm.git`), si proceda con
la lettura del file `README.md` per ottenere le informazioni più aggiornate per
la creazione di un template per le VM nel caso già non lo si abbia, la lista dei
programmi necessari per l'uso del progetto, le istruzioni sul come configurare
OpenTofu e Ansible e la procedura di #en[deploy] del #en[cluster]. Nix non è
necessario per l'uso del repository, ma è consigliato per avere un ambiente di
lavoro riproducibile e per beneficiare di diversi automatismi nel caso si voglia
proseguire con lo sviluppo e contribuire al progetto. `just` è consigliato in
quanto semplifica la procedura di #en[deploy], astraendo diversi comandi.

Di seguito la spiegazione dei comandi relativi a `just` (eseguiti dalla radice
del repository):

- `just fmt`: chiama a sua volta `just terraform/fmt` e `just ansible/fmt`
  - `just terraform/fmt`: esegue `tofu fmt` all'interno della cartella
    `terraform/`, per formattare automaticamente i file `.tf` e `.tfvars`.
  - `just ansible/fmt`: stampa "TODO fmt", al momento la formattazione dei file
    YAML non viene gestita.
- `just check`: chiama a sua volta `just terraform/check` e `just ansible/check`
  - `just terraform/check`: si assicura che all'interno della cartella
    `terraform/` OpenTofu sia inizializzato (`tofu init`), poi esegue
    `tofu validate` per verificare che i file di configurazione siano corretti.
  - `just ansible/check`: si assicura che i #en[playbook] specificati all'inizio
    di `ansible/justfile` e i relativi #en[playbook] figli sia corretti tramite
    `ansible-playbook $playbook.yaml --syntax-check`.
- `just tdeploy`: è un alias di `just terraform/deploy`
  - `just terraform/deploy`: verifica la correttezza dei file al pari di
    `just terraform/check`, poi esegue `tofu apply` per eseguire il #en[deploy]
    delle VM. Se già esistono, verranno modificate se necessario. OpenTofu
    chiederà conferma prima di effettuare modifiche, mostrando cosa verrà
    modificato.
- `just adeploy`: è un alias di `just ansible/deploy`
  - `just ansible/deploy`: eseguirà subito il #en[playbook] principale,
    verificando che le VM abbiamo `qemu-guest-agent` installato e attivo, che
    tutti i nodi siano aggiornati, che abbiamo installato Docker, e procederà
    con la creazione del #en[cluster] Docker Swarm.
- `just deploy`: esegue `just tdeploy` e poi `just adeploy`
- `just dry`: chiama `just terraform/dry` e `just ansible/dry`
  - `just terraform/dry`: si assicura che all'interno della cartella
    `terraform/` OpenTofu sia inizializzato (`tofu init`), poi esegue
    `tofu plan` per mostrare quali modifiche verrebbero applicate nel caso
    venisse lanciato `tofu apply`.
  - `just ansible/dry`: eseguirà il #en[playbook] principale senza
    effettivamentemodificare i nodi mostrando solo quali modifiche verrebbero
    effettuate, eseguendo `ansible-playbook playbook.yaml --check` all'interno
    della cartella `ansible/`.
- `just populate`: alias di `just ansible/populate`
  - `just ansible/populate`: eseguirà
    `ansible-playbook utils/swarm-populate.yaml`
    all'interno della cartella `ansible/` per avviare la creazione automatica di
    un container `registry` in tutti i nodi #en[manager], copierà i file
    contenuti in `ansible/utils/templates/` nel primo nodo #en[manager] da cui
    poi procederà con la creazione di una rete Docker e lancerà alcuni container
    come Traefik e Graphana-Alloy.
- `just full-deploy`: esegue `just deploy` seguito da `just populate`
- `just destroy`: esegue `just terraform/destroy` e `just ansible/destroy`
  - `just terraform/destroy`: lancerà `tofu destroy`, che procederà con la
    rimozione delle VM e relative risorse collegate.
  - `just ansible/destroy`: lancerà `ansible-playbook utils/swarm-destroy.yaml`,
    che rimuoverà tutti i container presenti in docker, farà lasciare al nodo il
    #[cluster] Docker Swarm e infine effettuerà una pulizia di tutte le immagini
    e volumi che potrebbero essere rimasti nei nodi.

Nota: eseguire per esempio `just ansible/check` è equivalente ad entrare nella
cartella `ansible/` ed eseguire `just check`.

= Fonti
Di seguito i link ai software utilizzati e altra documentazione o progetti da
cui è stata presa ispirazione per la realizzazione di questo progetto.
Intelligenze Artificiali (AI) sono state utilizzate ma solo in minima parte,
come supporto per la ricerca di soluzioni alternative. Nessun output di AI è
stato direttamente utilizzato integralmente o in parte.

== OpenTofu e ProxmoxVE
- OpenTofu: #link("https://opentofu.org/")
- Libreria per l'interfacciamento con le API di ProxmoxVE: #link(
    "https://registry.terraform.io/providers/Telmate/proxmox/latest/docs",
  )
- Esempi di configurazioni Terraform per ProxmoxVE: #link(
    "https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/examples",
  )
- Documentazione di ProxmoxVE: #link("https://pve.proxmox.com/pve-docs/")

== Ansible e Docker
- Documentazione di Ansible: #link("https://docs.ansible.com/ansible/latest/")
- Documentazione Docker Swarm:
  - #link("https://docs.docker.com/reference/cli/docker/swarm/")
  - #link("https://docs.docker.com/engine/swarm")
- Container usati per i test:
  - #link("https://doc.traefik.io/traefik/")
  - #link("https://grafana.com/docs/alloy/latest/")
- Esempi di configurazione per Traefik e Graphana-Alloy:
  #link("https://github.com/ChristianLempa/boilerplates")

== Altri software e progetti
- Documentazione `cloud-init` e creazione template:
  - #link("https://cloud-init.io/")
  - #link("https://technotim.live/posts/cloud-init-cloud-image/")
- Repositori di `just`: #link("https://github.com/casey/just")
- Nix:
  - Documentazione ufficiale: #link("https://nix.dev/")
  - Repositori del modulo `direnv`: #link(
      "https://github.com/nix-community/nix-direnv",
    )
  - Repositori del modulo `git-hooks`: #link(
      "https://github.com/cachix/git-hooks.nix",
    )
- Typst: #link("https://typst.app/docs/")
