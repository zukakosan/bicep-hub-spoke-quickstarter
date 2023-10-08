param location string = resourceGroup().location

@minValue(1)
@maxValue(10)
param spokeCount int = 2

// @allowed([
//   'Enabled'
//   'Disabled'
// ])
// param azfwEnabled string 
param azfwName string = take('azfw-${uniqueString(resourceGroup().id)})}',9)

param adminUsername string
@secure()
param adminPassword string

// @allowed([
//   'Enabled'
//   'Disabled'
// ])
// param azfwNatgwEnabled string 

// var azfwDeploy = azfwEnabled == 'Enabled'
// var azfwNatgwDeploy = azfwNatgwEnabled == 'Enabled'

module createHubVnet './modules/hubVnet.bicep' = {
  name: 'createHubVnets'
  params:{
    location: location
    // azfwDeploy: azfwDeploy
    azfwName: azfwName
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}

module createSpokeVnets './modules/spokeVnet.bicep' = [for i in range(1, spokeCount): {
  name: 'spokeVnet-${i}'
  params: {
    location: location
    index: i
    adminUsername: adminUsername
    adminPassword: adminPassword
    // azfwDeploy: azfwDeploy
    azfwName: azfwName
  }
  dependsOn:[
    createHubVnet
  ]
}]
