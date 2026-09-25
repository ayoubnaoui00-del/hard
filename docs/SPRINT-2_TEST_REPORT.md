# Sprint 2 Test Report & Deliverables Verification

**Project:** Hard Backend API  
**Sprint:** Sprint 2 — Core Features (Exercises, Workouts & Achievements)  
**Epic:** [HRD-7](https://ayoubnaoui00.atlassian.net/browse/HRD-7)  
**Date:** 2026-09-24  

---

## 🎯 Tasks Covered & Jira Status

| Issue Key | Summary | Status |
| :--- | :--- | :---: |
| **[HRD-7](https://ayoubnaoui00.atlassian.net/browse/HRD-7)** | **Sprint 2: Core Features - Exercises & Logging (Week 2)** | **Done** |
| **[HRD-8](https://ayoubnaoui00.atlassian.net/browse/HRD-8)** | Task 2.1: Exercise Database Seed | **Done** |
| **[HRD-9](https://ayoubnaoui00.atlassian.net/browse/HRD-9)** | Task 2.2: Exercise Controller | **Done** |
| **[HRD-10](https://ayoubnaoui00.atlassian.net/browse/HRD-10)** | Task 2.3: Workout Controller (CRUD) | **Done** |
| **[HRD-11](https://ayoubnaoui00.atlassian.net/browse/HRD-11)** | Task 2.4: Achievement System Seed & Logic | **Done** |
| **[HRD-12](https://ayoubnaoui00.atlassian.net/browse/HRD-12)** | [Merged into HRD-11] Achievement System | **Done** |

---

## 🧪 Automated Test Suite Results (`tests/sprint2.test.js`)

Executed with Node's native test runner against the live PostgreSQL database:

```text
▶ Sprint 2: Core Features — Exercises, Workouts & Achievements (HRD-8, HRD-9, HRD-10, HRD-11)
  ▶ Exercise Catalog API (HRD-9)
    ✔ GET /exercises should return paginated list of exercises
    ✔ GET /exercises?muscle=Chest should filter by muscle group
    ✔ GET /exercises?search=press should search exercises by keyword
    ✔ GET /exercises/:id should return details for a valid UUID
    ✔ GET /exercises/:id should return 404 for non-existent exercise
  ✔ Exercise Catalog API (HRD-9)
  ▶ Workout Controller & CRUD (HRD-10)
    ✔ POST /workouts should reject unauthenticated requests with 401
    ✔ POST /workouts should log a workout, calculate totalVolume, and update streak
    ✔ GET /workouts should return user workout history with pagination
    ✔ GET /workouts/:id should return single workout details
    ✔ PUT /workouts/:id should update workout and recalculate totalVolume
    ✔ DELETE /workouts/:id should remove workout and cascade delete exercises
  ✔ Workout Controller & CRUD (HRD-10)
  ▶ Achievement System (HRD-11)
    ✔ GET /achievements should reject unauthorized requests with 401
    ✔ GET /achievements should return user achievements and full catalog
  ✔ Achievement System (HRD-11)
✔ Sprint 2: Core Features — Exercises, Workouts & Achievements (HRD-8, HRD-9, HRD-10, HRD-11) (286.9609ms)
ℹ tests 14
ℹ suites 4
ℹ pass 14
ℹ fail 0
```

---

## 🛡️ Regression Verification (`tests/auth.test.js`)

Executed Sprint 1 authentication suite to ensure zero regressions:

```text
✔ Authentication API (HRD-5 & HRD-6) (271.2999ms)
ℹ tests 17
ℹ suites 6
ℹ pass 17
ℹ fail 0
```
