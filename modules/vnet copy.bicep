param location string
param azfwEnabled string

var azfwDeploy = azfwEnabled == 'Enabled'

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

resource createAzfwSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = if(azfwDeploy) {
  name: 'AzureFirewallSubnet'
  parent: hubVnet
  properties: {
    addressPrefix: '10.0.2.0/24'
  }
}


// Spoke VNET の構成をloopで作成した方がよさそう

// resource spokeVNetLoop 'Microsoft.Network/virtualNetworks@2023-04-01' = [for i in range(1, spokeCount): {
//   name: 'vnet-spoke-${i}'
//   location: location
//   properties: {
//     addressSpace: {
//       addressPrefixes: [
//         '10.${i}0.0.0/16'
//       ]
//     }
//     subnets: [
//       {
//         name: 'subnet-001'
//         properties: {
//           addressPrefix: '10.${i}0.0.0/24'
//         }
//       }
//       {
//         name: 'subnet-002'
//         properties: {
//           addressPrefix: '10.${i}0.1.0/24'
//         }
//       }
//     ]
//   }
// }]

// // use "i-1" for index of array starting with "0"
// // loop index starts with "1" 
// resource peeringHubToSpokeLoop 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = [for i in range(1, spokeCount): {
//   name: 'hub-to-spoke-${i}'
//   parent: hubVnet
//   properties: {
//     allowVirtualNetworkAccess: true
//     allowForwardedTraffic: true
//     allowGatewayTransit: false
//     useRemoteGateways: false
//     remoteVirtualNetwork: {
//       id: spokeVNetLoop[i-1].id
//     }
//   }
// }]

// // use "i-1" for index of array starting with "0"
// // loop index starts with "1" 
// resource peeringSpokeToHubLoop 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = [for i in range(1, spokeCount):  {
//   name: 'spoke-${i}-to-hub'
//   parent: spokeVNetLoop[i-1]
//   properties: {
//     allowVirtualNetworkAccess: true
//     allowForwardedTraffic: true
//     allowGatewayTransit: false
//     useRemoteGateways: false
//     remoteVirtualNetwork: {
//       id: hubVnet.id
//     }
//   }
// }]

// resource networkInterface 'Microsoft.Network/networkInterfaces@2020-11-01' = {
//   name: 'name'
//   location: location
//   properties: {
//     ipConfigurations: [
//       {
//         name: 'name'
//         properties: {
//           privateIPAllocationMethod: 'Dynamic'
//           subnet: {
//             id: 'subnet.id'
//           }
//         }
//       }
//     ]
//   }
// }


// resource ubuntuVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
//   name: 'name'
//   location: location
//   properties: {
//     hardwareProfile: {
//       vmSize: 'Standard_A2_v2'
//     }
//     osProfile: {
//       computerName: 'computerName'
//       adminUsername: 'adminUsername'
//       adminPassword: 'adminPassword'
//     }
//     storageProfile: {
//       imageReference: {
//         publisher: 'Canonical'
//         offer: 'UbuntuServer'
//         sku: '16.04-LTS'
//         version: 'latest'
//       }
//       osDisk: {
//         name: 'name'
//         caching: 'ReadWrite'
//         createOption: 'FromImage'
//       }
//     }
//     networkProfile: {
//       networkInterfaces: [
//         {
//           id: 'id'
//         }
//       ]
//     }
//     diagnosticsProfile: {
//       bootDiagnostics: {
//         enabled: true
//         storageUri: 'storageUri'
//       }
//     }
//   }
// }
