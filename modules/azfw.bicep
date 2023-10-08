param location string
param azfwName string

@description('The IP address to which the firewall will translate the destination address of the incoming packet. This should be the private IP address of the VM to which you want to allow SSH access.')
param dnatAddress string = '10.10.0.4'

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

resource networkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-01-01' = {
  parent: firewallPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        name: 'east-west-rule'
        priority: 1250
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'vnet-to-vnet'
            ipProtocols: [
              'Any'
            ]
            destinationAddresses: [
              '10.0.0.0/8'
            ]
            destinationPorts: [
              '*'
            ]
            sourceAddresses: [
              '10.0.0.0/8'
            ]
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyNatRuleCollection'
        action: {
          type: 'Dnat'
        }
        name: 'dnat-rule'
        priority: 1000
        rules:[
          {
            ruleType: 'NatRule'
            name: 'ssh-dnat-rule'
            destinationAddresses: [
              azfwPip.properties.ipAddress
            ]
            destinationPorts: [
              '50000'
            ]
            ipProtocols: [
              'Any'
            ]
            sourceAddresses: [
              '*'
            ]
            translatedAddress: dnatAddress
            translatedPort: '22'
          }
        ]
      }
    ]
  }
}

resource azureFirewall 'Microsoft.Network/azureFirewalls@2023-04-01' = {
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

output azfwPrivateIp string = azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress
