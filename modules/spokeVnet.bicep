param location string
param index int
param adminUsername string
@secure()
param adminPassword string
param azfwName string

var subnetName = 'subnet-001'
var testVmSize = 'Standard_B2ms'
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: 'vnet-hub'
}
resource azureFirewall 'Microsoft.Network/azureFirewalls@2023-04-01' existing = {
  name: azfwName
}

// create network security group for spoke vnet
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

// create route table with route of 0.0.0.0/0 to azure firewall
resource routeTable 'Microsoft.Network/routeTables@2023-04-01' = {
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
    disableBgpRoutePropagation: false
  }
}

// create spoke vnet with subnet that nsg and route table is attached
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
        name: subnetName
        properties: {
          addressPrefix: '10.${index}0.0.0/24'
          networkSecurityGroup: {
            id: nsgDefault.id
          }
          routeTable: {
            id: routeTable.id
          }
        }
      }
    ]
  }
  resource spokeSubnet 'subnets' existing = {
    name: subnetName
  }
}

// peering from hub to spoke
resource peeringHubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
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

// peering from spoke to hub
resource peeringSpokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
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

// create network interface for ubuntu vm
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-04-01' = {
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

// create ubuntu vm
resource ubuntuVM 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: 'ubuntu-spoke-${index}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: testVmSize
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

