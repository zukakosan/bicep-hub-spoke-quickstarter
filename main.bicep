@description('Azure location to deploy resources')
param location string = resourceGroup().location

@description('Number of spoke vnets to create')
@minValue(1)
@maxValue(10)
param spokeCount int = 2 

@description('Admin username for all VMs')
param adminUsername string
@description('Admin password for all VMs')
@secure()
param adminPassword string

@description('Azure Bastion should be enabled or disabled')
@allowed([
  'Enabled'
  'Disabled'
])
param bastionEnabled string 

@description('Azure Firewall name deployed in hub vnet')
var azfwName = 'azfw-hub'

@description('Boolean variable if Azure Bastion should be deployed')
var deployAzureBastion = bastionEnabled == 'Enabled'

// create hub vnet that contains azure firewall, jumpbox, azure bastion(if needed)
module createHubVnet './modules/hubVnet.bicep' = {
  name: 'createHubVnet'
  params:{
    location: location
    azfwName: azfwName
    adminUsername: adminUsername
    adminPassword: adminPassword
    deployAzureBastion: deployAzureBastion
  }
}

// create spoke vnets for N-times defined by parameters
module createSpokeVnets './modules/spokeVnet.bicep' = [for i in range(1, spokeCount): {
  name: 'createSpokeVnet-${i}'
  params: {
    location: location
    index: i
    adminUsername: adminUsername
    adminPassword: adminPassword
    azfwName: azfwName // put azure firewall name to create user defined routes of [0.0.0.0/0 to azure firewall]
  }
  dependsOn:[
    createHubVnet // create spoke vnet after hub vnet because of vnet peering, user defined route
  ]
}]
