# OwlBoard
Main repository for the OwlBoard project - a collaborative digital whiteboard platform.

## Organization Repositories

This is the main repository that orchestrates the entire OwlBoard ecosystem. Below are links to all the repositories in the OwlBoard organization:

### 🖥️ Frontend
- **[Desktop_Front_End](https://github.com/OwlBoard/Desktop_Front_End)** - Repository for the web front end (JavaScript)
- **[Mobile_Front_End](https://github.com/OwlBoard/Mobile_Front_End)** - Repository for the mobile front end (Dart)

### ⚙️ Services
- **[User_Service](https://github.com/OwlBoard/User_Service)** - User management service (Python)
- **[Canvas_Service](https://github.com/OwlBoard/Canvas_Service)** - Canvas/whiteboard service (Dockerfile)
- **[Comments_Service](https://github.com/OwlBoard/Comments_Service)** - Comments and collaboration service (Dockerfile)

## Getting Started

This main repository contains the Docker Compose configuration to run the entire OwlBoard system. All required repositories are included as Git submodules for easy setup.

## Instructions for deploying the system locally

   
1. Clone this repository with submodules:
   ```bash
   git clone --recursive https://github.com/OwlBoard/OwlBoard.git
   ```

2. Update all submodules to their latest versions with:
   ```bash
   git submodule update --remote --recursive
   ```
3. Start all services using Docker Compose:
   ```bash
   docker-compose up --build
   ```

4. Access the application through the configured ports:
   
   
    - User Service: `localhost:5000/docs`
    - Comments Service: `localhost:8001/docs`
    - Chat Service: `localhost:8002/docs`
    - Canvas Service: `localhost:8080/docs`
    - Desktop Frontend: `localhost:3002`
    - Mobile Frontend: `localhost:3001`
    - API Gateway: `localhost:3000`
