param location string = resourceGroup().location

@minValue(1)
@maxValue(10)
param spokeCount int = 2 

param adminUsername string
@secure()
param adminPassword string

@allowed([
  'Enabled'
  'Disabled'
])
param bastionEnabled string 

var azfwName = take('azfw-${uniqueString(resourceGroup().id)})}',9)
var deployAzureBastion = bastionEnabled == 'Enabled'

// create hub vnet 
// deploy azure bastion if needed
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
  name: 'spokeVnet-${i}'
  params: {
    location: location
    index: i
    adminUsername: adminUsername
    adminPassword: adminPassword
    azfwName: azfwName
  }
  dependsOn:[
    createHubVnet
  ]
}]
