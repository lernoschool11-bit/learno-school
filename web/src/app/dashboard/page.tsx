'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import api from '@/lib/api';
import { LayoutDashboard, Users, FileText, Settings, LogOut } from 'lucide-react';

export default function Dashboard() {
  const [user, setUser] = useState<any>(null);
  const router = useRouter();

  useEffect(() => {
    const fetchProfile = async () => {
      try {
        const response = await api.get('/auth/profile');
        setUser(response.data);
      } catch (err) {
        router.push('/login');
      }
    };
    fetchProfile();
  }, [router]);

  const handleLogout = () => {
    localStorage.clear();
    router.push('/login');
  };

  if (!user) return <div className="min-h-screen flex items-center justify-center">جاري التحميل...</div>;

  return (
    <div className="min-h-screen flex">
      {/* Sidebar Placeholder */}
      <aside className="w-64 glass m-4 flex flex-col gap-8 p-6">
        <div className="text-2xl font-bold text-primary">Learno</div>
        <nav className="flex flex-col gap-4">
          <button className="flex items-center gap-3 text-primary"><LayoutDashboard size={20} /> الرئيسية</button>
          <button className="flex items-center gap-3 text-text-secondary"><Users size={20} /> الطلاب</button>
          <button className="flex items-center gap-3 text-text-secondary"><FileText size={20} /> المنشورات</button>
          <button className="flex items-center gap-3 text-text-secondary"><Settings size={20} /> الإعدادات</button>
        </nav>
        <button onClick={handleLogout} className="mt-auto flex items-center gap-3 text-secondary"><LogOut size={20} /> خروج</button>
      </aside>

      {/* Main Content */}
      <main className="flex-1 p-8">
        <header className="flex justify-between items-center mb-12">
          <div>
            <h1 className="text-3xl font-bold mb-2">أهلاً بك، {user.fullName} 👋</h1>
            <p className="text-text-secondary">نتمنى لك يوماً دراسياً ممتعاً في {user.school || 'مدرستك'}</p>
          </div>
          <div className="w-12 h-12 rounded-full glass flex items-center justify-center font-bold">
            {user.fullName[0]}
          </div>
        </header>

        <div className="grid grid-cols-3 gap-6">
          <div className="glass p-6 h-40 flex flex-col justify-center items-center text-center">
            <div className="text-4xl font-bold text-primary mb-2">١٢</div>
            <div className="text-sm text-text-secondary">المنشورات الجديدة</div>
          </div>
          <div className="glass p-6 h-40 flex flex-col justify-center items-center text-center">
            <div className="text-4xl font-bold text-secondary mb-2">٥</div>
            <div className="text-sm text-text-secondary">تنبيهات عاجلة</div>
          </div>
          <div className="glass p-6 h-40 flex flex-col justify-center items-center text-center">
            <div className="text-4xl font-bold text-accent mb-2">٨٥٪</div>
            <div className="text-sm text-text-secondary">نسبة الحضور اليوم</div>
          </div>
        </div>
      </main>

      <style jsx>{`
        .flex { display: flex; }
        .flex-col { flex-direction: column; }
        .flex-1 { flex: 1; }
        .min-h-screen { min-height: 100vh; }
        .w-64 { width: 16rem; }
        .m-4 { margin: 1rem; }
        .p-6 { padding: 1.5rem; }
        .p-8 { padding: 2rem; }
        .gap-8 { gap: 2rem; }
        .gap-4 { gap: 1rem; }
        .gap-6 { gap: 1.5rem; }
        .gap-3 { gap: 0.75rem; }
        .font-bold { font-weight: bold; }
        .text-2xl { font-size: 1.5rem; }
        .text-3xl { font-size: 1.875rem; }
        .text-4xl { font-size: 2.25rem; }
        .text-sm { font-size: 0.875rem; }
        .mb-2 { margin-bottom: 0.5rem; }
        .mb-12 { margin-bottom: 3rem; }
        .mt-auto { margin-top: auto; }
        .text-primary { color: var(--primary); }
        .text-secondary { color: var(--secondary); }
        .text-accent { color: var(--accent); }
        .text-text-secondary { color: var(--text-secondary); }
        .grid { display: grid; }
        .grid-cols-3 { grid-template-columns: repeat(3, minmax(0, 1fr)); }
        .items-center { align-items: center; }
        .justify-center { justify-content: center; }
        .justify-between { justify-content: space-between; }
        .text-center { text-align: center; }
        .h-40 { height: 10rem; }
        .w-12 { width: 3rem; }
        .h-12 { height: 3rem; }
        .rounded-full { border-radius: 9999px; }
      `}</style>
    </div>
  );
}
