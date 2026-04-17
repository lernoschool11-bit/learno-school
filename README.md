# 🎓 Learno: Multi-School Educational Platform

**Learno** is a premium, multi-tenant social and educational ecosystem designed specifically for modern schools. It provides a secure, high-fidelity environment where students, teachers, and principals can interact, share resources, and manage school communities with precision.

## 🛡️ Multi-School Security & Architecture
Unlike standard social platforms, Learno implements a strict **Multi-Tenant Architecture**:
- **Isolated Communities**: Each school has its own private "Digital Campus." Posts and users are strictly bound to their respective `schoolId`.
- **Principal Oversight**: School admins (Principals) have exclusive moderation capabilities within their institution.
- **Dynamic Teacher Codes**: Secure registration workflow using principal-managed rotation codes.

## 🚀 Technology Stack
- **Frontend**: Flutter (3.x) with a luxury OLED-centric Pulse UI.
- **Backend**: Node.js & Express (TypeScript).
- **Database**: PostgreSQL with Prisma ORM for type-safe management.
- **Real-Time**: Socket.io for notifications and community interaction.
- **AI Integration**: Custom Gemini AI integrations for educational assistance.

## 📋 Core Administrative Capabilities
- **Access Management**: Principal-driven rotation of teacher registration codes.
- **Content Moderation**: Global "Principal View" to delete sensitive or inappropriate content within the school feed.
- **User Governance**: Capability to suspend or remove user accounts belonging to the managed school.
- **Branding**: Dynamic UI scaling that reflects the school's identity upon login.

## 🛠️ Setup & Installation

### Backend
1. `cd backend`
2. `npm install`
3. Configure your `.env` (DATABASE_URL, JWT_SECRET).
4. `npx prisma db push`
5. `npm run dev`

### Frontend (Flutter)
1. `cd frontend`
2. `flutter pub get`
3. `flutter run`

---
*Developed with excellence for the next generation of Jordanian education.*
