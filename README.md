# OwlBoard
Main repository for the OwlBoard project - a collaborative digital whiteboard platform.

## Organization Repositories

This is the main repository that orchestrates the entire OwlBoard ecosystem. Below are links to all the repositories in the OwlBoard organization:

### 🖥️ Frontend
- **[Desktop_Front_End](https://github.com/OwlBoard/Desktop_Front_End)** - Repository for the web front end (JavaScript)

### ⚙️ Services
- **[User_Service](https://github.com/OwlBoard/User_Service)** - User management service (Python)
- **[Canvas_Service](https://github.com/OwlBoard/Canvas_Service)** - Canvas/whiteboard service (Dockerfile)
- **[Comments_Service](https://github.com/OwlBoard/Comments_Service)** - Comments and collaboration service (Dockerfile)

### 🗄️ Databases
- **[User_Service_Database](https://github.com/OwlBoard/User_Service_Database)** - Relational database for the User Service
- **[Comments_Service_Database](https://github.com/OwlBoard/Comments_Service_Database)** - Non-Relational database for the user comments service

### 📝 Templates & Resources
- **[Templates](https://github.com/OwlBoard/Templates)** - Templates repository

## Getting Started

This main repository contains the Docker Compose configuration to run the entire OwlBoard system. To get started:

1. Clone this repository and the required service repositories
2. Run `docker-compose up` to start all services
3. Access the application through the configured ports

For more detailed information about each component, please visit the individual repository links above.
