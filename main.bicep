param location string = resourceGroup().location

@minValue(1)
@maxValue(10)
param spokeCount int = 3

@allowed([
  'Enabled'
  'Disabled'
])
param azfwEnabled string 
param azfwName string = take('azfw-${uniqueString(resourceGroup().id)})}',9)

param adminUsername string
@secure()
param adminPassword string

// @allowed([
//   'Enabled'
//   'Disabled'
// ])
// param azfwNatgwEnabled string 

var azfwDeploy = azfwEnabled == 'Enabled'
// var azfwNatgwDeploy = azfwNatgwEnabled == 'Enabled'

module createHubVnet './modules/hubVnet.bicep' = {
  name: 'createHubVnets'
  params:{
    location: location
    azfwEnabled: azfwEnabled
    azfwName: azfwName
  }
}


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


// ここでDNATルールを作成する
// Spokeの何らかのVMに対して、DNATルールを作成する
