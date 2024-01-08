# pcls Case Study

Case Study für das Modul "pcls" an der FHNW. Durchgeführt von Julie Engel (engelju) und Luca Plozner (ProgrammiererEFZ).

## Use Case

Jitsi Videoconferencing in AWS.

## Komponente

Das ganze wird auf AWS (Amazon Web Services) deployt und folgende Komponente werden verwendet:

- Access Management mit IAM
- Computing mit EC2
- Loadbalancer mit ELB
- Autoscaling Groups mit ASG
- Certificate mit ACM
- Monitoring mit SNS und CloudWatch

## Installation

Die Installation setzt voraus, dass folgende Tools installiert sind:
- `awscli`
- `jq`

Ebenfalls müssen vorgängig folgende Schritte ausgeführt werden:
- Domain Name im File `resources/jitsi_setup.sh` anpassen
- Manuelles erstellen, signieren und importieren (in ACM) des SSL-Zertifikates in ACM und anpassen des Domainnamens im File `02_create_loadbalancer.sh`

Anschliessend können die Skripte `00_create_iam.sh`, `01_create_instances.sh`, `'02_create_load_balancer.sh` sowie `03_create_monitoring.sh` nacheinander ausgeführt werden. 

Das Skript `00_create_iam.sh` erstellt den User und die Policy für die Installation und generiert ein EC2 Keypair (und speichert dies in ein neues Verzeichnis "/output") und das Skript `01_create_instances.sh` erstellt anschliessend das Setup für benötigten EC2-Instanzen und fährt sie hoch. Das Skript `02_create_load_balancer.sh` erstellt den Loadbalancer und das Skript `03_create_monitoring.sh` erstellt die Monitoring-Alarme.

Abschliessend muss noch der DNS CNAME manuell beim Provider angepasst werden.

# Vorgaben

1. Wählen Sie einen geeigneten Use Case für die Umsetzung in der AWS Cloud, der alle folgenden Eigenschaften erfüllt:
   - ✅ Einsatz von mindestens fünf verschiedenen AWS-Services: IAM, EC2, ELB, ASG, ACM, SNS/CloudWatch
   - ✅ Service muss über das Internet erreichbar sein: meet.rotzlöffel.ch

2. Erstellen Sie eine geeignete Architektur für die Implementation des oben definierten Services in der AWS-Cloud unter Berücksichtigung der folgenden Eigenschaften:
   - ❓ Tiefe Kosten (Pay-As-You-Go betreffend der verwendeten Services)
   - ❓ Hohe Skalierbarkeit (Service kann einfach durch das Hinzufügen von Ressourcen skaliert werden)
     - ❓ Man muss Instanztyp im 01_create_instances.sh Skript anpassen
   - ✅ Hochverfügbarkeit (Ausfall eines Services oder einer Komponente hat keinen Impact)

3. Implementieren Sie die Services gemäss ihrer gewählten Architektur:
   - ✅ Verwenden Sie Scripte / IaC, wo sinnvoll/möglich
   - ✅ Dokumentieren Sie klar die Implementierung, wo IaC nicht sinnvoll/möglich
   - ✅ Verwenden Sie ein Sourcecode-Management und Automatismen sofern möglich
   - ✅ Alle Artifakte dieses Schrittes müssen im Sourcecode-Management sein (ja: auch die Dokumentation zum Erstellen wo IaC nicht sinnvoll/möglich ist)

4. Fertigen Sie einen Technischen Bericht an:
   - ✅ Beschreibung des Use Cases
   - ✅ Beschreibung der Architektur: Welche architektonischen Prinzipien haben Sie berücksichtigt? Warum haben Sie Entscheiden so getroffen, wie Sie sie getroffen habe und nicht anders?
   - ✅ Beschreibung der Implementierung: Wie haben Sie was umgesetzt und warum?
   - ✅ 10-15 Seiten

5. TODO: Stellen Sie Ihren Use Case in der Veranstaltung vor:
   - Zeitrahmen: 10min + 5min Fragen pro Gruppe
   - Sourcecode und Demo > PPT

## Lieferobjekte
- ✅ Technischer Bericht
- ✅ Sourcecode / Dokumentation zum Aufsetzen des Services (README)
- TODO: Vorstellung der laufenden Implementierung im Plenum

### Beispielstruktur des technischen Berichts
- ✅ Beschreibung Use Case
- ✅ Gewählte Architektur inkl. evt. Alternativen
- ✅ Verargumentieren der Entscheidung anhand der gelernten Prinzipien
- ✅ Vorgehensweise für Umsetzung
- ✅ Beschreibung der Implementation inklusive Configs
- TODO: Erkenntnisse und Fazit

### Die folgenden Punkte werden bewertet:
- Gewählten Servicearchitektur betreffend Kosten, Skalierbarkeit und hohe Verfügbarkeit
- Qualität der Implementierung
- Qualität und Struktur des Berichtes
- Es gibt ein Excel-Sheet mit einem Benotungsschema

