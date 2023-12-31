param location string
param azfwName string
param adminUsername string
@secure()
param adminPassword string
param deployAzureBastion bool

var serverName = 'jumpbox'
var subnetName = 'subnet-001'
var jumpboxVmSize = 'Standard_B2ms'

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
        name: subnetName
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


module createVM './vm.bicep' = {
  name: 'createHubVM'
  params:{
    location: location
    nicName: 'vm-${serverName}-nic'
    subnetId: hubVnet::hubSubnet.id
    vmName: 'vm-${serverName}'
    adminUsername: adminUsername
    adminPassword: adminPassword
    diskName: 'vm-${serverName}-disk'
    vmSize: jumpboxVmSize
  }
}

// create Azure Firewall by azfw.bicep module
module createAzfw './azfw.bicep' = {
  name: 'createAzfw'
  params:{
    location: location
    azfwName: azfwName
    dnatAddress: createVM.outputs.vmPrivateIp // to create dnat rule for jumpbox vm
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

// create azure bastion after hub vnet creattion if deployAzureBastion is true
module createAzureBastion './bastion.bicep' = if(deployAzureBastion) {
  name: 'createAzureBastion'
  params: {
    location: location
  }
  dependsOn: [
    hubVnet
  ]
}
