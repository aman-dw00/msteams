## **🎙️Introduction**

This document provides a **step-by-step guide** to deploy a full-fledged observability stack using Helm charts and Jenkins pipelines. Each observability component is packaged in a Helm chart, and its deployment is automated using Jenkins .


---

## **💼 Prerequisites**

Before starting the deployment, make sure the following requirements are fulfilled:

###  😀Access

* GitHub access to: [o11y-k8s-setup-template](https://github.com/ot-client/o11y-k8s-setup-template.git) repo.
* [Jenkins](https://jenkins.opstree.dev/) access to trigger jobs.
* Access to target Kubernetes cluster.

### 🛠️Tools installed 

* Helm v3 installed on Jenkins agent .
* kubectl configured .


---

## **🗂️ Repo Structure** 

```javascript
o11y-k8s-setup-template/
├── Blackbox_exporter/           # Helm chart for Blackbox Exporter
├── Endpoints/                   # Helm chart for Endpoint configs for Blackbox
├── alertmanager/                # Alertmanager components
│   ├── alerting_rules/          # Helm chart for alert rules
│   └── alertmanager_setup/      # Helm chart for Alertmanager
├── grafana/                     # Grafana components
│   ├── grafana_dashboard/       # Helm chart for Dashboards JSON & folder provisioning
│   ├── grafana_datasource/      # Helm chart for Datasource provisioning
│   └── grafana_setup/           # Base Grafana Helm chart setup
├── jenkins/                     # Jenkinsfiles & job DSL configs
├── loki/                        # Helm chart for Loki 
├── otel/                        # OpenTelemetry components
│   ├── otel-collector/          # Helm chart for OTel Collector
│   └── otel-operator/           # Helm chart for OTel Operator
├── tempo/                       # Helm chart for Tempo 
└── victoria_metrics/            # Helm chart for VictoriaMetrics 
```


---

## 🔄 **General Process for All Components**


1. Each component has its **own Helm chart** with a values.yaml file.
2. A matching \[component\]-[Jenkinsfile](https://github.com/ot-client/o11y-k8s-setup-template/tree/main/jenkins) automates the Helm deployment.
3. You customize via values.yaml, trigger Jenkins job, and Helm does the deployment.

> ✅ **You can change values (like resources, node selectors, etc.) in values.yaml before triggering Jenkins job**. **The changes should be make in a separate branch commit your changes in that branch and raise PR.** 


---

# 🔨Procedure


* Trigger the [JobDSL](https://jenkins.opstree.dev/job/COE/job/Observability/job/JobDSL/) .It will creates jobs automatically in a folder name **O11y_Setup**  on path COE>Observability, but it **requires approval** in Jenkins:

  > 📍 Manage Jenkins → In-process Script Approval → Approve jobdsl.groovy scripts

  **⚠️ Without approval, jobs won't get created and automation will fail.**

  

## ✅ **1. VictoriaMetrics Deployment**

### Purpose

VictoriaMetrics is a fast, cost-saving, and scalable solution for **monitoring and managing time series data**

###  Chart Path:

[VictoriaMetrics](https://github.com/ot-client/o11y-k8s-setup-template/tree/main/victoria_metrics)

###  Deployment Steps:


1. Open [Jenkins](https://jenkins.opstree.dev/job/COE/job/Observability/) and trigger the job: VictoriaMetrics . 
2. This job performs the following steps:
   * **Updates Helm Dependencies** to ensure all required charts are available locally.
   * **Deploys or Upgrades** the Helm release using the helm upgrade --install command to apply the chart on the Kubernetes cluster.
3. Verify the pods in the kubernetes cluster :

   ```javascript
   kubectl get pods -n monitoring | grep vm
   ```


---

## ✅ **2. Loki Deployment**

###  Purpose

Loki is a log aggregation system designed to work with Fluentbit .

###  Chart Path:

[loki](https://github.com/ot-client/o11y-k8s-setup-template/tree/main/loki)

### Steps:


1. Trigger the Jenkins job: Loki
2. This job performs the following steps:
   * **Updates Helm Dependencies** to ensure all required charts are available locally.
   * **Deploys or Upgrades** the Helm release using the helm upgrade --install command to apply the chart on the Kubernetes cluster.
3. Verify the pods in the kubernetes cluster :

   ```javascript
   kubectl get pods -n logging | grep loki
   ```

   


---

## ✅ **3. Tempo Deployment**

###  Purpose

Tempo is a distributed tracing backend. It collects traces from applications using OpenTelemetry.

###  Chart Path:

[tempo](https://github.com/ot-client/o11y-k8s-setup-template/tree/main/tempo)

##  Steps:


1. Trigger the Jenkins job: tempo
2. This job performs the following steps:
   * **Updates Helm Dependencies** to ensure all required charts are available locally.
   * **Deploys or Upgrades** the Helm release using the helm upgrade --install command to apply the chart on the Kubernetes cluster.
3. Verify the pods in the kubernetes cluster :

   ```javascript
   kubectl get pods -n observability | grep tempo
   ```

   


---

## ✅ **4. OpenTelemetry Operator**

###  Purpose

The OTel Operator manages OpenTelemetryCollector .

###  Chart Path:

[otel-operator](https://github.com/ot-client/o11y-k8s-setup-template/tree/main/otel/otel-operator)

###  Steps:


1. Trigger job: otel-opertor
2. Confirm operator pod is running in the cluster:

   ```javascript
   kubectl get pods -n observability | grep operator
   ```

   


---

## ✅ **5. OpenTelemetry Collector**

###  Purpose

Collector ingests telemetry data (metrics, logs, traces) and routes it to appropriate backends (tempo).

###  Chart Path:

[otel-collector](https://github.com/ot-client/o11y-k8s-setup-template/tree/main/otel/otel-collector)

###  Steps:


1. Trigger job: otel-collector
2. Validate that otel-collector pod is running 

   ```javascript
   kubectl get pods -n observability | grep collector
   ```


---

## ✅ **6. Alertmanager**

###  Purpose

Alertmanager handles alert delivery (email, Slack, Teams).Configure receivers in values.yaml.

###  Chart Path:

[alertmanager](https://github.com/ot-client/o11y-k8s-setup-template/tree/main/alertmanager/alertmanager_setup)

###  Steps:


1. Trigger job: alertmanager
2. Confirm pod in the cluster :

   ```javascript
   kubectl get pods -n monitoring | grep alertmanager
   ```

   


---

## ✅ **7. Alerting Rules**

###  Purpose

This chart manages alerting rules sent to Alertmanager. You can add alerts if required in the helm chart.

###  Chart Path:

[alerting-rules](https://github.com/ot-client/o11y-k8s-setup-template/tree/main/alertmanager/alerting_rules)

###  **Steps:**


1. Trigger job: alerting_rules
2. Confirm rules loaded 

   ```javascript
   kubectl get vmrules -n monitoring
   ```


---

## ✅ **8. Grafana**

###  Purpose

Grafana is the central dashboarding tool.

###  Chart Path:

[grafana](https://github.com/ot-client/o11y-k8s-setup-template/tree/main/grafana/grafana_setup)

###  Steps:


1. Trigger job: grafana
2. Ingress is also created via this helm chart. Open a Browser and hit 

   ```javascript
   grafana.k8s.opstree.dev
   ```

3\.Grafana user is **admin** and you can get grafana password from secrets:

```javascript
kubectl get secrets grafana -n monitoring -o yaml
```

The password will be in base64 encoded , decode the password  open [decode](https://www.base64decode.org/) site on browser and login with the user and password on grafana.


4\.To edit the grafana password if required with below command:

```javascript
kubectl edit secret grafana -n monitoring -o yaml 
```

Convert your required password in base64encoded form and add in the yaml.


---


## ✅ **9. Grafana Datasource**

###  Purpose

Configures datasources (VictoriaMetrics, Loki, Tempo, alertmanager).

###  Chart Path:

[grafana-datasource](https://github.com/ot-client/o11y-k8s-setup-template/tree/main/grafana/grafana_datasource)

### Steps:


1. Trigger job: Grafana_datasource.
2. Login to Grafana UI → Check under “Settings > Data Sources”


---

## ✅ **10. Grafana Folders + Dashboards**

###  Purpose

Creates folders and organizes dashboards into them.

###  Chart Paths:

* [grafana-dashboard](https://github.com/ot-client/o11y-k8s-setup-template/tree/main/grafana/grafana_dashboard)

###  Steps:


1. Trigger the jobs : Grafana_dashboard
2. Folders structure and dashboards are created as per the structure  you have given in the github [dashboard](https://github.com/ot-client/o11y-k8s-setup-template/tree/main/grafana/grafana_dashboard/dashboards/Opstree) folder. If wants to add new dashboards or folder  add it on the github on the same path and run the jenkins job.
3. Login to Grafana and validate


---

## ✅ **11. Blackbox Exporter**

###  Purpose

Performs endpoint availability checks using  HTTP, TCP probes.

###  Chart Path:

[Blackbox](https://github.com/ot-client/o11y-k8s-setup-template/tree/main/Blackbox_exporter)

###  Steps:


1. Trigger Jenkins job: Blackbox
2. Check inside the cluster :

   ```javascript
   kubectl get pods -n monitoring | grep blackbox
   ```


---

## ✅ **12. Blackbox Endpoints**

###  Purpose

Defines probe targets (websites etc.)

###  Chart Path:

[Endpoints](https://github.com/ot-client/o11y-k8s-setup-template/tree/main/Endpoints)

###  Steps:


1. Trigger Jenkins job: Endpoint
2. This creates a VMStaticScrape  for probe targets you can validate it by 

```javascript
kubectl get VMStaticScrape <vmstaticscrape_name> -n monitoring -o yaml 
```


3. You can also validate it on grafana UI there will be  a dashbord name blackbox in that dashboard validate your endpoints .


---

## ✅ Final Validation Checklist

|     Component | Validation Command |
|----|----|
| VictoriaMetrics | `kubectl get pods -n monitoring` |
| Loki  | `kubectl get pods -n logging` |
| Tempo | `kubectl get pods -n observability` |
| OTel Operator | `kubectl get pods -n observability` |
| Alertmanager | `kubectl get pods -n monitoring` |
| Grafana | Open Grafana UI |
| Dashboards | Check folders & dashboards in UI |
| Datasources | Check under Settings → Data Sources |
| Blackbox Exporter | `kubectl get pods -n monitoring` |
| Endpoints | `Kubectl get vmstaticscrape -n monitoring` |
| Alerting Rules | `kubectl get vmrules  -n monitoring` |


Also, validate that the required **metrics**, **logs**, and **traces** are available in **Grafana Explore** by selecting the appropriate **data source**.


---

## ✅ Troubleshooting

* Try to Run Jobs in the same Sequence as given above. or if required you can run victoriametrics, tempo , loki , otel-operator, otel-collector, grafana  in parallel then run the remaining jobs alertmanager, alertingrules, blackbox exporter, endpoint, datasource, dashboards.


* If a job got failed Check console output of that job.
* While job in running phase enter in the cluster check the pods if they are created. If some pods in crashloop , pending state investigate  the pod and take the required actions.

  ```javascript
  Kubectl describe po <pod_name> -n <namespace>
  ```
* If required check the logs : 

  ```javascript
  kubectl logs <pod_name> -n <namespace>
  ```
* While making changes to the values.yaml file, ensure that the **indentation is correct**, as improper indentation can lead to Helm deployment failures.


🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸
