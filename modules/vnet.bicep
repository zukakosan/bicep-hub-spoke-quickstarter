param location string
param spokeCount int
param azfwEnabled string

var azfwDeploy = azfwEnabled == 'Enabled'

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-hub'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-001'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'subnet-002'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

resource createAzfwSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = if(azfwDeploy) {
  name: 'AzureFirewallSubnet'
  parent: hubVnet
  properties: {
    addressPrefix: '10.0.2.0/24'
  }
}

resource spokeVNetLoop 'Microsoft.Network/virtualNetworks@2023-05-01' = [for i in range(1, spokeCount+1): {
  name: 'vnet-spoke-${i}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.${i}0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-001'
        properties: {
          addressPrefix: '10.${i}0.0.0/24'
        }
      }
      {
        name: 'subnet-002'
        properties: {
          addressPrefix: '10.${i}0.1.0/24'
        }
      }
    ]
  }
}]
