# pcls

# Use Case

> Jitsi in der Cloud.
- https://aws.amazon.com/blogs/opensource/getting-started-with-jitsi-an-open-source-web-conferencing-solution/ und https://github.com/jitsi/docker-jitsi-meet

## Komponente

Das ganze wird via Terraform auf AWS (Amazon Web Services) deployt und folgende Kompontenten werden verwendet.

### Access Management
- Computing via ECS
- Loadbalancer / Autoscaling Groups
- Monitoring
- DNS/Domain via Route53
- Certifcate Manager

# Vorgaben

1. Wählen Sie einen geeigneten Use Case für die Umsetzung in der AWS Cloud, der alle folgenden Eigenschaften erfüllt:
   - Einsatz von mindestens fünf verschiedenen AWS-Services: ✅
   - Service muss über das Internet erreichbar sein: ✅

2. Erstellen Sie eine geeignete Architektur für die Implementation des oben definierten Services in der AWS-Cloud unter Berücksichtigung der folgenden Eigenschaften:
   - Tiefe Kosten (Pay-As-You-Go betreffend der verwendeten Services)
   - Hohe Skalierbarkeit (Service kann einfach durch das Hinzufügen von Ressourcen skaliert werden)
   - Hochverfügbarkeit (Ausfall eines Services oder einer Komponente hat keinen Impact)

3. Implementieren Sie die Services gemäss ihrer gewählten Architektur:
   - Verwenden Sie Scripte / IaC, wo sinnvoll/möglich
   - Dokumentieren Sie klar die Implementierung, wo IaC nicht sinnvoll/möglich
   - Verwenden Sie ein Sourcecode-Management und Automatismen sofern möglich
   - Alle Artifakte dieses Schrittes müssen im Sourcecode-Management sein (ja: auch die Dokumentation zum Erstellen wo IaC nicht sinnvoll/möglich ist)

4. Fertigen Sie einen Technischen Bericht an:
   - 10-15 Seiten
   - Beschreibung des Use Cases
   - Beschreibung der Architektur: Welche architektonischen Prinzipien haben Sie berücksichtigt? Warum haben Sie Entscheiden so getroffen, wie Sie sie getroffen habe und nicht anders?
   - Beschreibung der Implementierung: Wie haben Sie was umgesetzt und warum?

5. Stellen Sie Ihren Use Case in der Veranstaltung vor:
   - Zeitrahmen: 10min + 5min Fragen pro Gruppe
   - Sourcecode und Demo > PPT

## Lieferobjekte
- Sourcecode / Dokumentation zum Aufsetzen des Services (README)
- Technischer Bericht
- Vorstellung der laufenden Implementierung im Plenum

### Beispielstruktur des Berichts
- Beschreibung Use Case
- Gewählte Architektur inkl. evt. Alternativen
- Verargumentieren der Entscheidung anhand der gelernten Prinzipien
- Vorgehensweise für Umsetzung
- Beschreibung der Implementation inklusive Configs
- Erkenntnisse
- Fazit

### Die folgenden Punkte werden bewertet:
- Gewählten Servicearchitektur betreffend Kosten, Skalierbarkeit und hohe Verfügbarkeit
- Qualität der Implementierung
- Qualität und Struktur des Berichtes
- Es gibt ein Excel-Sheet mit einem Benotungsschema

# Other Resources

- https://github.com/hpi-schul-cloud/jitsi-deployment/blob/master/docs/architecture/architecture.md
- AWS CloudFormation Template for Jitsi: https://github.com/chris-armstrong/jitsi-meet-cfn
- Infrastructure as Code: Deploy Jitsi Meet to AWS: https://github.com/AvasDream/terraform_aws_jitsi_meet/tree/master and https://avasdream.engineer/terraform-jitsi
- EC2 setup with Terraform: https://napo.io/posts/jitsi-on-aws-with-terraform/ und https://github.com/hajowieland/terraform-aws-jitsi/tree/master
- EC2 setup with Terraform: https://github.com/AppGambitStudio/terraform-jisti-aws-ecs
- docker setup unstable: https://github.com/jitsi/docker-jitsi-meet/issues/1320
- https://community.jitsi.org/t/scalling-jitsi-meet-with-ec2-autoscaling-group-and-elb/71109
- Good Terraform Tutorial: https://www.architect.io/blog/2021-03-30/create-and-manage-an-aws-ecs-cluster-with-terraform/
- Terraform IAM Policies: https://developer.hashicorp.com/terraform/tutorials/aws/aws-iam-policy

## TaskDefinitions

aws ecs task definition multiple containers:
- https://github.com/aws-samples/aws-containers-task-definitions
- https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html
- https://docs.aws.amazon.com/AmazonECS/latest/developerguide/example_task_definitions.html
- https://stackoverflow.com/questions/58196930/communication-between-containers-in-ecs-task-definition
- https://stackoverflow.com/questions/53145233/aws-ecs-start-multiple-containers-in-one-task-definition#53168127
