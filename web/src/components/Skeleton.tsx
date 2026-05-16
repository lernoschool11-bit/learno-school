'use client';

import React from 'react';
import styles from './Skeleton.module.css';

// ═══════════════════════════════════════════════════════════════
// Skeleton Loading — "خداع البصر"
// ═══════════════════════════════════════════════════════════════
// المستخدم لما يشوف "هيكل" الصفحة وهي بتتحمل، بحس إن التطبيق 
// أسرع بـ 30% من لو شاف دائرة بتلف.
// ═══════════════════════════════════════════════════════════════

interface SkeletonProps {
  /** عدد الصفوف */
  rows?: number;
  /** نوع الهيكل */
  variant?: 'text' | 'card' | 'avatar' | 'stat-card' | 'table-row';
  /** عرض مخصص */
  width?: string;
  /** ارتفاع مخصص */
  height?: string;
}

export function Skeleton({ rows = 1, variant = 'text', width, height }: SkeletonProps) {
  return (
    <div className={styles.wrapper}>
      {Array.from({ length: rows }).map((_, i) => (
        <div
          key={i}
          className={`${styles.skeleton} ${styles[variant]}`}
          style={{ width, height }}
        />
      ))}
    </div>
  );
}

/** هيكل بطاقة الإحصائيات (3 بطاقات) */
export function StatCardsSkeleton() {
  return (
    <div className={styles.statGrid}>
      {[1, 2, 3].map((i) => (
        <div key={i} className={`${styles.skeleton} ${styles.statCard}`}>
          <div className={`${styles.skeleton} ${styles.statNumber}`} />
          <div className={`${styles.skeleton} ${styles.statLabel}`} />
        </div>
      ))}
    </div>
  );
}

/** هيكل جدول (صفوف) */
export function TableSkeleton({ rows = 5 }: { rows?: number }) {
  return (
    <div className={styles.tableWrapper}>
      {/* Header row */}
      <div className={styles.tableRow}>
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className={`${styles.skeleton} ${styles.tableHeader}`} />
        ))}
      </div>
      {/* Data rows */}
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className={styles.tableRow}>
          <div className={`${styles.skeleton} ${styles.tableCell}`} style={{ width: '30%' }} />
          <div className={`${styles.skeleton} ${styles.tableCell}`} style={{ width: '25%' }} />
          <div className={`${styles.skeleton} ${styles.tableCell}`} style={{ width: '20%' }} />
          <div className={`${styles.skeleton} ${styles.tableCell}`} style={{ width: '15%' }} />
        </div>
      ))}
    </div>
  );
}

/** هيكل بطاقة المنشور */
export function PostCardSkeleton({ count = 3 }: { count?: number }) {
  return (
    <div className={styles.postList}>
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className={styles.postCard}>
          <div className={styles.postHeader}>
            <div className={`${styles.skeleton} ${styles.avatar}`} />
            <div className={styles.postMeta}>
              <div className={`${styles.skeleton} ${styles.text}`} style={{ width: '40%' }} />
              <div className={`${styles.skeleton} ${styles.text}`} style={{ width: '25%', height: '0.6rem' }} />
            </div>
          </div>
          <div className={`${styles.skeleton} ${styles.text}`} style={{ width: '100%' }} />
          <div className={`${styles.skeleton} ${styles.text}`} style={{ width: '80%' }} />
          <div className={`${styles.skeleton} ${styles.text}`} style={{ width: '60%' }} />
        </div>
      ))}
    </div>
  );
}

/** هيكل صفحة الداشبورد الكاملة */
export function DashboardSkeleton() {
  return (
    <div className={styles.dashboardSkeleton}>
      {/* Header */}
      <div className={styles.dashHeader}>
        <div>
          <div className={`${styles.skeleton} ${styles.text}`} style={{ width: '250px', height: '1.8rem' }} />
          <div className={`${styles.skeleton} ${styles.text}`} style={{ width: '180px', height: '0.9rem', marginTop: '0.5rem' }} />
        </div>
        <div className={`${styles.skeleton} ${styles.avatar}`} />
      </div>
      {/* Stats */}
      <StatCardsSkeleton />
      {/* Content area */}
      <div className={`${styles.skeleton} ${styles.text}`} style={{ width: '100%', height: '200px', marginTop: '2rem', borderRadius: '12px' }} />
    </div>
  );
}
