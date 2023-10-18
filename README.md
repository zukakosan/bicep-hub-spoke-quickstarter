# bicep-hub-spoke-quickstarter
This repository can be used for quickly deployment of Hub-VNet and some Spoke-VNets with Azure Firewall. 

## Architecture
The overall architecture is like bellow. Optionally, you can deploy Azure Bastion as well for administration althogh DNAT Rule on Azure Firewall to use jumpbox VM is set by default. Azure Firewall has allow Network Rule for east-west connection but this rule definition is wider, so please restrict ranges in more detail. VMs can communicate each other by route table attached to each subnet including user-defined route(`0.0.0.0/0 > VirtualAppliance`).
![](/imgs/hubspoke-architecture.png)
 
# Lisence
This project is licensed under the MIT License, see the LICENSE.txt file for details.
