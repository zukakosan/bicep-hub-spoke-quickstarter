param location string = resourceGroup().location

@minValue(1)
@maxValue(20)
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

module createVnets './modules/vnet.bicep' = {
  name: 'createVnets'
  params:{
    location: location
    spokeCount: spokeCount
    azfwEnabled: azfwEnabled
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}

module createAzfw './modules/azfw.bicep' = if(azfwDeploy){
  name: 'createAzfw'
  params:{
    location: location
    azfwName: azfwName
  }
  dependsOn:[
    createVnets
  ]
}

