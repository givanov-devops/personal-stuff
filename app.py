#!/usr/bin/env python3
"""
Simple Flask web application.
Provides /api/ping endpoint that returns JSON with message and hostname.
"""

import logging
import os
import socket

from flask import Flask, jsonify

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)

app = Flask(__name__)
logger = logging.getLogger(__name__)


def get_hostname():
    """Get the hostname of the current server node."""
    try:
        return socket.gethostname()
    except Exception as e:
        logger.error(f"Error getting hostname: {e}")
        return "unknown"


@app.route("/", methods=["GET"])
def home():
    """
    Home endpoint with custom message.

    Returns:
        JSON response with custom message and hostname
    """
    hostname = get_hostname()
    response_data = {
        "message": "I hope to be part of the Alcatraz AI DevOps team soon :)",
        "hostname": hostname,
        "status": "ready",
    }

    logger.info(f"Received home request, responding from {hostname}")
    return jsonify(response_data)


@app.route("/api/ping", methods=["GET"])
def ping():
    """
    Ping endpoint that returns pong message with hostname.

    Returns:
        JSON response with message and hostname
    """
    hostname = get_hostname()
    response_data = {"message": "pong", "hostname": hostname}

    logger.info(f"Received ping request, responding from {hostname}")
    return jsonify(response_data)


@app.route("/health", methods=["GET"])
def health_check():
    """Health check endpoint for load balancer."""
    return jsonify({"status": "healthy"}), 200


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return jsonify({"error": "Not found"}), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors."""
    logger.error(f"Internal server error: {error}")
    return jsonify({"error": "Internal server error"}), 500


if __name__ == "__main__":
    # Get configuration from environment variables
    host = os.getenv("FLASK_HOST", "0.0.0.0")
    port = int(os.getenv("FLASK_PORT", 5000))
    debug = os.getenv("FLASK_DEBUG", "False").lower() == "true"

    logger.info(f"Starting Flask app on {host}:{port}")
    app.run(host=host, port=port, debug=debug)
