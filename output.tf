output "vnet" {
  description = "The created VNET with all of it's attributes"
  value       = aviatrix_vpc.default
}


output "transit_gateway" {
  description = "The Aviatrix transit gateway object with all of it's attributes"
  value       = aviatrix_transit_gateway.ha
}

output "aviatrix_firenet" {
  description = "The Aviatrix firenet object with all of it's attributes"
  value       = aviatrix_firenet.firenet_ha
}

output "aviatrix_firewall_instance" {
  description = "A list with the created firewall instances and their attributes"
  value       = [aviatrix_firewall_instance.firewall_instance_1, aviatrix_firewall_instance.firewall_instance_2] 
}



