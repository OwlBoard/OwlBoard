# Docker Networks Explained - OwlBoard Context

This document clarifies how Docker networks actually work and why the diagram shows them the way it does.

---

## ❓ The Confusion

**Question:** "Why does the diagram show networks as separate components? Do networks encapsulate containers?"

**Answer:** Networks are **NOT separate components** - they're **invisible overlay networks** that containers exist within. My original diagram was misleading. Let me explain the reality.

---

## 🌐 What Docker Networks Actually Are

### Think of Networks as Wi-Fi Networks

Imagine your house has two Wi-Fi networks:
- **GuestWifi** - Your guests can connect and access the internet
- **PrivateWifi** - Your devices can connect and access each other + internet

Some devices (like your phone) can connect to BOTH networks simultaneously - they have two "network cards" (one for each Wi-Fi).

**Docker networks work exactly the same way.**

---

## 🔍 OwlBoard's Two Networks

### 1. Public Network (`owlboard-public-network`)
```yaml
networks:
  owlboard-public-network:
    driver: bridge
    name: owlboard-public-network
    # NO 'internal: true' - external routing ENABLED
```

**What it means:**
- ✅ Containers can be reached from the host machine (via `localhost`)
- ✅ Containers can reach the internet
- ✅ Port mappings work (e.g., `3002:3000` exposes container to host)

**Who's on it:**
- Desktop Frontend (3002)
- Mobile Frontend (3001)
- Load Balancer (8000, 9000)

**Purpose:** Allow external users to reach these services

---

### 2. Private Network (`owlboard-private-network`)
```yaml
networks:
  owlboard-private-network:
    driver: bridge
    name: owlboard-private-network
    internal: true  # ← THIS IS THE KEY!
```

**What it means:**
- ❌ Containers CANNOT be reached from the host machine
- ❌ Containers CANNOT reach the internet
- ✅ Containers CAN communicate with each other
- ❌ Port mappings do NOT expose containers externally

**Who's on it:**
- Load Balancer (also on public - dual-homed!)
- API Gateway 1, 2, 3, 4
- User Service, Canvas Service, Chat Service, Comments Service
- MySQL, PostgreSQL, Redis, MongoDB, RabbitMQ

**Purpose:** Complete isolation - these services can ONLY talk to each other

---

## 🔌 Dual-Homed Containers (The Bridge)

Some containers are connected to **BOTH** networks:

### Load Balancer
```yaml
load_balancer:
  networks:
    - owlboard-public-network   # Can receive external traffic
    - owlboard-private-network  # Can reach API Gateways
```

**Think of it as:**
The Load Balancer literally has **TWO network interfaces (NICs)**:
- **NIC 1** (public): IP = `172.18.0.5` - receives traffic from frontends
- **NIC 2** (private): IP = `172.19.0.5` - sends traffic to API Gateways

It's like having a phone connected to both "GuestWifi" and "PrivateWifi" simultaneously.

### Next.js Frontend (also dual-homed)
```yaml
nextjs_frontend:
  networks:
    - owlboard-public-network   # Receives browser requests
    - owlboard-private-network  # Makes server-side API calls
```

**Why?** Next.js does server-side rendering, so it needs to:
- Receive requests from browsers (public network)
- Make API calls to backend services (private network)

---

## 🎨 Why My Original Diagram Was Wrong

### ❌ Original (MISLEADING):
```
╔════════ PUBLIC NETWORK ════════╗
║  [Frontends]  [Load Balancer] ║
╚════════════════════════════════╝
           ↓
╔════════ PRIVATE NETWORK ═══════╗
║  [Gateways]  [Services]  [DBs] ║
╚════════════════════════════════╝
```

**Problem:** Makes it look like networks are "layers" or "separate zones" with a gateway between them.

### ✅ Reality (ACCURATE):
```
PUBLIC NETWORK (overlay):
  ┌─────────────────────────────┐
  │ [Desktop]  [Mobile]         │
  │                             │
  │ [Load Balancer] ◄───┐       │
  └──────────┬──────────┼───────┘
             │          │
             │   Has 2 NICs
             │          │
  ┌──────────▼──────────▼───────┐
  │ [Load Balancer] ◄───┘       │
  │       │                     │
  │ [Gateway 1-4]               │
  │       │                     │
  │ [Services] [Databases]      │
  │                             │
  PRIVATE NETWORK (overlay)
```

**Better:** Shows that Load Balancer exists in BOTH networks simultaneously, and networks are overlays, not physical separations.

---

## 🧠 Technical Reality: How Docker Implements This

### Network Namespaces
Each container has its own **network namespace** (isolated network stack):
- Own IP address
- Own routing table
- Own network interfaces

### Bridge Networks
Docker creates **virtual bridges** (like virtual switches):
- `br-public` (public network bridge)
- `br-private` (private network bridge)

### Container Connections
When you add a container to a network, Docker:
1. Creates a **virtual ethernet pair** (veth pair)
2. One end goes into the container (becomes `eth0`)
3. Other end connects to the bridge

### Dual-Homed Containers
For containers on multiple networks:
- They get **multiple veth pairs**
- `eth0` connects to public bridge
- `eth1` connects to private bridge
- They have **two IP addresses** (one on each network)

### Example: Load Balancer
```bash
# Inside load_balancer container
$ ip addr
1: lo: ...
2: eth0: inet 172.18.0.5/16  ← Public network interface
3: eth1: inet 172.19.0.5/16  ← Private network interface
```

### The `internal: true` Flag
When set on private network:
- Docker does NOT add a route to the host's routing table
- Docker does NOT enable IP forwarding to external networks
- Traffic can only flow between containers on that bridge

---

## 📊 Visual: Network Isolation in Action

### What CAN Happen:
```
Browser → localhost:8000 → Load Balancer (public NIC)
                             ↓ (routes to private NIC)
Load Balancer (private NIC) → API Gateway 1
                             ↓
API Gateway 1 → User Service → MySQL
```

### What CANNOT Happen:
```
Browser → localhost:3306 → MySQL
         ❌ NO ROUTE - Port not exposed

Browser → localhost:8001 → API Gateway 1
         ❌ NO ROUTE - Not on public network

Hacker → internet → MySQL
         ❌ BLOCKED - Private network has no external routing
```

---

## 🔒 Security Implications

### Defense in Depth
```
Layer 1: No exposed ports (databases, backend services)
         └─ Even if you know the IP, ports aren't mapped

Layer 2: Private network isolation
         └─ Even if ports were mapped, internal:true blocks routing

Layer 3: Network namespace isolation
         └─ Containers can't see each other's processes/files

Layer 4: Load balancer as gateway
         └─ All traffic must pass through controlled chokepoint
```

### Why This Matters
If an attacker compromises the Desktop Frontend:
- ✅ Can reach Load Balancer (on public network)
- ❌ Cannot reach API Gateways (not on public network)
- ❌ Cannot reach databases (not on public network)
- ❌ Cannot reach backend services directly (not on public network)

They MUST go through Load Balancer → API Gateway, which:
- Enforces rate limiting
- Logs all requests
- Can be monitored for anomalies

---

## 🎯 Correct Mental Model

### ❌ WRONG: Networks as "Zones"
```
Internet → [ DMZ Zone ] → [ Internal Zone ] → [ Database Zone ]
          (Firewall 1)    (Firewall 2)        (Firewall 3)
```

### ✅ RIGHT: Networks as "VLANs"
```
Container 1:  [eth0: VLAN 10]
Container 2:  [eth0: VLAN 20]
Container 3:  [eth0: VLAN 10, eth1: VLAN 20]  ← Bridge between VLANs
```

Docker networks are **virtual layer-2 networks** (like VLANs), not **layer-3 security zones** (like firewalls).

---

## 🧪 Practical Test

Run these commands to see the reality:

### 1. Check Load Balancer's Interfaces
```bash
docker exec load_balancer ip addr
# You'll see TWO interfaces (eth0 + eth1) with different IPs
```

### 2. Check Network Membership
```bash
docker network inspect owlboard-public-network
# Shows: Desktop, Mobile, Load Balancer

docker network inspect owlboard-private-network
# Shows: Load Balancer, Gateways, Services, Databases
```

### 3. Test Isolation
```bash
# This works (public network)
curl http://localhost:8000/health

# This fails (private network, no route)
curl http://localhost:3306
# Connection refused - port not accessible
```

### 4. Check Internal DNS
```bash
# From inside load_balancer
docker exec load_balancer ping api_gateway_1
# Works! Docker DNS resolves the name

# From outside (your host)
ping api_gateway_1
# Fails! Name only exists inside Docker networks
```

---

## 📚 Summary

### Key Takeaways

1. **Networks are Overlays**: Not physical separators, but virtual layer-2 networks (like VLANs or Wi-Fi networks)

2. **Containers Have NICs**: Containers on multiple networks have multiple virtual network interfaces

3. **`internal: true` Blocks Routing**: The private network has no route to the host or internet

4. **Dual-Homed = Bridge**: Load Balancer and Next.js Frontend bridge between public and private networks

5. **Docker DNS**: Service names (like `api_gateway_1`) only resolve inside Docker networks

6. **Security by Design**: Private network isolation is enforced at the network layer, not application layer

---

## 🎨 Better Diagram Concept

Think of it like this:

```
YOUR HOUSE (Host Machine)
├─ GuestWifi (Public Network)
│  ├─ Guest's Phone (Desktop Frontend)
│  ├─ Guest's Tablet (Mobile Frontend)
│  └─ Your Router (Load Balancer) ◄─── Has TWO radios
│
└─ PrivateWifi (Private Network)
   ├─ Your Router (Load Balancer) ◄─── Same device, different radio
   ├─ Your Smart TV (API Gateway 1)
   ├─ Your Laptop (API Gateway 2)
   ├─ Your Server (Backend Services)
   └─ Your NAS (Databases)
```

The router (Load Balancer) has radios for BOTH networks, so it can forward traffic between them. But devices on GuestWifi can't directly talk to devices on PrivateWifi.

---

## Conclusion

Networks in Docker are **invisible overlay networks** that containers are attached to, not physical components or zones. The corrected diagram now shows the private network as a **boundary box** containing the isolated components, which is more accurate than showing it as a separate "layer" in the traffic flow.

The Load Balancer is the critical **dual-homed** component that bridges these two network overlays, providing controlled access while maintaining security isolation.
