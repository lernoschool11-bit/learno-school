import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Learno | المنصة التعليمية الذكية",
  description: "منصة تعليمية متطورة تهدف إلى ربط المعلمين والطلاب وأولياء الأمور في بيئة رقمية تفاعلية وسهلة الاستخدام.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ar" dir="rtl">
      <body>
        <main className="min-h-screen">
          {children}
        </main>
      </body>
    </html>
  );
}
