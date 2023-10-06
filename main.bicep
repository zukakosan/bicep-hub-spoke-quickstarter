param location string = resourceGroup().location

@minValue(1)
@maxValue(20)
param spokeCount int = 2

@allowed([
  'Enabled'
  'Disabled'
])
param azfwEnabled string = 'Enabled'
param azfwName string = take('azfw-${uniqueString(resourceGroup().id)}', 8)

var azfwDeploy = azfwEnabled == 'Enabled'

module createVnets './modules/vnet.bicep' = {
  name: 'createVnets'
  params:{
    location: location
    spokeCount: spokeCount
    azfwEnabled: azfwEnabled
  }
}
module createAzfw './modules/azfw.bicep' = if(azfwDeploy){
  name: 'createAzfw'
  params:{
    location: location
    azfwName: azfwName
  }
}
