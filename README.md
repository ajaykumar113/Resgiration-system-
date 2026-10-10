# Smart Registration Portal - Backend API

This is the Python Flask REST API backend for the **Smart Registration Portal**.

## Tech Stack
- **Python 3.14**
- **Flask** & **Flask-CORS**
- **Flask-SQLAlchemy**
- **PyMySQL** & **SQLite (fallback support)**
- **Werkzeug Security** (Password Hashing)
- **PyJWT** (JSON Web Tokens)

## Setup & Running Instructions

### 1. Install Dependencies
```powershell
python -m pip install -r requirements.txt
```

### 2. Configure Environment Variables
Copy `.env.example` to `.env`:
```powershell
Copy-Item .env.example .env
```
Ensure your MySQL database credentials match in `.env`:
```env
DATABASE_URL=mysql+pymysql://root:yourpassword@localhost:3306/registration_portal
```

### 3. Run Backend Server
```powershell
python app.py
```
The backend server runs on `http://localhost:5000`.

### 4. Run Automated Backend Tests
```powershell
python -m unittest discover -s tests
```
