# Patient Module Multi-Portal API

## 📋 Overview

This is a **production-ready** multi-portal Healthcare API built with NestJS and TypeORM. The API serves three separate portals:

1. **Admin Panel** - Complete management of doctors, diagnostics, appointments, bookings, and users
2. **Patient Panel** - Self-service for appointment booking, diagnostic bookings, and doctor browsing
3. **Doctor Panel** - View and manage appointments, update profile

Each portal has its own authentication, authorization, and endpoints isolated to prevent unauthorized access.

---

## 🏗️ Architecture

### Three Independent Portals

```
Patient Module API
├── Admin Portal (admin-auth)
│   ├── Authentication & Authorization
│   ├── Doctor Management (CRUD)
│   ├── Diagnostic Management (CRUD)
│   ├── Appointment Management (View, Cancel, Reassign)
│   ├── Diagnostic Booking Management
│   ├── User Management
│   └── Role & Permission Management
│
├── Patient Portal (patient)
│   ├── Authentication (Email/Phone Registration & Login)
│   ├── Profile Management (View, Update, Change Password)
│   ├── Appointment Booking & Management
│   ├── Diagnostic Booking
│   ├── Doctor Browsing & Search
│   └── History & Upcoming Appointments/Bookings
│
└── Doctor Portal (doctor)
    ├── Authentication (Login)
    ├── Profile Management (View, Change Password)
    └── Appointment Management (View, Filter by Status & Date)
```

---

## 🔐 Authentication & Authorization

### JWT-based Authentication

Each portal uses its own JWT secret and expiration:

| Portal  | Env Variable         | Default Expiration |
| ------- | -------------------- | ------------------ |
| Admin   | `ADMIN_JWT_SECRET`   | 24 hours           |
| Doctor  | `DOCTOR_JWT_SECRET`  | 7 days             |
| Patient | `PATIENT_JWT_SECRET` | 30 days            |

### Role-Based Access Control (RBAC)

**Admin Portal** uses role-based permissions:

- **SUPER_ADMIN**: Full system access
- **ADMIN**: Standard admin operations
- **SUPPORT**: Limited read access
- **MANAGER**: Appointment & booking management

---

## 📡 API Endpoints

### Admin Portal (`/api/v1/admin-auth`)

#### Authentication

- `POST /login` - Admin login

#### Admin Management

- `POST /create` - Create new admin (SUPER_ADMIN only)
- `GET /all-admin` - List all admins

#### Doctor Management

- `GET /doctors` - List all doctors
- `POST /doctors` - Create new doctor
- `GET /doctors/:id` - Get doctor details
- `PATCH /doctors/:id` - Update doctor
- `DELETE /doctors/:id` - Delete doctor
- `GET /doctors/:id/appointments` - Get doctor's appointments
- `GET /doctors-with-appointments` - List doctors with their appointments

#### Diagnostic Management

- `GET /diagnostics` - List all diagnostics
- `POST /diagnostics` - Create diagnostic
- `GET /diagnostics/:id` - Get diagnostic details
- `PATCH /diagnostics/:id` - Update diagnostic
- `DELETE /diagnostics/:id` - Delete diagnostic
- `PATCH /diagnostics/:id/status` - Toggle diagnostic status
- `POST /diagnostics/import` - Bulk import diagnostics
- `GET /diagnostics/export` - Export diagnostics as CSV

#### Appointment Management

- `GET /appointments` - List all appointments (paginated, filterable)
- `POST /appointments/bulk-status` - Bulk update appointment status
- `GET /appointments/:id` - Get appointment details
- `POST /appointments/:id/cancel` - Cancel appointment
- `PATCH /appointments/:id/reassign` - Reassign appointment to another doctor
- `PATCH /appointments/:id` - Update appointment
- `DELETE /appointments/:id` - Delete appointment

#### Diagnostic Booking Management

- `GET /diagnostic-bookings` - List all bookings (paginated, filterable)
- `POST /diagnostic-bookings/bulk-status` - Bulk update booking status
- `GET /diagnostic-bookings/:id` - Get booking details
- `POST /diagnostic-bookings/:id/cancel` - Cancel booking
- `PATCH /diagnostic-bookings/:id` - Update booking
- `DELETE /diagnostic-bookings/:id` - Delete booking

#### User Management

- `GET /users` - List all users
- `GET /users/:id` - Get user details
- `PATCH /users/:id` - Update user
- `DELETE /users/:id` - Delete user

#### Role & Permission Management

- `GET /roles` - List all roles
- `GET /roles/:role/permissions` - Get role permissions
- `POST /admins/:id/assign-role` - Assign role to admin
- `GET /admins/:id/role` - Get admin's role
- `GET /admins-with-roles` - List admins with their roles

---

### Patient Portal (`/api/v1/patient`)

#### Authentication

- `POST /auth/register-email` - Register with email
- `POST /auth/register-phone` - Register with phone
- `POST /auth/login` - Patient login

#### Profile Management

- `GET /profile` - Get patient profile
- `PATCH /profile` - Update patient profile
- `POST /profile/change-password` - Change password

#### Appointment Management

- `POST /appointments` - Book appointment
- `GET /appointments` - Get patient's appointments (paginated)
- `GET /appointments/upcoming` - Get upcoming appointments
- `GET /appointments/history` - Get appointment history
- `DELETE /appointments/:appointmentId` - Cancel appointment
- `GET /appointments/check-existing` - Check if appointment already exists

#### Diagnostic Booking

- `POST /bookings` - Book diagnostic
- `GET /bookings` - Get patient's bookings (paginated)
- `GET /bookings/upcoming` - Get upcoming bookings
- `GET /bookings/history` - Get booking history
- `DELETE /bookings/:bookingId` - Cancel booking

#### Doctor & Diagnostic Browsing

- `GET /diagnostics` - List available diagnostics (paginated, searchable)
- `GET /doctors` - List all doctors (paginated, searchable, filterable by specialty)
- `GET /doctors/:doctorId` - Get doctor details

---

### Doctor Portal (`/api/v1/doctor`)

#### Authentication

- `POST /auth/login` - Doctor login

#### Profile Management

- `GET /profile` - Get doctor profile
- `POST /profile/change-password` - Change password

#### Appointment Management

- `GET /appointments` - Get all appointments (paginated, filterable by status)
- `GET /appointments/pending` - Get pending appointments
- `GET /appointments/confirmed` - Get confirmed appointments
- `GET /appointments/today` - Get today's appointments
- `GET /appointments/upcoming` - Get upcoming appointments
- `GET /appointments/history` - Get appointment history (paginated)
- `GET /appointments/:appointmentId` - Get appointment details

---

## 🚀 Getting Started

### Prerequisites

- Node.js >= 18.0.0
- npm >= 9.0.0
- MySQL 8.0+

### Installation

```bash
# Install dependencies
npm install

# Create .env file from .env.example
cp .env.example .env

# Update .env with your configuration
```

### Configuration

Update `.env` with your database and JWT secrets:

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASS=your_password
DB_NAME=patient_module_db

ADMIN_JWT_SECRET=generate-strong-secret
DOCTOR_JWT_SECRET=generate-strong-secret
PATIENT_JWT_SECRET=generate-strong-secret

NODE_ENV=development
PORT=3000
```

### Running the Application

```bash
# Development
npm run start:dev

# Production
npm run build
npm run start:prod

# Debug mode
npm run start:debug
```

### Testing

```bash
# Run unit tests
npm test

# Watch mode
npm test:watch

# Coverage
npm test:cov

# E2E tests
npm run test:e2e
```

---

## 📦 Project Structure

```
src/
├── admin_auth/              # Admin portal
│   ├── admin_auth.controller.ts
│   ├── admin_auth.service.ts
│   ├── admin_authGuard.ts
│   ├── decorators/          # Auth decorators
│   ├── dto/                 # Data Transfer Objects
│   ├── entities/            # Database entities
│   ├── enums/               # Roles & Permissions
│   └── services/            # Business logic
│
├── patient/                 # Patient portal
│   ├── patient.controller.ts
│   ├── patient.service.ts
│   ├── guards/              # Patient auth guard
│   ├── decorators/          # Auth decorators
│   ├── dto/                 # DTOs
│   └── entities/            # Database entities
│
├── doctor/                  # Doctor portal
│   ├── doctor.controller.ts
│   ├── doctor.service.ts
│   ├── guards/              # Doctor auth guard
│   ├── dto/                 # DTOs
│   └── entities/            # Database entities
│
├── appointments/            # Appointment management (shared)
├── diagnostics/             # Diagnostic management (shared)
├── diagnostic-booking/      # Diagnostic booking (shared)
├── app.module.ts           # Root module
├── main.ts                 # Application entry point
└── database/               # Database configuration
```

---

## 🔒 Security Features

✅ **Helmet** - HTTP security headers  
✅ **CORS** - Configurable origin-based access  
✅ **JWT Authentication** - Stateless, secure token-based auth  
✅ **Password Hashing** - BCrypt with salt rounds  
✅ **Input Validation** - Class-validator with whitelisting  
✅ **Role-Based Access Control** - Permission-based endpoint access  
✅ **Audit Logging** - Track admin actions  
✅ **Environment Variables** - Sensitive data separation

---

## 🛠️ Production Deployment

### Pre-Deployment Checklist

```bash
# Build for production
npm run build

# Run linting
npm run lint

# Run tests
npm test
npm run test:e2e

# Check environment variables
cat .env
```

### Docker Deployment

Create `Dockerfile`:

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY dist ./dist

EXPOSE 3000

CMD ["node", "dist/main"]
```

Build and run:

```bash
docker build -t patient-api:1.0.0 .
docker run -p 3000:3000 --env-file .env patient-api:1.0.0
```

### Environment for Production

```env
NODE_ENV=production
PORT=3000

# Use strong, randomly generated secrets
ADMIN_JWT_SECRET=generate-with-openssl-rand-hex-32
DOCTOR_JWT_SECRET=generate-with-openssl-rand-hex-32
PATIENT_JWT_SECRET=generate-with-openssl-rand-hex-32

# Database with replication/cluster
DB_HOST=db.production.rds.amazonaws.com
DB_POOL_SIZE=10

# Restricted CORS
CORS_ORIGIN=https://admin.example.com,https://patient.example.com,https://doctor.example.com
```

---

## 📊 Database Schema

### Key Entities

- **Admin** - Admin users with roles and permissions
- **Doctor** - Doctor profiles with specialization
- **Patients** - Patient user profiles
- **Appointment** - Appointment bookings
- **Diagnostic** - Available diagnostic services
- **DiagnosticBooking** - Patient diagnostic bookings
- **AdminAuditLog** - Admin action audit trail

---

## 🐛 Error Handling

All endpoints return consistent error responses:

```json
{
  "statusCode": 400,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "errors": ["email must be an email"]
    }
  ]
}
```

---

## 📝 API Testing

Use Postman or curl to test endpoints. Example:

```bash
# Admin login
curl -X POST http://localhost:3000/api/v1/admin-auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password123"}'

# Patient login
curl -X POST http://localhost:3000/api/v1/patient/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"patient@example.com","password":"password123"}'

# Doctor login
curl -X POST http://localhost:3000/api/v1/doctor/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"doctor@example.com","password":"password123"}'

# Protected endpoint with JWT
curl -X GET http://localhost:3000/api/v1/patient/profile \
  -H "Authorization: Bearer <jwt_token>"
```

---

## 🔄 What Was Removed for Production

- ❌ `app.controller.ts` - Unused generic controller
- ❌ `app.service.ts` - Unused service
- ❌ Unnecessary test configurations
- ❌ Unsafe console.logs (replaced with Logger)
- ❌ CORS origin wildcard `*` (now restricted)
- ❌ Loose validation (now strict)

---

## 📞 Support & Contribution

For issues, feature requests, or contributions, please contact your development team.

---

## 📄 License

UNLICENSED - Internal Use Only

---

**Version:** 1.0.0  
**Last Updated:** January 2026  
**Environment:** Production Ready
