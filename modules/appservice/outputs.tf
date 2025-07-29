output "appservices" {
    value = {
    for name, app in azurerm_linux_web_app.as-linux :
    name => {
      name                  = app.name
      identity_principal_id = app.identity[0].principal_id
      id                    = app.id
      hostname              = app.default_hostname
    }
  }
}

