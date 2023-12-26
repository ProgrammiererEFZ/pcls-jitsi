pcls
====

# Use Case

> Jitsi in der Cloud.
- https://aws.amazon.com/blogs/opensource/getting-started-with-jitsi-an-open-source-web-conferencing-solution/

## Komponente

Das ganze wird auf AWS (Amazon Web Services) deployt und folgende Kompontenten werden verwendet.

(- IAM)
### Access Management

- Computing
- Datenbank
- Storage
- Loadbalancer
- Monitoring

# Vorgaben

1. Wählen Sie einen geeigneten Use Case für die Umsetzung in der AWS Cloud, der alle folgenden Eigenschaften erfüllt:
    • Einsatz von mindestens fünf verschiedenen AWS-Services: ✅
    • Service muss über das Internet erreichbar sein: ✅

2. Erstellen Sie eine geeignete Architektur für die Implementation des oben definierten Services in der AWS-Cloud unter Berücksichtigung der folgenden Eigenschaften:
    • Tiefe Kosten (Pay-As-You-Go betreffend der verwendeten Services)
    • Hohe Skalierbarkeit (Service kann einfach durch das Hinzufügen von Ressourcen skaliert werden)
    • Hochverfügbarkeit (Ausfall eines Services oder einer Komponente hat keinen Impact)

3. Implementieren Sie die Services gemäss ihrer gewählten Architektur:
    • Verwenden Sie Scripte / IaC, wo sinnvoll/möglich
    • Dokumentieren Sie klar die Implementierung, wo IaC nicht sinnvoll/möglich
    • Verwenden Sie ein Sourcecode-Management und Automatismen sofern möglich
    • Alle Artifakte dieses Schrittes müssen im Sourcecode-Management sein (ja: auch die Dokumentation zum Erstellen wo IaC nicht sinnvoll/möglich ist)

4.  Fertigen Sie einen Technischen Bericht an:
    • 10-15 Seiten
    • Beschreibung des Use Cases
    • Beschreibung der Architektur: Welche architektonischen Prinzipien haben Sie berücksichtigt? Warum haben Sie Entscheiden so getroffen, wie Sie sie getroffen habe und nicht anders?
    • Beschreibung der Implementierung: Wie haben Sie was umgesetzt und warum?

5. Stellen Sie Ihren Use Case in der Veranstaltung vor:
    • Zeitrahmen: 10min + 5min Fragen pro Gruppe 
    • Sourcecode und Demo > PPT

Lieferobjekte
    • Sourcecode / Dokumentation zum Aufsetzen des Services (README)
    • Technischer Bericht
    • Vorstellung der laufenden Implementierung im Plenum

Beispielstruktur, Bericht
    • Beschreibung Use Case
    • Gewählte Architektur inkl. evt. Alternativen
    • Verargumentieren der Entscheidung anhand der gelernten Prinzipien
    • Vorgehensweise für Umsetzung
    • Beschreibung der Implementation inklusive Configs
    • Erkenntnisse
    • Fazit

Die folgenden Punkte werden bewertet:
    • Gewählten Servicearchitektur betreffend Kosten, Skalierbarkeit und hohe Verfügbarkeit
    • Qualität der Implementierung
    • Qualität und Struktur des Berichtes
    • Es gibt ein Excel-Sheet mit einem Benotungsschema