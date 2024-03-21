resource "google_sql_database_instance" "mysqlcloudserver" {
    name             = "mysqlcloudserver"
    database_version = "MYSQL_8_0"

    settings {
        tier = "db-f1-micro"
        ip_configuration {
            ipv4_enabled     = true
        
            authorized_networks {
                value           = "0.0.0.0/0"
                name            = "all"
            }
        }
    }

    deletion_protection = false
}

resource "google_sql_user" "root" {
    name     = "root"
    instance = google_sql_database_instance.mysqlcloudserver.name
    password = var.root_password
}

resource "null_resource" "populate_db" {
    depends_on = [
        google_sql_user.root,
    ]

    provisioner "local-exec" {
        command = "mysql --host=${google_sql_database_instance.mysqlcloudserver.public_ip_address} --user=${google_sql_user.root.name} --password=${google_sql_user.root.password} < CreateDatabase.sql >  /dev/null"
    }
}
