# ============================================================================
# OUTPUTS - Infrastructure Information
# ============================================================================

output "load_balancer_url" {
  description = "URL of the load balancer"
  value       = var.enable_tls ? "https://localhost:${var.lb_port}" : "http://localhost:${var.lb_port}"
}

output "load_balancer_health_url" {
  description = "Load balancer health check URL"
  value       = var.enable_tls ? "https://localhost:${var.lb_port}/health" : "http://localhost:${var.lb_port}/health"
}

output "application_info" {
  description = "Application deployment information"
  value = {
    name        = var.app_name
    version     = var.app_version
    node_count  = var.node_count
    tls_enabled = var.enable_tls
  }
}

output "app_nodes" {
  description = "List of application node details"
  value = {
    for i, container in docker_container.app_nodes : "node-${i + 1}" => {
      name          = container.name
      hostname      = container.hostname
      internal_ip   = container.network_data[0].ip_address
      external_port = local.app_node_ports[i].external
      internal_port = local.app_node_ports[i].internal
      health_url    = "http://localhost:${local.app_node_ports[i].external}/health"
      direct_url    = "http://localhost:${local.app_node_ports[i].external}"
    }
  }
}

output "network_info" {
  description = "Network configuration details"
  value = {
    network_name = docker_network.app_network.name
    subnet       = var.network_subnet
    gateway      = one([for config in docker_network.app_network.ipam_config : config.gateway])
  }
}

output "container_configuration" {
  description = "Container configuration summary"
  value = {
    memory_limit_mb       = var.container_memory
    memory_swap_mb        = var.container_memory_swap
    gunicorn_workers      = var.gunicorn_workers
    gunicorn_timeout      = var.gunicorn_timeout
    health_check_interval = var.health_check_interval
  }
}

output "build_information" {
  description = "Docker image build information"
  value = {
    image_name    = docker_image.ping_app.name
    image_id      = docker_image.ping_app.image_id
    repo_digest   = docker_image.ping_app.repo_digest
    trigger_files = var.rebuild_trigger_files
    current_hash  = local.rebuild_trigger_hash
    file_checksums = {
      for file in var.rebuild_trigger_files :
      file => fileexists("${path.module}/${file}") ? filesha1("${path.module}/${file}") : "missing"
    }
  }
}

output "security_configuration" {
  description = "Security settings summary"
  value = {
    tls_enabled           = var.enable_tls
    security_headers      = var.enable_security_headers
    ssl_protocols         = var.enable_tls ? var.ssl_protocols : null
    rate_limit_per_second = var.rate_limit_requests
    rate_limit_burst      = var.rate_limit_burst
  }
}

output "monitoring_endpoints" {
  description = "Available monitoring and health check endpoints"
  value = {
    application_health = "${var.enable_tls ? "https" : "http"}://localhost:${var.lb_port}/health"
    api_ping           = "${var.enable_tls ? "https" : "http"}://localhost:${var.lb_port}/api/ping"
    direct_nodes = {
      for i in range(var.node_count) : "node-${i + 1}" => {
        health = "http://localhost:${var.app_port + i}/health"
        api    = "http://localhost:${var.app_port + i}/api/ping"
        home   = "http://localhost:${var.app_port + i}/"
      }
    }
  }
}

output "resource_tags" {
  description = "Applied resource tags"
  value       = local.common_labels
}

output "deployment_summary" {
  description = "Complete deployment summary"
  value = {
    app_name          = var.app_name
    app_version       = var.app_version
    node_count        = var.node_count
    load_balancer_url = var.enable_tls ? "https://localhost:${var.lb_port}" : "http://localhost:${var.lb_port}"
    tls_enabled       = var.enable_tls
    network_subnet    = var.network_subnet
    managed_by        = "terraform"
  }
}
