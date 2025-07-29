from collections import Counter

import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

URL = "https://localhost:8080/health"

hostnames = []

for i in range(100):
    try:
        r = requests.get(URL, verify=False, timeout=3)
        r.raise_for_status()
        data = r.json()
        hostname = data.get("hostname")
        if hostname:
            hostnames.append(hostname)
        else:
            print(f"[{i}] No 'hostname' in response: {data}")
    except Exception as e:
        print(f"[{i}] Request failed: {e}")

counts = Counter(hostnames)

print("\nRequest distribution per node:")
for host, count in counts.items():
    print(f"{host}: {count} requests")

print(f"\nTotal unique nodes: {len(counts)}")
print(f"Total successful requests: {sum(counts.values())}")
