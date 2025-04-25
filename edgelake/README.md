# EdgeLake Service for  OpenHorizon

EdgeLake is a decentralized network to manage IoT/Edges data. Nodes are compute instances that execute the EdgeLake 
Software and that are part of a nodes network.

The EdgeLake network is using one MASTER Node (is has all the network meta data), as many OPERATOR nodes as required (this is where the data is) and at least one QUERY node (this is where a query for the data is made, nodes can be dual role Query+Operator). The Query node is where the end-user (human or application, Grafana to build a dashboard for example) queries data, it knows from the meta data which Operators to goto and does it peer to peer.

note: the Master node can also be replaced by a Blockchain service & contract : we will not cover this below for the time being

Adding EdgeLake to Open Horizon implementations extends OH value it allows :
- collection of nodes health simply
- extending data queried to other sensors: data usefull to the user (machine rpms for example)


In a typical Open Horizon deployment here are the main elements: 
<img width="1118" alt="image" src="https://github.com/user-attachments/assets/7e1d9264-2ace-4450-ab5a-f1c97f5e7211">


Adding EdgeLake to an existing Open Horizon deployment, the simplest pattern is to locate the Master and Query nodes together 'centrally' with the OH Managenent Hub as below:
<img width="1149" alt="image" src="https://github.com/user-attachments/assets/308e51d6-73ac-46c2-b3e7-9f1fc8df28a6">

A more practical approach is to have the Query node (at least one) elsewhere as below (avoiding to move
data to the Management Hub : Peer to Peer collection), and one can have as many Query nodes as needed:
<img width="1159" alt="image" src="https://github.com/user-attachments/assets/d9ff937f-09fb-4309-96f2-f11241aaea21">


For demonstrating and testing on a single system we created deployment tools:
- 2x .sh for the Management side (deploy Master, deploy Query)
- 1x .sh for the Agent side (deploy Operator during Edge build and initial Agent installation)
- 1x 1 Service Policy for Operator at Edge (deploy Operator into an already deployed Edge using the Horizon deployment tool)

Here is the simplified diagram when deploying on a single physical system: 
<img width="1159" alt="image" src="https://github.com/user-attachments/assets/761645ad-3af5-49e2-bdf0-c6a3b6f21815">



Back to deployment, with the instructions below you will be able to deploy an integrated OH+EL setup to run a simple dashboard.
Creating a nodes network requires the following steps:
1. Install the EdgeLake Software on one or more computer instances.
2. Configure each installed node (compute instance) such that:
   1. The node joins an exiting network (or creates a new network).
   2. The node offers data management and monitoring services.  



## Table of Content
* [Install OpenHorizon](Documentation%2FInstall_Local_OpenHorizon.md)
* [Deploy EdgeLake](deploy_edgelake_service.md)
* [EdgeLake KubeArmor Integration](Documentation/EdgeLake_KubeArmor_integration.md) - Accepting KubeArmor data into EdgeLake
* [Import Grafana Dashboards](Documentation/Import_Grafana_Dashboards.md) - Importing KubeArmor related gauges into Grafana 


## 📌 Our valuable contributors👩‍💻👨‍💻

<table>
  <tr>
    <a href="https://github.com/open-horizon-services/service-edgelake/graphs/contributors">
      <img src="https://contrib.rocks/image?repo=open-horizon-services/service-edgelake" />
    </a>
  </tr>
</table>




