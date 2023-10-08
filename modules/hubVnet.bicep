param location string
// param azfwDeploy bool
param azfwName string
param adminUsername string
@secure()
param adminPassword string

resource nsgDefault 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-hub'
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

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
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
          networkSecurityGroup: {
            id: nsgDefault.id
          }
        }
      }
    ]
  }
  resource hubSubnet 'subnets' existing = {
    name: 'subnet-001'
  }
}

// if azfwDeploy = true, create azfw subnet
resource createAzfwSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  name: 'AzureFirewallSubnet'
  parent: hubVnet
  properties: {
    addressPrefix: '10.0.1.0/24'
  }
}

// if azfwDeploy = true, create azfw
module createAzfw './azfw.bicep' = {
  name: 'createAzfw'
  params:{
    location: location
    azfwName: azfwName
  }
  dependsOn:[
    createAzfwSubnet
  ]
}

// // if azfwDeploy = true, create azfw route table
// resource routeTable 'Microsoft.Network/routeTables@2019-11-01' = if(azfwDeploy) {
//   name: 'rt-hub'
//   location: location
//   properties: {
//     routes: [
//       {
//         name: 'defaultRoute'
//         properties: {
//           addressPrefix: '0.0.0.0/0'
//           nextHopType: 'VirtualAppliance'
//           nextHopIpAddress: createAzfw.outputs.azfwPrivateIp
//         }
//       }
//     ]
//     disableBgpRoutePropagation: true
//   }
// }

// resource networkInterface 'Microsoft.Network/networkInterfaces@2020-11-01' = {
//   name: 'ubuntu-hub-nic'
//   location: location
//   properties: {
//     ipConfigurations: [
//       {
//         name: 'ipconfig1'
//         properties: {
//           privateIPAllocationMethod: 'Dynamic'
//           subnet: {
//             id: hubVnet::hubSubnet.id
//           }
//         }
//       }
//     ]
//   }
// }

// resource ubuntuVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
//   name: 'ubuntu-hub'
//   location: location
//   properties: {
//     hardwareProfile: {
//       vmSize: 'Standard_B2ms'
//     }
//     osProfile: {
//       computerName: 'ubuntu-hub'
//       adminUsername: adminUsername
//       adminPassword: adminPassword
//     }
//     storageProfile: {
//       imageReference: {
//         publisher: 'Canonical'
//         offer: '0001-com-ubuntu-server-focal'
//         sku: '20_04-lts-gen2'
//         version: 'latest'
//       }
//       osDisk: {
//         name: 'ubuntu-hub-disk'
//         caching: 'ReadWrite'
//         createOption: 'FromImage'
//       }
//     }
//     networkProfile: {
//       networkInterfaces: [
//         {
//           id: networkInterface.id
//         }
//       ]
//     }
//     diagnosticsProfile: {
//       bootDiagnostics: {
//         enabled: false
//       }
//     }
//   }
// }
