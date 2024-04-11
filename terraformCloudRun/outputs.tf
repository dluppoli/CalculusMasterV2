output "db_address" {
  value = module.sqlvm.private_ip_address
}

output "lb_address" {
  value = module.lb.lb_address
}