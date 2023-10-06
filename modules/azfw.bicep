param location string
param azfwName string

// @minValue(1)
// @maxValue(100)
// param numberOfPublicIPAddresses int = 2

resource azfwSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  name: 'vnet-hub/AzureFirewallSubnet'
}

resource azfwPip 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'azfw-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-04-01' = {
  name: '${azfwName}-policy'
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
    dnsSettings: {
      enableProxy: true
    }
    threatIntelMode: 'Alert'
  }
}


resource firewall 'Microsoft.Network/azureFirewalls@2023-04-01' = {
  name: azfwName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }    
    firewallPolicy: {
      id: firewallPolicy.id
    }
    ipConfigurations: [ 
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: azfwSubnet.id
          }
          publicIPAddress: {
            id: azfwPip.id
          }
        }
      }
    ]
  }
}
