output "subnets" {
    value = {
    for subnet in azurerm_subnet.sbs :
    replace(replace(subnet.name,"sb-",""),"-${local.resource_suffixes}","") => {
      name = subnet.name
      id   = subnet.id
    }
  }
}

output "vnet_id" {
  value = azurerm_virtual_network.vn.id
}