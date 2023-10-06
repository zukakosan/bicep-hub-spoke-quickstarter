param location string
// param spokeCount int
param index int
param adminUsername string
@secure()
param adminPassword string
param azfwName string

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: 'vnet-hub'
}
resource azureFirewall 'Microsoft.Network/azureFirewalls@2023-04-01' existing = {
  name: azfwName
}

resource nsgDefault 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-spoke-${index}'
  location: location
  properties: {
    // securityRules: [
    //   {
    //     name: 'nsgRule'
    //     properties: {
    //       description: 'description'
    //       protocol: 'Tcp'
    //       sourcePortRange: '*'
    //       destinationPortRange: '*'
    //       sourceAddressPrefix: '*'
    //       destinationAddressPrefix: '*'
    //       access: 'Allow'
    //       priority: 100
    //       direction: 'Inbound'
    //     }
    //   }
    // ]
  }
}

resource routeTable 'Microsoft.Network/routeTables@2019-11-01' = {
  name: 'rt-spoke-${index}'
  location: location
  properties: {
    routes: [
      {
        name: 'defaultRoute'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
    disableBgpRoutePropagation: true
  }
}


resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'vnet-spoke-${index}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.${index}0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-001'
        properties: {
          addressPrefix: '10.${index}0.0.0/24'
          networkSecurityGroup: {
            id: nsgDefault.id
          }
        }
      }
      {
        name: 'subnet-002'
        properties: {
          addressPrefix: '10.${index}0.1.0/24'
          networkSecurityGroup: {
            id: nsgDefault.id
          }
        }
      }
    ]
  }
  resource spokeSubnet 'subnets' existing = {
    name: 'subnet-001'
  }
}

// use "i-1" for index of array starting with "0"
// loop index starts with "1" 
resource peeringHubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: 'hub-to-spoke-${index}'
  parent: hubVnet
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVnet.id
    }
  }
}

// use "i-1" for index of array starting with "0"
// loop index starts with "1" 
resource peeringSpokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: 'spoke-${index}-to-hub'
  parent: spokeVnet
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'ubuntu-spoke-${index}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: spokeVnet::spokeSubnet.id
          }
        }
      }
    ]
  }
}

resource ubuntuVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'ubuntu-spoke-${index}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2ms'
    }
    osProfile: {
      computerName: 'ubuntu-spoke-${index}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        name: 'ubuntu-spoke-${index}-disk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}

