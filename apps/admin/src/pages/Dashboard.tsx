import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { getStats } from '../services/api';
import {
  Users,
  Briefcase,
  CreditCard,
  ShieldCheck,
  TrendingUp,
  Clock,
  CheckCircle,
  XCircle,
  ArrowRight,
} from 'lucide-react';

export default function Dashboard() {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getStats()
      .then(setStats)
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="w-8 h-8 border-3 border-primary-200 border-t-primary-500 rounded-full animate-spin" />
      </div>
    );
  }

  if (!stats) return <p className="text-warm-500">Failed to load dashboard data.</p>;

  const customers = stats.users?.byRole?.CUSTOMER || 0;
  const workers = stats.users?.byRole?.WORKER || 0;
  const openJobs = stats.jobs?.byStatus?.OPEN || 0;
  const inProgressJobs = stats.jobs?.byStatus?.IN_PROGRESS || 0;
  const completedJobs = stats.jobs?.byStatus?.COMPLETED || 0;
  const cancelledJobs = stats.jobs?.byStatus?.CANCELLED || 0;
  const revenue = stats.payments?.revenue || 0;
  const pendingVerifications = stats.pendingVerification || 0;
  const recentJobs = stats.recentJobs || [];
  const monthlyRevenue = stats.monthlyRevenue || [];

  const statCards = [
    {
      label: 'Total Users',
      value: stats.users?.total || 0,
      sub: `${customers} customers, ${workers} workers`,
      icon: Users,
      color: 'bg-blue-50 text-blue-600',
      link: '/users',
    },
    {
      label: 'Total Jobs',
      value: stats.jobs?.total || 0,
      sub: `${openJobs} open, ${inProgressJobs} in progress`,
      icon: Briefcase,
      color: 'bg-green-50 text-green-600',
      link: '/jobs',
    },
    {
      label: 'Revenue',
      value: `Rs. ${revenue.toLocaleString()}`,
      sub: `${stats.payments?.total || 0} total payments`,
      icon: CreditCard,
      color: 'bg-primary-50 text-primary-700',
      link: '/payments',
    },
    {
      label: 'Pending Verifications',
      value: pendingVerifications,
      sub: 'Workers awaiting review',
      icon: ShieldCheck,
      color: 'bg-orange-50 text-orange-600',
      link: '/verification',
    },
  ];

  const maxRevenue = Math.max(...monthlyRevenue.map((m: any) => m.revenue), 1);

  return (
    <div className="space-y-6">
      {/* Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        {statCards.map((card) => {
          const Icon = card.icon;
          return (
            <Link
              key={card.label}
              to={card.link}
              className="bg-white rounded-xl border border-warm-300 p-5 hover:shadow-md transition-shadow"
            >
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-sm text-warm-500">{card.label}</p>
                  <p className="text-2xl font-bold text-warm-800 mt-1">
                    {card.value}
                  </p>
                  <p className="text-xs text-warm-400 mt-1">{card.sub}</p>
                </div>
                <div className={`p-2.5 rounded-lg ${card.color}`}>
                  <Icon size={20} />
                </div>
              </div>
            </Link>
          );
        })}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Monthly Revenue Chart */}
        <div className="bg-white rounded-xl border border-warm-300 p-5">
          <div className="flex items-center gap-2 mb-4">
            <TrendingUp size={18} className="text-warm-400" />
            <h3 className="font-semibold text-warm-800">Monthly Revenue</h3>
          </div>
          {monthlyRevenue.length > 0 ? (
            <div className="flex items-end gap-2 h-48">
              {monthlyRevenue.map((m: any) => (
                <div key={m.month} className="flex-1 flex flex-col items-center gap-1">
                  <span className="text-xs text-warm-500">
                    Rs.{Math.round(m.revenue).toLocaleString()}
                  </span>
                  <div
                    className="w-full bg-primary-500 rounded-t-md min-h-[4px] transition-all"
                    style={{
                      height: `${(m.revenue / maxRevenue) * 160}px`,
                    }}
                  />
                  <span className="text-xs text-warm-400">{m.month}</span>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-sm text-warm-400 text-center py-16">No revenue data yet</p>
          )}
        </div>

        {/* Recent Jobs */}
        <div className="bg-white rounded-xl border border-warm-300 p-5">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <Clock size={18} className="text-warm-400" />
              <h3 className="font-semibold text-warm-800">Recent Jobs</h3>
            </div>
            <Link
              to="/jobs"
              className="text-sm text-primary-600 hover:text-primary-700 flex items-center gap-1"
            >
              View all <ArrowRight size={14} />
            </Link>
          </div>
          <div className="space-y-3">
            {recentJobs.map((job: any) => (
              <div
                key={job.id}
                className="flex items-center justify-between py-2 border-b border-warm-200 last:border-0"
              >
                <div className="min-w-0">
                  <p className="text-sm font-medium text-warm-800 truncate">
                    {job.title}
                  </p>
                  <p className="text-xs text-warm-400">
                    {job.category?.name} &middot;{' '}
                    {new Date(job.createdAt).toLocaleDateString()}
                  </p>
                </div>
                <StatusBadge status={job.status} />
              </div>
            ))}
            {recentJobs.length === 0 && (
              <p className="text-sm text-warm-400 text-center py-4">No jobs yet</p>
            )}
          </div>
        </div>
      </div>

      {/* Job Status Overview */}
      <div className="bg-white rounded-xl border border-warm-300 p-5">
        <h3 className="font-semibold text-warm-800 mb-4">Job Status Overview</h3>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
          <StatusCard icon={Clock} label="Open" value={openJobs} color="text-blue-600 bg-blue-50" />
          <StatusCard icon={TrendingUp} label="In Progress" value={inProgressJobs} color="text-primary-700 bg-primary-50" />
          <StatusCard icon={CheckCircle} label="Completed" value={completedJobs} color="text-green-600 bg-green-50" />
          <StatusCard icon={XCircle} label="Cancelled" value={cancelledJobs} color="text-red-600 bg-red-50" />
        </div>
      </div>
    </div>
  );
}

function StatusCard({ icon: Icon, label, value, color }: { icon: any; label: string; value: number; color: string }) {
  return (
    <div className={`p-4 rounded-lg ${color}`}>
      <Icon size={20} className="mb-2" />
      <p className="text-2xl font-bold">{value}</p>
      <p className="text-sm opacity-75">{label}</p>
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const styles: Record<string, string> = {
    OPEN: 'bg-blue-100 text-blue-700',
    APPLICATIONS_RECEIVED: 'bg-cyan-100 text-cyan-700',
    ASSIGNED: 'bg-primary-100 text-primary-800',
    IN_PROGRESS: 'bg-yellow-100 text-yellow-700',
    COMPLETED: 'bg-green-100 text-green-700',
    REVIEWING: 'bg-purple-100 text-purple-700',
    CLOSED: 'bg-warm-200 text-warm-700',
    CANCELLED: 'bg-red-100 text-red-700',
  };

  return (
    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${styles[status] || 'bg-warm-200 text-warm-700'}`}>
      {status.replace(/_/g, ' ')}
    </span>
  );
}
