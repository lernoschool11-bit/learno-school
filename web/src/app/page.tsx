'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { ArrowRight, BookOpen, Users, Sparkles, ShieldCheck, Globe, ChevronDown } from 'lucide-react';
import styles from './landing.module.css';

export default function LandingPage() {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 50);
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <div className={styles.wrapper}>
      {/* Navigation */}
      <nav className={`${styles.nav} ${scrolled ? styles.navScrolled : ''}`}>
        <div className={styles.navContainer}>
          <div className={styles.logo}>
            <span className={styles.l}>L</span>earno
          </div>
          <div className={styles.navLinks}>
            <a href="#features">المميزات</a>
            <a href="#about">عن المنصة</a>
            <a href="#stats">إحصائيات</a>
          </div>
          <div className={styles.navActions}>
            <Link href="/login" className={styles.loginBtn}>تسجيل الدخول</Link>
            <Link href="/register" className={styles.registerBtn}>ابدأ مجاناً</Link>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className={styles.hero}>
        <div className={styles.heroContent}>
          <div className={styles.badge}>
            <Sparkles size={14} />
            <span>مستقبل التعليم الرقمي في الأردن</span>
          </div>
          <h1 className={styles.title}>
            أعد تعريف تجربتك <br />
            <span>التعليمية مع Learno</span>
          </h1>
          <p className={styles.description}>
            المنصة التعليمية المتكاملة التي تجمع المعلمين، الطلاب، وأولياء الأمور في مساحة رقمية ذكية تعتمد على التفاعل والذكاء الاصطناعي.
          </p>
          <div className={styles.heroActions}>
            <Link href="/register" className={styles.primaryCta}>
              ابدأ الآن مجاناً <ArrowRight size={20} />
            </Link>
            <Link href="#features" className={styles.secondaryCta}>
              اكتشف المميزات
            </Link>
          </div>
        </div>
        
        <div className={styles.heroImageContainer}>
          <div className={`${styles.floatingCard} glass`}>
            <Users className={styles.cardIcon} />
            <div>
              <h3>+١٠,٠٠٠</h3>
              <p>طالب نشط</p>
            </div>
          </div>
          <div className={`${styles.floatingCard} ${styles.card2} glass`}>
            <BookOpen className={styles.cardIcon} color="var(--secondary)" />
            <div>
              <h3>+٥٠٠</h3>
              <p>مدرسة مشتركة</p>
            </div>
          </div>
          <div className={styles.heroMainImage}>
             <div className={styles.glow} />
             {/* Abstract UI representation */}
             <div className={styles.uiMockup + " glass"}>
                <div className={styles.uiHeader} />
                <div className={styles.uiContent}>
                   <div className={styles.uiLine} />
                   <div className={styles.uiLine} style={{width: '60%'}} />
                   <div className={styles.uiCircle} />
                </div>
             </div>
          </div>
        </div>

        <div className={styles.scrollIndicator}>
          <ChevronDown size={24} />
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className={styles.features}>
        <div className={styles.sectionHeader}>
          <h2>لماذا يختار الجميع Learno؟</h2>
          <p>نقدم حلولاً تعليمية متكاملة مصممة خصيصاً لتلبية احتياجات المدارس الحديثة.</p>
        </div>
        
        <div className={styles.featuresGrid}>
          <div className={`${styles.featureCard} glass`}>
            <div className={styles.featureIcon}><ShieldCheck /></div>
            <h3>بيئة آمنة</h3>
            <p>خصوصية تامة لبيانات الطلاب والمعلمين مع أنظمة تشفير متطورة.</p>
          </div>
          <div className={`${styles.featureCard} glass`}>
            <div className={styles.featureIcon} style={{color: 'var(--secondary)'}}><Globe /></div>
            <h3>تواصل عالمي</h3>
            <p>اربط صفك الدراسي بالعالم وشارك المنشورات والأنشطة التعليمية بسهولة.</p>
          </div>
          <div className={`${styles.featureCard} glass`}>
            <div className={styles.featureIcon} style={{color: 'var(--accent)'}}><Sparkles /></div>
            <h3>ذكاء اصطناعي</h3>
            <p>مساعد تعليمي ذكي يساعدك في الإجابة على الأسئلة وتطوير مهاراتك.</p>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className={styles.footer}>
        <div className={styles.footerContent}>
          <div className={styles.footerBrand}>
            <div className={styles.logo}><span className={styles.l}>L</span>earno</div>
            <p>نحو بيئة تعليمية ذكية ومتكاملة.</p>
          </div>
          <div className={styles.footerLinks}>
            <div className={styles.linkGroup}>
              <h4>الروابط</h4>
              <Link href="/login">الدخول</Link>
              <Link href="/register">التسجيل</Link>
            </div>
            <div className={styles.linkGroup}>
              <h4>تواصل معنا</h4>
              <span>info@learno.edu</span>
              <span>+962 700 000 000</span>
            </div>
          </div>
        </div>
        <div className={styles.footerBottom}>
          <p>© {new Date().getFullYear()} Learno Platform. جميع الحقوق محفوظة.</p>
        </div>
      </footer>
    </div>
  );
}
