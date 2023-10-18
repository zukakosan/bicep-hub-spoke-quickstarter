param location string
param azfwName string
// param deployDnatVm string

@description('The IP address to which the firewall will translate the destination address of the incoming packet. This should be the private IP address of the VM to which you want to allow SSH access.')
param dnatAddress string

resource azfwSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  name: 'vnet-hub/AzureFirewallSubnet'
}

// create public ip address for azure firewall
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

// create firewall policy
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

// create dnat rule collection group on firewall policy
// this rule collection group will be used to translate the destination address of the incoming packet
// rule description: ssh traffic from internet to the firewall public ip address is translated to the private ip address of the vm
resource dnatRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-04-01' = {
  parent: firewallPolicy
  name: 'DefaultDnatRuleCollectionGroup'
  properties: {
    priority: 100
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyNatRuleCollection'
        action: {
          type: 'DNAT'
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

// after creating the dnat rule collection group, create the network rule collection group
// these creating two rule collection groups cannot be parallelized
// rule description: east west traffic between the vnets is allowed
resource networkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-04-01' = {
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
    ]
  }
  dependsOn: [
    dnatRuleCollectionGroup
  ]
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
  dependsOn: [
    networkRuleCollectionGroup
  ]
}

output azfwPrivateIp string = azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress
