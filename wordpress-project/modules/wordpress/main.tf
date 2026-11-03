locals {
  user_data = templatefile("${path.module}/user_data.sh", {
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
  })

  user_data_replace_on_change = true
}