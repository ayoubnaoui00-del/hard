# HRD-6: Authentication Test Report & Postman Documentation

**Project:** Hard Backend API  
**Sprint:** Sprint 1 — Backend Setup & Auth  
**Tasks Covered:**
* **HRD-5:** Task 1.4 — Auth Controller (Register & Login)
* **HRD-6:** Task 1.5 — Test Auth Locally

---

## 🎯 Acceptance Criteria Verification Checklist

| Criteria | Expected Behavior | Actual Result | Status |
| :--- | :--- | :--- | :---: |
| **Register Valid User** | Returns `201 Created`, user profile (without password), `accessToken`, and `refreshToken`. | Returned `201 Created` with sanitized user object and 15m/7d tokens. | **PASS** |
| **Register Duplicate Email** | Returns `409 Conflict` with clear error message. | Returned `409 Conflict`: "An account with this email already exists". | **PASS** |
| **Register Duplicate Username** | Returns `409 Conflict` with clear error message. | Returned `409 Conflict`: "Username is already taken". | **PASS** |
| **Register Validation (Short Pwd)** | Rejects passwords `< 6` characters with `400 Bad Request`. | Returned `400 Bad Request`: "Password must be at least 6 characters long". | **PASS** |
| **Register Validation (Short User)** | Rejects usernames `< 3` characters with `400 Bad Request`. | Returned `400 Bad Request`: "Username must be at least 3 characters long". | **PASS** |
| **Login Valid User** | Returns `200 OK`, updates `lastActiveAt`, returns tokens. | Returned `200 OK` with valid tokens and updated timestamp. | **PASS** |
| **Login Incorrect Password** | Returns `401 Unauthorized` with generic message. | Returned `401 Unauthorized`: "Invalid email or password". | **PASS** |
| **Login Non-Existent User** | Returns `401 Unauthorized` with generic message. | Returned `401 Unauthorized`: "Invalid email or password". | **PASS** |
| **Protected Route Without Token** | `GET /auth/me` without `Authorization` returns `401`. | Returned `401 Unauthorized`: "Access denied. No token provided.". | **PASS** |
| **Protected Route Invalid Token** | `GET /auth/me` with bad token returns `401`. | Returned `401 Unauthorized` with code `TOKEN_INVALID`. | **PASS** |
| **Protected Route With Token** | `GET /auth/me` with `Bearer <accessToken>` returns user profile. | Returned `200 OK` with user profile without exposing password. | **PASS** |
| **Refresh Token Valid** | `POST /auth/refresh` issues new access & refresh tokens. | Returned `200 OK`, verified new access token grants route access. | **PASS** |
| **Refresh Token Invalid/Missing** | `POST /auth/refresh` with bad token returns `401`. | Returned `401 Unauthorized` with code `REFRESH_TOKEN_INVALID`. | **PASS** |
| **Logout** | `POST /auth/logout` returns `200 OK`. | Returned `200 OK`: "Logged out successfully". | **PASS** |

---

## 📦 Postman Deliverables

Two ready-to-import files have been added to the [`postman/`](file:///c:/Users/user/Desktop/projects/Hard/postman/) directory:

1. **[`postman/Hard_Auth_API.postman_collection.json`](file:///c:/Users/user/Desktop/projects/Hard/postman/Hard_Auth_API.postman_collection.json)**
   * Contains all 9 endpoints/test requests.
   * Includes automated JavaScript test scripts (`pm.test`, `pm.expect`).
   * Automatically persists `accessToken` and `refreshToken` into collection variables upon successful register or login.

2. **[`postman/Hard_Local_Environment.postman_environment.json`](file:///c:/Users/user/Desktop/projects/Hard/postman/Hard_Local_Environment.postman_environment.json)**
   * Pre-configured environment pointing to `http://localhost:3000`.

### How to Import & Run in Postman:
1. Open Postman $\rightarrow$ Click **Import** $\rightarrow$ Select `Hard_Auth_API.postman_collection.json`.
2. Start the local server:
   ```bash
   npm run dev
   ```
3. Run the collection using the **Collection Runner** in Postman:
   * All 9 requests run sequentially with **100% assertions passing**.

---

## 🧪 Automated Unit & Integration Suite (`tests/auth.test.js`)

Executed with Node's native test runner (`node --test`) against the live PostgreSQL database:

```text
▶ Authentication API (HRD-5 & HRD-6)
  ▶ POST /auth/register
    ✔ should fail with 400 if required fields are missing
    ✔ should fail with 400 if username is shorter than 3 characters
    ✔ should fail with 400 if password is shorter than 6 characters
    ✔ should register a valid user successfully with 201
    ✔ should fail with 409 if registering duplicate email
    ✔ should fail with 409 if registering duplicate username
  ✔ POST /auth/register
  ▶ POST /auth/login
    ✔ should fail with 400 when missing email or password
    ✔ should fail with 401 when using wrong password
    ✔ should fail with 401 when email does not exist
    ✔ should successfully log in with valid credentials
  ✔ POST /auth/login
  ▶ Protected Route: GET /auth/me
    ✔ should return 401 when Authorization header is missing
    ✔ should return 401 when token is invalid
    ✔ should return 200 and user profile when valid token provided
  ✔ Protected Route: GET /auth/me
  ▶ POST /auth/refresh
    ✔ should fail with 400 when refreshToken is missing
    ✔ should fail with 401 when refreshToken is invalid
    ✔ should generate a new accessToken with valid refreshToken
  ✔ POST /auth/refresh
  ▶ POST /auth/logout
    ✔ should successfully log out with 200
  ✔ POST /auth/logout
✔ Authentication API (HRD-5 & HRD-6) (1145.4616ms)
ℹ tests 17
ℹ suites 6
ℹ pass 17
ℹ fail 0
```

---

## 🔗 Jira Status
* **[HRD-5](https://ayoubnaoui00.atlassian.net/browse/HRD-5)**: Task 1.4: Auth Controller (Register & Login) $\rightarrow$ **Done**
* **[HRD-6](https://ayoubnaoui00.atlassian.net/browse/HRD-6)**: Task 1.5: Test Auth Locally $\rightarrow$ **Done**
