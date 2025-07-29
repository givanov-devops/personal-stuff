# ============================================================================
# VARIABLES - Input Configuration
# ============================================================================

# Application Configuration
variable "app_name" {
  description = "Name of the application (used for naming resources)"
  type        = string
  default     = "ping-app"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.app_name))
    error_message = "App name must be lowercase, start with a letter, and contain only letters, numbers, and hyphens."
  }
}

variable "app_version" {
  description = "Version tag for the application"
  type        = string
  default     = "latest"
}

# Infrastructure Configuration
variable "node_count" {
  description = "Number of application nodes to deploy"
  type        = number
  default     = 3

  validation {
    condition     = var.node_count > 0 && var.node_count <= 10
    error_message = "Node count must be between 1 and 10."
  }
}

variable "lb_port" {
  description = "External port for the load balancer"
  type        = number
  default     = 8080

  validation {
    condition     = var.lb_port > 1000 && var.lb_port < 65536
    error_message = "Load balancer port must be between 1001 and 65535."
  }
}

variable "enable_tls" {
  description = "Enable TLS/HTTPS for the load balancer"
  type        = bool
  default     = true
}

# Container Configuration
variable "container_memory" {
  description = "Memory limit for application containers (MB)"
  type        = number
  default     = 256

  validation {
    condition     = var.container_memory >= 128 && var.container_memory <= 2048
    error_message = "Container memory must be between 128MB and 2048MB."
  }
}

variable "container_memory_swap" {
  description = "Memory swap limit for application containers (MB)"
  type        = number
  default     = 512
}

variable "gunicorn_workers" {
  description = "Number of Gunicorn worker processes per container"
  type        = number
  default     = 2

  validation {
    condition     = var.gunicorn_workers >= 1 && var.gunicorn_workers <= 8
    error_message = "Gunicorn workers must be between 1 and 8."
  }
}

variable "gunicorn_timeout" {
  description = "Gunicorn worker timeout in seconds"
  type        = number
  default     = 30

  validation {
    condition     = var.gunicorn_timeout >= 10 && var.gunicorn_timeout <= 300
    error_message = "Gunicorn timeout must be between 10 and 300 seconds."
  }
}

# Network Configuration
variable "network_subnet" {
  description = "CIDR subnet for the application network"
  type        = string
  default     = "172.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.network_subnet, 0))
    error_message = "Network subnet must be a valid CIDR block."
  }
}

variable "app_port" {
  description = "Internal port for the application containers"
  type        = number
  default     = 5000

  validation {
    condition     = var.app_port > 1000 && var.app_port < 65536
    error_message = "Application port must be between 1001 and 65535."
  }
}

# Health Check Configuration
variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30

  validation {
    condition     = var.health_check_interval >= 10 && var.health_check_interval <= 300
    error_message = "Health check interval must be between 10 and 300 seconds."
  }
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 10

  validation {
    condition     = var.health_check_timeout >= 5 && var.health_check_timeout <= 60
    error_message = "Health check timeout must be between 5 and 60 seconds."
  }
}

variable "health_check_retries" {
  description = "Number of health check retries before marking unhealthy"
  type        = number
  default     = 3

  validation {
    condition     = var.health_check_retries >= 1 && var.health_check_retries <= 10
    error_message = "Health check retries must be between 1 and 10."
  }
}

variable "health_check_start_period" {
  description = "Health check start period in seconds"
  type        = number
  default     = 15

  validation {
    condition     = var.health_check_start_period >= 0 && var.health_check_start_period <= 300
    error_message = "Health check start period must be between 0 and 300 seconds."
  }
}

# Load Balancer Configuration
variable "nginx_worker_connections" {
  description = "Number of worker connections for Nginx"
  type        = number
  default     = 1024

  validation {
    condition     = var.nginx_worker_connections >= 512 && var.nginx_worker_connections <= 8192
    error_message = "Nginx worker connections must be between 512 and 8192."
  }
}

variable "rate_limit_requests" {
  description = "Rate limit requests per second per IP"
  type        = number
  default     = 10

  validation {
    condition     = var.rate_limit_requests >= 1 && var.rate_limit_requests <= 1000
    error_message = "Rate limit must be between 1 and 1000 requests per second."
  }
}

variable "rate_limit_burst" {
  description = "Rate limit burst size"
  type        = number
  default     = 20
}

# Build Configuration
variable "docker_build_no_cache" {
  description = "Force Docker build without cache"
  type        = bool
  default     = false
}

variable "rebuild_trigger_files" {
  description = "List of files that should trigger Docker image rebuilds"
  type        = list(string)
  default     = ["Dockerfile", "app.py", "requirements.txt"]

  validation {
    condition     = length(var.rebuild_trigger_files) > 0
    error_message = "At least one trigger file must be specified."
  }
}

# Monitoring Configuration
variable "enable_detailed_logging" {
  description = "Enable detailed application logging"
  type        = bool
  default     = false
}

variable "log_level" {
  description = "Application log level"
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARNING, ERROR, CRITICAL."
  }
}

# Security Configuration
variable "enable_security_headers" {
  description = "Enable security headers in Nginx"
  type        = bool
  default     = true
}

variable "ssl_protocols" {
  description = "Allowed SSL/TLS protocols"
  type        = list(string)
  default     = ["TLSv1.2", "TLSv1.3"]

  validation {
    condition = alltrue([
      for protocol in var.ssl_protocols :
      contains(["TLSv1", "TLSv1.1", "TLSv1.2", "TLSv1.3"], protocol)
    ])
    error_message = "SSL protocols must be valid TLS versions."
  }
}

# Resource Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project   = "ping-application"
    ManagedBy = "terraform"
    Owner     = "givanov-devops"
  }

  validation {
    condition     = contains(keys(var.tags), "Project")
    error_message = "Tags must include a 'Project' key."
  }
}
