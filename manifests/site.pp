node /^vcac-sdl-web-\d{4}/ {
  include roles::frontend_webserver
}

node /^vcac-sdl-db-\d{4}/ {
  include roles::backend_dbserver
}

node default {

  include profiles::base

}
