# ============================================================================
# LOCAL VALUES - Computed Configuration
# ============================================================================

locals {
  # Resource naming with consistent patterns
  resource_prefix = var.app_name

  # Network configuration
  network_name = "${local.resource_prefix}-network"

  # Container naming patterns
  app_container_name_template = "${local.resource_prefix}-node"
  lb_container_name           = "${local.resource_prefix}-lb"

  # Image configuration
  app_image_name = "${var.app_name}:${var.app_version}"

  # Port mappings for application nodes
  app_node_ports = [
    for i in range(var.node_count) : {
      internal = var.app_port
      external = var.app_port + i
    }
  ]

  # Build trigger hash computation (stable and predictable)
  rebuild_trigger_hash = sha1(join("", [
    for file in var.rebuild_trigger_files :
    fileexists("${path.module}/${file}") ? filesha1("${path.module}/${file}") : "file-not-found"
  ]))

  # Container environment variables
  container_environment = [
    "FLASK_HOST=0.0.0.0",
    "FLASK_PORT=${var.app_port}",
    "FLASK_DEBUG=true",
    "LOG_LEVEL=${var.log_level}",
    "APP_NAME=${var.app_name}"
  ]

  # Gunicorn command configuration
  gunicorn_command = [
    "gunicorn",
    "--bind", "0.0.0.0:${var.app_port}",
    "--workers", tostring(var.gunicorn_workers),
    "--timeout", tostring(var.gunicorn_timeout),
    "--worker-class", "sync",
    "--max-requests", "1000",
    "--max-requests-jitter", "100",
    "--preload",
    "app:app"
  ]

  # Resource labels for all containers
  common_labels = merge(var.tags, {
    app_name   = var.app_name
    version    = var.app_version
    managed_by = "terraform"
  })

  # SSL configuration
  ssl_config = var.enable_tls ? {
    cert_path = "/etc/nginx/ssl/cert.pem"
    key_path  = "/etc/nginx/ssl/key.pem"
    protocols = join(" ", var.ssl_protocols)
  } : null

  # Health check configuration
  health_check_config = {
    interval     = "${var.health_check_interval}s"
    timeout      = "${var.health_check_timeout}s"
    retries      = var.health_check_retries
    start_period = "${var.health_check_start_period}s"
    endpoint     = "http://localhost:${var.app_port}/health"
  }

  # Rate limiting configuration
  rate_limit_config = {
    requests_per_second = var.rate_limit_requests
    burst_size          = var.rate_limit_burst
    zone_size           = "10m"
  }
}
