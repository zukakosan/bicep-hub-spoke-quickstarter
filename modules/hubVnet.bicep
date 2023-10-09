param location string
param azfwName string
param adminUsername string
@secure()
param adminPassword string
param deployAzureBastion bool
var serverName = 'jumpbox'

// create network security group for hub vnet
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

// create hub vnet
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
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
  resource hubSubnet 'subnets' existing = {
    name: 'subnet-001'
  }
}

// create network interface for jumpbox vm
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: 'ubuntu-${serverName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: hubVnet::hubSubnet.id
          }
        }
      }
    ]
  }
}

// create jumpbox vm
resource jumpBox 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: 'ubuntu-${serverName}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2ms'
    }
    osProfile: {
      computerName: 'ubuntu-${serverName}'
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
        name: 'ubuntu-${serverName}-disk'
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

// create Azure Firewall by azfw.bicep module
module createAzfw './azfw.bicep' = {
  name: 'createAzfw'
  params:{
    location: location
    azfwName: azfwName
    dnatAddress: networkInterface.properties.ipConfigurations[0].properties.privateIPAddress
  }
}

// create route table after creating azure firewall to acquire private IP address of azure firewall
resource routeTable 'Microsoft.Network/routeTables@2023-04-01' = {
  name: 'rt-hub'
  location: location
  properties: {
    routes: [
      {
        name: 'defaultRoute'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: createAzfw.outputs.azfwPrivateIp
        }
      }
    ]
    disableBgpRoutePropagation: false
  }
}

// update subnet to use route table
resource subnetRouteTableAssociation 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  name: hubVnet::hubSubnet.name
  parent: hubVnet
  properties: {
    addressPrefix: '10.0.0.0/24'
    networkSecurityGroup: {
      id: nsgDefault.id
    }
    routeTable: {
      id: routeTable.id
    }
  }
}

// create azure bastion if deployAzureBastion is true
module createAzureBastion './bastion.bicep' = if(deployAzureBastion) {
  name: 'createAzureBastion'
  params: {
    location: location
  }
  dependsOn: [
    hubVnet
  ]
}
