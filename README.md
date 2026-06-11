# ☁️ Cloud Notes App — Amazon RDS Demo

> A production-style full-stack demo for the **AWS Zero to Hero** YouTube series.
> Teaches Amazon RDS the real-infrastructure way: a Node.js + Express API connects to a managed MySQL database, and a React + Tailwind dashboard lets you create, view, and delete notes.

**YouTube channel:** [Madhukar Reddy — @awsandevops](https://youtube.com/@awsandevops)

---

## 📋 Table of Contents

1. [What you'll learn](#-what-youll-learn)
2. [Architecture](#-architecture)
3. [Folder structure](#-folder-structure)
4. [Tech stack](#-tech-stack)
5. [Run with Docker (recommended)](#-run-with-docker-recommended)
6. [Local testing without Docker](#-local-testing-without-docker)
7. [AWS RDS setup](#-aws-rds-setup)
8. [Deploying to EC2](#-deploying-to-ec2)
9. [API reference](#-api-reference)
10. [Security reminders](#-security-reminders)
11. [Troubleshooting](#-troubleshooting)

---

## 🎯 What you'll learn

- How to provision an Amazon RDS MySQL instance
- How a Node.js backend connects to RDS using `mysql2`
- How to use environment variables for credentials (never hardcode!)
- How to expose a clean REST API with Express
- How to build a modern dashboard UI with React + Tailwind
- How to deploy the stack on EC2 and lock down RDS with security groups

---

## 🏗 Architecture

```
                  Internet
                     │ HTTPS (443)
                     ▼
        ┌─────────────────────────────┐
        │  EC2 (Ubuntu 22.04)         │
        │                             │
        │  Host Nginx (SSL termination)│
        │       │                     │       ┌──────────────────┐
        │       ├─▶ frontend (Docker) │       │ Amazon RDS       │
        │       └─▶ backend  (Docker) │──────▶│ MySQL 8.0        │
        │              :5000 (local)  │ 3306  │ Private endpoint │
        └─────────────────────────────┘       └──────────────────┘
```

The browser hits the host's Nginx over HTTPS. Nginx terminates SSL and reverse-proxies to the two Docker containers (both bound to localhost only). The backend container talks to RDS over the private VPC subnet on port 3306.

---

## 📁 Folder structure

```
cloud-notes-app/
├── docker-compose.yml       # Brings up the whole stack
├── .env.example             # Root env file for Docker Compose
│
├── backend/
│   ├── server.js            # Express app + routes
│   ├── db.js                # MySQL connection pool + helpers
│   ├── Dockerfile           # Backend container image
│   ├── .dockerignore
│   ├── package.json
│   ├── .env.example         # Used only for non-Docker local runs
│   └── .gitignore
│
├── frontend/
│   ├── src/
│   │   ├── App.jsx          # Main dashboard component
│   │   ├── main.jsx         # React entry point
│   │   └── index.css        # Tailwind + custom styles
│   ├── public/
│   │   └── cloud.svg        # Favicon
│   ├── Dockerfile           # Multi-stage: builds React, serves with Nginx
│   ├── nginx.conf           # Inside-container Nginx (static files only)
│   ├── .dockerignore
│   ├── index.html
│   ├── package.json
│   ├── vite.config.js       # Proxies /api to backend (dev mode only)
│   ├── tailwind.config.js
│   ├── postcss.config.js
│   └── .gitignore
│
├── deploy/
│   ├── nginx-host.conf      # Production Nginx config for EC2 host
│   └── ec2-setup.sh         # One-shot EC2 provisioning script
│
└── README.md
```

---

## 🛠 Tech stack

| Layer       | Technology                          |
| ----------- | ----------------------------------- |
| Frontend    | React 18 + Vite + Tailwind CSS      |
| Icons       | lucide-react                        |
| Backend     | Node.js + Express                   |
| DB driver   | mysql2 (promise-based)              |
| Database    | Amazon RDS — MySQL 8.0              |
| Config      | dotenv                              |
| Deployment  | EC2 (Amazon Linux 2023 or Ubuntu)   |

---

## 🐳 Run with Docker (recommended)

This is the easiest way — one command, no Node.js install required on your machine.

### Prerequisites

- Docker Desktop (Mac/Windows) or Docker Engine + Docker Compose (Linux) — [install](https://docs.docker.com/get-docker/)
- An Amazon RDS MySQL instance (see [next section](#-aws-rds-setup))

### 1. Configure the environment

From the project root:

```bash
cp .env.example .env
nano .env
```

Fill in your RDS details:

```env
DB_HOST=cloudnotes-db.xxxxx.ap-south-1.rds.amazonaws.com
DB_PORT=3306
DB_USER=admin
DB_PASSWORD=YourStrongPasswordHere
DB_NAME=cloudnotes
```

### 2. Bring up the stack

```bash
docker compose up --build
```

That's it. Docker will:

- Build the backend image (`node:20-alpine` + Express)
- Build the frontend image (multi-stage: React build → Nginx serve)
- Create a private bridge network so frontend can reach backend
- Start both containers

You should see logs like:

```
cloudnotes-backend  | 🚀 Starting Cloud Notes App Backend...
cloudnotes-backend  | ✅ Connected to RDS: cloudnotes-db.****.ap-south-1.rds.amazonaws.com
cloudnotes-backend  | ✅ Notes table ready
cloudnotes-backend  | ✅ Server running on http://localhost:5000
cloudnotes-frontend | Configuration complete; ready for start up
```

Open **http://localhost:3000** in your browser — the dashboard loads, connects to RDS, you're done.

> The backend API is at **http://localhost:5000**. Both ports bind to `127.0.0.1` only, so they're only reachable from your machine. On EC2, host Nginx fronts both behind a single HTTPS endpoint — see [Deploying to EC2](#-deploying-to-ec2-with-your-own-domain--https).

### 3. Useful Docker commands

```bash
# Run in background (detached mode)
docker compose up -d --build

# View logs
docker compose logs -f
docker compose logs -f backend       # backend only

# Stop everything
docker compose down

# Rebuild after code changes
docker compose up --build --force-recreate

# Shell into a container
docker exec -it cloudnotes-backend sh
```

### How it works locally

```
┌─────────────────────────────────────────────────────┐
│  Your machine                                       │
│                                                     │
│  Browser ──▶ http://localhost:3000                  │
│                       │                             │
│                       ▼                             │
│  ┌─────────────────────────┐    ┌────────────────┐  │
│  │ frontend                │    │ backend        │  │      ┌──────────────┐
│  │ (nginx:alpine)          │───▶│ (node:alpine)  │──┼─────▶│ Amazon RDS   │
│  │ 127.0.0.1:3000          │    │ 127.0.0.1:5000 │  │ 3306 │ MySQL 8.0    │
│  │ serves React + /api/*   │    │                │  │      └──────────────┘
│  └─────────────────────────┘    └────────────────┘  │
│                                                     │
│            cloudnotes-net (bridge)                  │
└─────────────────────────────────────────────────────┘
```

- Open `http://localhost:3000` — the frontend container serves the React app and proxies `/api/*` to the backend over the internal Docker network (`backend:5000`).
- Both host ports bind to `127.0.0.1` only — nothing is exposed to your local network.
- On EC2, **host Nginx** sits in front and handles SSL + domain routing, hitting the same two containers.

---

## 💻 Local testing without Docker

Prefer running the services directly with Node? Here's the manual path.

### Prerequisites

- Node.js 18+ ([install](https://nodejs.org/))
- An Amazon RDS MySQL instance (see [next section](#-aws-rds-setup))
- Your laptop's IP added to the RDS security group inbound rules

### 1. Clone & install

```bash
git clone <your-repo-url>
cd cloud-notes-app

# Backend
cd backend
npm install

# Frontend (in a new terminal)
cd ../frontend
npm install
```

### 2. Configure backend

```bash
cd backend
cp .env.example .env
```

Edit `.env` with your RDS details:

```env
DB_HOST=cloudnotes-db.xxxxx.ap-south-1.rds.amazonaws.com
DB_PORT=3306
DB_USER=admin
DB_PASSWORD=YourStrongPasswordHere
DB_NAME=cloudnotes
PORT=5000
```

### 3. Run it

```bash
# Terminal 1 — backend
cd backend
npm start
```

You should see:

```
🚀 Starting Cloud Notes App Backend...
✅ Connected to RDS: cloudnotes-db.****.ap-south-1.rds.amazonaws.com
✅ Notes table ready
✅ Server running on http://localhost:5000
```

```bash
# Terminal 2 — frontend
cd frontend
npm run dev
```

Open **http://localhost:3000** — you should see the dashboard with a green "Connected" badge.

---

## ☁️ AWS RDS setup

### Step 1: Create the RDS instance

1. Open the AWS Console → **RDS** → **Create database**
2. Choose:
   - Engine: **MySQL** (8.0.x)
   - Template: **Free tier** (for the demo)
   - DB instance identifier: `cloudnotes-db`
   - Master username: `admin`
   - Master password: pick a strong one — save it!
3. **Connectivity:**
   - VPC: default
   - Public access: **No** (we'll connect through EC2 — production-safe)
   - For local testing only, you can temporarily set this to **Yes** and add your IP
   - VPC security group: create new, name it `rds-cloudnotes-sg`
4. **Additional configuration:**
   - Initial database name: `cloudnotes`
5. Click **Create database** and wait ~5 minutes.

### Step 2: Configure the security group

Edit `rds-cloudnotes-sg` inbound rules:

| Type       | Protocol | Port | Source                            |
| ---------- | -------- | ---- | --------------------------------- |
| MySQL/Aurora | TCP      | 3306 | The EC2 security group ID         |
| MySQL/Aurora | TCP      | 3306 | Your laptop IP (only for testing) |

**Never** open 3306 to `0.0.0.0/0` in production.

### Step 3: Get the endpoint

RDS → Databases → `cloudnotes-db` → **Connectivity & security** tab. Copy the **Endpoint** (looks like `cloudnotes-db.xxxxx.ap-south-1.rds.amazonaws.com`) into your `.env`.

### Step 4: SQL fallback (if auto-create fails)

The backend will auto-create the `notes` table on startup. If you'd rather create it manually, connect via MySQL client:

```bash
mysql -h cloudnotes-db.xxxxx.ap-south-1.rds.amazonaws.com -u admin -p
```

Then run:

```sql
CREATE DATABASE IF NOT EXISTS cloudnotes;
USE cloudnotes;

CREATE TABLE IF NOT EXISTS notes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 🚀 Deploying to EC2 with your own domain + HTTPS

This is the production-style deployment used in the video. The app runs on `https://www.aws365.shop` with a real Let's Encrypt certificate. Replace `aws365.shop` with your own domain throughout.

### Architecture

```
        ┌──────────────────────────────────────────────────┐
        │  Internet                                        │
        └──────────────────┬───────────────────────────────┘
                           │ HTTPS (443)
                           ▼
        ┌──────────────────────────────────────────────────┐
        │  EC2 Instance (Ubuntu 22.04)                     │
        │                                                  │
        │  Host Nginx ── SSL termination (certbot)         │
        │      │                                           │
        │      ├──▶ 127.0.0.1:3000  ── frontend container  │
        │      └──▶ 127.0.0.1:5000  ── backend container   │
        │                                  │               │
        └──────────────────────────────────┼───────────────┘
                                           │ 3306 (private)
                                           ▼
                                  ┌────────────────┐
                                  │ Amazon RDS     │
                                  │ MySQL 8.0      │
                                  └────────────────┘
```

The host Nginx terminates SSL and reverse-proxies to the containers, which are bound to `127.0.0.1` only — they are never directly reachable from the internet.

### Step 1: Launch EC2

- AMI: **Ubuntu 22.04** (the setup script targets Ubuntu)
- Instance type: `t2.micro` is fine for the demo
- Security group `ec2-cloudnotes-sg`: open **22** (your IP only), **80**, **443**
- **Add this EC2 security group as an inbound source on the RDS security group**
- Allocate an **Elastic IP** and associate it with the instance (so it doesn't change on reboot)

### Step 2: Point your domain at the EC2 box

In **Route 53** (or your DNS provider), create two `A` records pointing at the Elastic IP:

| Record name        | Type | Value                  |
| ------------------ | ---- | ---------------------- |
| `aws365.shop`      | A    | Your EC2 Elastic IP    |
| `www.aws365.shop`  | A    | Your EC2 Elastic IP    |

Wait a couple of minutes and verify:

```bash
dig +short www.aws365.shop
# Should return your EC2 IP
```

Certbot will fail to issue a certificate if DNS isn't pointing correctly yet, so don't skip this step.

### Step 3: Clone the repo and configure

SSH into the EC2 box, then:

```bash
git clone <your-repo-url>
cd cloud-notes-app

cp .env.example .env
nano .env   # Fill in your RDS endpoint and credentials
```

### Step 4: Edit the setup script

Open `deploy/ec2-setup.sh` and change two things at the top:

```bash
EMAIL="your-email@example.com"   # Let's Encrypt notifications go here
# Change DOMAIN and WWW_DOMAIN if not using aws365.shop
```

### Step 5: Run the setup script

```bash
chmod +x deploy/ec2-setup.sh
sudo ./deploy/ec2-setup.sh
```

This installs Docker, Nginx, certbot, brings up the containers, requests an SSL cert covering both `aws365.shop` and `www.aws365.shop`, redirects the apex to www, and enables automatic certificate renewal.

The script is idempotent — safe to run again if something fails halfway.

### Step 6: Visit your site

🎉 **https://www.aws365.shop** — secured with Let's Encrypt SSL, served by host Nginx, app running in Docker, data living in Amazon RDS.

### Verifying the setup

```bash
# Container health
docker compose ps
docker compose logs -f

# Host Nginx
sudo nginx -t                          # config syntax check
sudo systemctl status nginx
sudo tail -f /var/log/nginx/cloudnotes.access.log

# SSL certificate
sudo certbot certificates              # see issued certs
sudo certbot renew --dry-run           # test renewal works
curl -I https://www.aws365.shop        # should return 200 and HSTS header
```

### Updating the app later

```bash
cd ~/cloud-notes-app
git pull
docker compose up -d --build
```

Host Nginx and SSL don't need to be touched. The containers update in place.

### Why this layout (host Nginx + containers)

- **SSL renewal without rebuilding images.** Certbot edits the host Nginx config; the containers don't know or care.
- **Multiple apps on one box.** Add a new server block in `/etc/nginx/sites-available/` for `shop.aws365.shop` or `api.aws365.shop` — same Elastic IP, same SSL workflow.
- **Containers are private.** They bind to `127.0.0.1:3000` and `127.0.0.1:5000`. Only host Nginx can reach them. Nothing on ports 3000 or 5000 is exposed to the internet.
- **Clean separation of concerns.** Nginx does TLS and routing. Docker does app lifecycle. RDS does data.

---

## 📡 API reference

| Method | Endpoint            | Description                          |
| ------ | ------------------- | ------------------------------------ |
| GET    | `/health`           | App liveness + uptime                |
| GET    | `/api/db-status`    | RDS connection info (endpoint masked)|
| GET    | `/api/notes`        | List all notes (newest first)        |
| POST   | `/api/notes`        | Create a note `{ title, content }`   |
| DELETE | `/api/notes/:id`    | Delete by ID                         |

### Example requests

```bash
# Health
curl http://localhost:5000/health

# Create
curl -X POST http://localhost:5000/api/notes \
  -H "Content-Type: application/json" \
  -d '{"title":"Hello RDS","content":"My first note"}'

# List
curl http://localhost:5000/api/notes

# Delete
curl -X DELETE http://localhost:5000/api/notes/1
```

---

## 🔒 Security reminders

These are the rules to drill into viewers:

1. **Keep RDS private.** `Publicly accessible = No`. Always.
2. **Lock the security group.** Allow port 3306 *only* from the EC2 security group ID — never `0.0.0.0/0`.
3. **Never commit `.env`.** It's in `.gitignore` for a reason. Use AWS Secrets Manager or SSM Parameter Store in production.
4. **Rotate the master password.** Don't use the one you typed during creation forever.
5. **Enable encryption at rest** (RDS option) and **enforce SSL in transit** for any real workload.
6. **Backups & Multi-AZ** are off in free tier — turn them on for anything beyond a demo.
7. **IAM database authentication** is a great next-level topic to cover.

---

## 🐛 Troubleshooting

| Symptom                                      | Likely cause                                                          |
| -------------------------------------------- | --------------------------------------------------------------------- |
| `ETIMEDOUT` when starting backend            | Security group doesn't allow your IP or EC2 SG on port 3306           |
| `ER_ACCESS_DENIED_ERROR`                     | Wrong `DB_USER` or `DB_PASSWORD` in `.env`                            |
| `Unknown database 'cloudnotes'`              | You didn't set an initial DB name — create it manually (see SQL above)|
| Dashboard says "Backend unreachable"         | Backend isn't running, or Vite proxy port is wrong                    |
| `ENOTFOUND` on the RDS hostname              | Wrong endpoint in `.env`, or VPC routing issue                        |
| `Notes table ready` never appears            | DB user doesn't have `CREATE TABLE` privilege                         |
| `port is already allocated` on `docker compose up` | Port 80 is taken — stop the other process or change the host port |
| Containers up but UI shows "Disconnected"    | Root `.env` not filled in, or RDS SG doesn't allow EC2 instance       |
| `permission denied` running `docker`         | You're not in the docker group — log out and back in after `usermod`  |
| Code changes not reflecting                  | Rebuild: `docker compose up --build --force-recreate`                 |

---

## 📺 Watch the video

This entire app is built and explained step-by-step in the **AWS Zero to Hero** series.

▶️ **Subscribe:** [youtube.com/@awsandevops](https://youtube.com/@awsandevops)

---

Built with ☁️ by **Madhukar Reddy**.
