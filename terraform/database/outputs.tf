output "db_address" {
  value = google_sql_database_instance.mysqlcloudserver.public_ip_address
}