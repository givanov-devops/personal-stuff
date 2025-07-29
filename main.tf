# ============================================================================
# TLS CERTIFICATE GENERATION
# ============================================================================

resource "tls_private_key" "internal_ca" {
  count = var.enable_tls ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "internal_ca" {
  count = var.enable_tls ? 1 : 0

  private_key_pem = tls_private_key.internal_ca[0].private_key_pem

  subject {
    common_name  = "Internal CA"
    organization = var.tags.Project
  }

  validity_period_hours = 8760 # 1 year
  is_ca_certificate     = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}

# ============================================================================
# NETWORK INFRASTRUCTURE
# ============================================================================

resource "docker_network" "app_network" {
  name   = local.network_name
  driver = "bridge"

  ipam_config {
    subnet = var.network_subnet
  }

  dynamic "labels" {
    for_each = merge(local.common_labels, {
      component = "network"
    })

    content {
      label = labels.key
      value = labels.value
    }
  }
}

# ============================================================================
# APPLICATION IMAGE BUILD
# ============================================================================

resource "docker_image" "ping_app" {
  name = local.app_image_name

  build {
    context    = "."
    dockerfile = "Dockerfile"
    no_cache   = var.docker_build_no_cache

    # Static build args - only change when variables change
    build_args = {
      VCS_REF  = var.app_version
      APP_PORT = tostring(var.app_port)
    }
  }

  keep_locally = true

  # Rebuilds, if something is changed within the conf files
  triggers = {
    source_files_sha1 = local.rebuild_trigger_hash
  }
}

# ============================================================================
# APPLICATION CONTAINERS
# ============================================================================

resource "docker_container" "app_nodes" {
  count = var.node_count

  name  = "${local.app_container_name_template}-${count.index + 1}"
  image = docker_image.ping_app.image_id

  # Network configuration
  networks_advanced {
    name = docker_network.app_network.name
  }

  # Environment variables
  env = local.container_environment

  # Port mapping
  ports {
    internal = local.app_node_ports[count.index].internal
    external = local.app_node_ports[count.index].external
  }

  # Container configuration
  restart = "unless-stopped"
  command = local.gunicorn_command

  # Resource limits
  memory      = var.container_memory
  memory_swap = var.container_memory_swap

  # Health check configuration
  healthcheck {
    test = [
      "CMD",
      "curl",
      "-f",
      local.health_check_config.endpoint
    ]
    interval     = local.health_check_config.interval
    timeout      = local.health_check_config.timeout
    retries      = local.health_check_config.retries
    start_period = local.health_check_config.start_period
  }

  # Labels for identification and management
  dynamic "labels" {
    for_each = merge(local.common_labels, {
      component = "application"
      node_id   = "node-${count.index + 1}"
      app       = "ping-service"
    })

    content {
      label = labels.key
      value = labels.value
    }
  }
}

# ============================================================================
# LOAD BALANCER CONFIGURATION
# ============================================================================

resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = true
}

# Nginx configuration template with variables
locals {
  nginx_config = templatefile("${path.module}/data/nginx.conf.tpl", {
    app_nodes               = docker_container.app_nodes
    enable_tls              = var.enable_tls
    ssl_config              = local.ssl_config
    worker_connections      = var.nginx_worker_connections
    rate_limit_config       = local.rate_limit_config
    enable_security_headers = var.enable_security_headers
    app_port                = var.app_port
  })
}

resource "docker_container" "load_balancer" {
  name  = local.lb_container_name
  image = docker_image.nginx.image_id

  # Network configuration
  networks_advanced {
    name = docker_network.app_network.name
  }

  # Port configuration
  ports {
    internal = var.enable_tls ? 443 : 80
    external = var.lb_port
  }

  # Nginx configuration
  upload {
    content = local.nginx_config
    file    = "/etc/nginx/nginx.conf"
  }

  # TLS certificates (conditional)
  dynamic "upload" {
    for_each = var.enable_tls ? [1] : []
    content {
      content = tls_self_signed_cert.internal_ca[0].cert_pem
      file    = local.ssl_config.cert_path
    }
  }

  dynamic "upload" {
    for_each = var.enable_tls ? [1] : []
    content {
      content = tls_private_key.internal_ca[0].private_key_pem
      file    = local.ssl_config.key_path
    }
  }

  # Container configuration
  restart = "unless-stopped"

  # Resource limits (lighter for load balancer)
  memory      = 128
  memory_swap = 256

  # Labels
  dynamic "labels" {
    for_each = merge(local.common_labels, {
      component = "load-balancer"
      app       = "nginx"
    })

    content {
      label = labels.key
      value = labels.value
    }
  }

  depends_on = [docker_container.app_nodes]
}
