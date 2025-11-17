# Travel Management Backend - Docker Deployment

This repository contains the Travel Management System backend (Spring Boot) and Docker configuration to run it with a MySQL database using a Docker volume for persistence.

What I changed here (local):
- Added `Dockerfile` (multi-stage build).
- Added `docker-compose.yml` to run `mysql` + backend, with a named volume `travel_db_data` for DB persistence.
- Added `.dockerignore`.
- Adjusted `pom.xml` to use Java 17 so the project builds with JDK 17.

Build & Run (on your machine)
1. Open PowerShell and change to the project folder:
```powershell
cd 'C:\Users\swara\Downloads\travel-backend-main\travel-backend-main'
```

2. Build the application JAR (local build uses the Maven wrapper):
```powershell
.\mvnw -DskipTests package
```

3. Start the app and MySQL via Docker Compose:
```powershell
docker-compose up --build -d
```

This will:
- Create a `travel-db` MySQL container with a named volume `travel_db_data` mounted at `/var/lib/mysql` (data persists across restarts).
- Build and start the backend container, exposing port `8081`.

If Docker Desktop / Engine is not running, please start it first.

Manual Docker commands (without compose)
```powershell
# create network and volume
docker network create travelnet
docker volume create travel_db_data

# run MySQL
docker run -d --name travel-db --network travelnet `
  -e MYSQL_ROOT_PASSWORD=root `
  -e MYSQL_DATABASE=travelmanagement `
  -v travel_db_data:/var/lib/mysql `
  -p 3306:3306 `
  mysql:8.0

# build backend image
docker build -t travel-backend:latest .

# run backend
docker run -d --name travel-backend --network travelnet `
  -e SPRING_DATASOURCE_URL=jdbc:mysql://travel-db:3306/travelmanagement `
  -e SPRING_DATASOURCE_USERNAME=root `
  -e SPRING_DATASOURCE_PASSWORD=root `
  -p 8081:8081 `
  travel-backend:latest
```

Test persistence:
- POST `http://localhost:8081/auth/signup` with JSON body `{"username":"demo","email":"demo@example.com","password":"pass"}`
- Restart containers:
```powershell
docker restart travel-backend
docker restart travel-db
```
- Try login: POST `http://localhost:8081/auth/login` with `{"username":"demo","password":"pass"}` — if login still works, persistence is OK.

Git: commit & push
```powershell
git add Dockerfile docker-compose.yml .dockerignore README.md pom.xml
git commit -m "Add Docker deployment files and README; set Java version to 17"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

Submission
- After pushing your repo, copy the repo URL and submit it to: `https://tinyurl.com/endsemsubmission`.

Limitations I hit here
- This environment doesn't have Docker engine running, so I couldn't build or run Docker images/containers here and couldn't push to your remote GitHub repository from this environment.

If you want, I can:
- Adjust the project to use an embedded H2 file database and mount a local folder as a volume instead of MySQL.
- Or keep MySQL and help with any credential/remote push steps interactively.