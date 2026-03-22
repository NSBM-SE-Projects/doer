import { useEffect, useState } from 'react';
import { getPendingWorkers, verifyWorker } from '../services/api';
import {
  ShieldCheck,
  ShieldX,
  User,
  MapPin,
  CreditCard,
  Star,
  Briefcase,
  CheckCircle,
  XCircle,
  AlertCircle,
} from 'lucide-react';

export default function VerificationPage() {
  const [workers, setWorkers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  const fetchWorkers = () => {
    setLoading(true);
    getPendingWorkers()
      .then((res) => setWorkers(res.workers || res.data || []))
      .catch(console.error)
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchWorkers();
  }, []);

  const handleVerify = async (userId: string, status: 'VERIFIED' | 'REJECTED') => {
    setActionLoading(userId);
    try {
      await verifyWorker(userId, status);
      fetchWorkers();
    } catch (err) {
      console.error(err);
    } finally {
      setActionLoading(null);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="w-8 h-8 border-3 border-primary-200 border-t-primary-500 rounded-full animate-spin" />
      </div>
    );
  }

  if (workers.length === 0) {
    return (
      <div className="bg-white rounded-xl border border-warm-300 p-12 text-center">
        <CheckCircle size={48} className="mx-auto text-green-400 mb-4" />
        <h3 className="text-lg font-semibold text-warm-800">All caught up!</h3>
        <p className="text-sm text-warm-500 mt-1">
          No workers pending verification.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2 text-sm text-warm-500">
        <AlertCircle size={16} />
        <span>{workers.length} worker(s) awaiting verification</span>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {workers.map((worker) => (
          <div
            key={worker.id}
            className="bg-white rounded-xl border border-warm-300 p-5"
          >
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 bg-orange-100 rounded-full flex items-center justify-center flex-shrink-0">
                {worker.user?.avatarUrl ? (
                  <img
                    src={worker.user.avatarUrl}
                    alt=""
                    className="w-12 h-12 rounded-full object-cover"
                  />
                ) : (
                  <User size={20} className="text-orange-600" />
                )}
              </div>
              <div className="flex-1 min-w-0">
                <h4 className="font-semibold text-warm-800">
                  {worker.user?.name || 'Unknown'}
                </h4>
                <p className="text-sm text-warm-500">{worker.user?.email}</p>
                <p className="text-xs text-warm-400 mt-0.5">
                  Applied {new Date(worker.user?.createdAt).toLocaleDateString()}
                </p>
              </div>
              <span className="px-2 py-0.5 bg-orange-100 text-orange-700 rounded-full text-xs font-medium">
                PENDING
              </span>
            </div>

            <div className="mt-4 grid grid-cols-2 gap-3">
              <DetailItem
                icon={CreditCard}
                label="NIC Number"
                value={worker.nicNumber || 'Not provided'}
              />
              <DetailItem
                icon={MapPin}
                label="Location"
                value={
                  worker.latitude
                    ? `${worker.latitude.toFixed(4)}, ${worker.longitude.toFixed(4)}`
                    : 'Not set'
                }
              />
              <DetailItem
                icon={Star}
                label="Rating"
                value={`${worker.rating} / 5`}
              />
              <DetailItem
                icon={Briefcase}
                label="Total Jobs"
                value={worker.totalJobs}
              />
            </div>

            {worker.bio && (
              <div className="mt-3 p-3 bg-warm-50 rounded-lg">
                <p className="text-xs text-warm-500 mb-1">Bio</p>
                <p className="text-sm text-warm-700">{worker.bio}</p>
              </div>
            )}

            {worker.categories && worker.categories.length > 0 && (
              <div className="mt-3">
                <p className="text-xs text-warm-500 mb-1">Skills</p>
                <div className="flex flex-wrap gap-1">
                  {worker.categories.map((wc: any) => (
                    <span
                      key={wc.category?.id || wc.categoryId}
                      className="px-2 py-0.5 bg-primary-50 text-primary-800 rounded-full text-xs"
                    >
                      {wc.category?.name || 'Unknown'}
                    </span>
                  ))}
                </div>
              </div>
            )}

            <div className="mt-4 flex items-center gap-2">
              <button
                onClick={() => handleVerify(worker.userId, 'VERIFIED')}
                disabled={actionLoading === worker.userId}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg text-sm font-medium hover:bg-green-700 disabled:opacity-50 transition-colors"
              >
                <ShieldCheck size={16} />
                Approve
              </button>
              <button
                onClick={() => handleVerify(worker.userId, 'REJECTED')}
                disabled={actionLoading === worker.userId}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg text-sm font-medium hover:bg-red-700 disabled:opacity-50 transition-colors"
              >
                <ShieldX size={16} />
                Reject
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function DetailItem({
  icon: Icon,
  label,
  value,
}: {
  icon: any;
  label: string;
  value: any;
}) {
  return (
    <div className="flex items-center gap-2">
      <Icon size={14} className="text-warm-400 flex-shrink-0" />
      <div className="min-w-0">
        <p className="text-xs text-warm-400">{label}</p>
        <p className="text-sm text-warm-800 truncate">{String(value)}</p>
      </div>
    </div>
  );
}
