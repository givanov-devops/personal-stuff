#!/usr/bin/env python3
"""
Simple Load Testing Script for Alcatraz AI Ping Application
Sends configurable number of requests to the load balancer and analyzes
node distribution.
"""

import argparse
import sys
from collections import Counter

import requests
import urllib3

# Disable SSL warnings for self-signed certificates
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def make_request(url, timeout=10):
    """Make a single request to the ping endpoint."""
    try:
        response = requests.get(url, verify=False, timeout=timeout)
        if response.status_code == 200:
            data = response.json()
            return data.get("hostname", "unknown"), True
        else:
            return "error", False
    except Exception:
        return "error", False


def run_load_test(url, num_requests, timeout=10):
    """Run load test and collect results."""
    print("🚀 Starting load test...")
    print(f"Target URL: {url}")
    print(f"Total Requests: {num_requests}")
    print("-" * 50)

    hostnames = []
    successful_requests = 0
    failed_requests = 0

    for i in range(num_requests):
        # Progress indicator
        if (i + 1) % 10 == 0 or i == 0:
            print(f"Progress: {i + 1}/{num_requests} requests...")

        hostname, success = make_request(url, timeout)

        if success:
            hostnames.append(hostname)
            successful_requests += 1
        else:
            failed_requests += 1

    print("✅ Load test completed!")
    print("-" * 50)

    return hostnames, successful_requests, failed_requests


def analyze_results(hostnames, successful_requests, failed_requests):
    """Analyze results and print Alcatraz AI required information."""
    print("\n" + "=" * 60)
    print("         ALCATRAZ AI LOAD TEST RESULTS")
    print("=" * 60)

    # Basic statistics
    total_requests = successful_requests + failed_requests
    success_rate = (
        (successful_requests / total_requests * 100) if total_requests > 0 else 0
    )

    print(f"Total Requests: {total_requests}")
    print(f"Successful Requests: {successful_requests}")
    print(f"Failed Requests: {failed_requests}")
    print(f"Success Rate: {success_rate:.1f}%")
    print()

    if successful_requests > 0:
        # Count requests per node
        hostname_counter = Counter(hostnames)

        # 🎯 ALCATRAZ AI REQUIREMENT 1: List of node hostnames
        print("📋 LIST OF NODE HOSTNAMES:")
        print("-" * 40)
        node_list = list(hostname_counter.keys())
        print(f"Node Hostnames: {', '.join(node_list)}")
        print()

        # 🎯 ALCATRAZ AI REQUIREMENT 2: Count of available nodes
        print("🔢 COUNT OF AVAILABLE NODES:")
        print("-" * 40)
        available_nodes = len(hostname_counter)
        print(f"Available Nodes: {available_nodes}")
        print()

        # 🎯 ALCATRAZ AI REQUIREMENT 3: Number of requests handled by each node
        print("📊 REQUESTS HANDLED BY EACH NODE:")
        print("-" * 40)
        for hostname, count in hostname_counter.items():
            percentage = (count / successful_requests) * 100
            print(f"  {hostname}: {count} requests ({percentage:.1f}%)")
        print()

        print("=" * 60)
        print("✅ ALCATRAZ AI REQUIREMENTS COMPLETED:")
        print("   ✓ List of node hostnames")
        print("   ✓ Number of requests handled by each node")
        print("   ✓ Count of available nodes")
        print("=" * 60)
    else:
        print("❌ No successful requests to analyze")


def main():
    """Main function."""
    parser = argparse.ArgumentParser(
        description="Simple load tester for Alcatraz AI ping application"
    )
    parser.add_argument(
        "--url",
        default="https://localhost:8080/api/ping",
        help="Target URL (default: https://localhost:8080/api/ping)",
    )
    parser.add_argument(
        "--requests",
        "-n",
        type=int,
        default=100,
        help="Number of requests to send (default: 100)",
    )
    parser.add_argument(
        "--timeout",
        "-t",
        type=int,
        default=10,
        help="Request timeout in seconds (default: 10)",
    )

    args = parser.parse_args()

    # Validate arguments
    if args.requests <= 0:
        print("❌ Error: Number of requests must be positive")
        sys.exit(1)

    try:
        # Run load test
        hostnames, successful, failed = run_load_test(
            args.url, args.requests, args.timeout
        )

        # Analyze and display results
        analyze_results(hostnames, successful, failed)

    except KeyboardInterrupt:
        print("\n❌ Load test interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error running load test: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
