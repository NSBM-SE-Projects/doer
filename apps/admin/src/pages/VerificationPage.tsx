import { useEffect, useState } from 'react';
import { getPendingWorkers, verifyWorker } from '../services/api';
import type { BadgeLevel } from '../types';
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
  FileText,
  Award,
  X,
  Eye,
} from 'lucide-react';

const BADGE_COLORS: Record<BadgeLevel, string> = {
  TRAINEE: 'bg-gray-100 text-gray-700',
  BRONZE: 'bg-amber-100 text-amber-800',
  SILVER: 'bg-slate-200 text-slate-700',
  GOLD: 'bg-yellow-100 text-yellow-800',
  PLATINUM: 'bg-indigo-100 text-indigo-800',
};

export default function VerificationPage() {
  const [workers, setWorkers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [rejectTarget, setRejectTarget] = useState<string | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);

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

  const handleVerify = async (userId: string) => {
    setActionLoading(userId);
    try {
      await verifyWorker(userId, 'VERIFIED');
      fetchWorkers();
    } catch (err) {
      console.error(err);
    } finally {
      setActionLoading(null);
    }
  };

  const handleReject = async () => {
    if (!rejectTarget || !rejectionReason.trim()) return;
    setActionLoading(rejectTarget);
    try {
      await verifyWorker(rejectTarget, 'REJECTED', rejectionReason.trim());
      setRejectTarget(null);
      setRejectionReason('');
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
              <div className="flex flex-col items-end gap-1">
                <span className="px-2 py-0.5 bg-orange-100 text-orange-700 rounded-full text-xs font-medium">
                  PENDING
                </span>
                {worker.badgeLevel && (
                  <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${BADGE_COLORS[worker.badgeLevel as BadgeLevel] || BADGE_COLORS.TRAINEE}`}>
                    <Award size={10} className="inline mr-1" />
                    {worker.badgeLevel}
                  </span>
                )}
              </div>
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

            {/* Document Viewer Section */}
            <div className="mt-4">
              <p className="text-xs text-warm-500 mb-2 font-medium">Documents</p>
              <div className="grid grid-cols-3 gap-2">
                <DocThumbnail
                  label="NIC Front"
                  url={worker.nicFrontUrl}
                  onPreview={setPreviewUrl}
                />
                <DocThumbnail
                  label="NIC Back"
                  url={worker.nicBackUrl}
                  onPreview={setPreviewUrl}
                />
                <DocThumbnail
                  label="Background"
                  url={worker.backgroundCheckUrl}
                  onPreview={setPreviewUrl}
                />
              </div>
              {worker.qualificationDocs && worker.qualificationDocs.length > 0 && (
                <div className="mt-2">
                  <p className="text-xs text-warm-400 mb-1">Qualifications</p>
                  <div className="flex flex-wrap gap-1">
                    {worker.qualificationDocs.map((doc: any) => (
                      <button
                        key={doc.id}
                        onClick={() => setPreviewUrl(doc.url)}
                        className="flex items-center gap-1 px-2 py-1 bg-blue-50 text-blue-700 rounded text-xs hover:bg-blue-100 transition-colors"
                      >
                        <FileText size={12} />
                        {doc.title}
                      </button>
                    ))}
                  </div>
                </div>
              )}
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
                onClick={() => handleVerify(worker.userId)}
                disabled={actionLoading === worker.userId}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg text-sm font-medium hover:bg-green-700 disabled:opacity-50 transition-colors"
              >
                <ShieldCheck size={16} />
                Approve
              </button>
              <button
                onClick={() => {
                  setRejectTarget(worker.userId);
                  setRejectionReason('');
                }}
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

      {/* Rejection Reason Modal */}
      {rejectTarget && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl max-w-md w-full">
            <div className="p-6 border-b border-warm-300 flex items-center justify-between">
              <h3 className="font-semibold text-warm-800">Rejection Reason</h3>
              <button
                onClick={() => setRejectTarget(null)}
                className="text-warm-400 hover:text-warm-700"
              >
                <X size={20} />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <p className="text-sm text-warm-500">
                Please provide a reason for rejecting this worker's verification.
                This will be shown to the worker.
              </p>
              <textarea
                value={rejectionReason}
                onChange={(e) => setRejectionReason(e.target.value)}
                rows={4}
                placeholder="e.g. NIC image is blurry, please re-upload a clearer photo..."
                className="w-full px-3 py-2 border border-warm-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-400 resize-none"
              />
              <div className="flex gap-3">
                <button
                  onClick={() => setRejectTarget(null)}
                  className="flex-1 px-4 py-2 border border-warm-300 text-warm-700 rounded-lg text-sm font-medium hover:bg-warm-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleReject}
                  disabled={!rejectionReason.trim() || actionLoading === rejectTarget}
                  className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg text-sm font-medium hover:bg-red-700 disabled:opacity-50 transition-colors"
                >
                  {actionLoading === rejectTarget ? 'Rejecting...' : 'Confirm Reject'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Document Preview Modal */}
      {previewUrl && (
        <div
          className="fixed inset-0 bg-black/70 z-50 flex items-center justify-center p-4"
          onClick={() => setPreviewUrl(null)}
        >
          <div
            className="relative max-w-3xl max-h-[90vh] bg-white rounded-xl overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            <button
              onClick={() => setPreviewUrl(null)}
              className="absolute top-3 right-3 z-10 w-8 h-8 bg-white rounded-full flex items-center justify-center shadow-md hover:bg-warm-50"
            >
              <X size={16} />
            </button>
            {previewUrl.endsWith('.pdf') ? (
              <iframe src={previewUrl} className="w-full h-[80vh]" />
            ) : (
              <img
                src={previewUrl}
                alt="Document preview"
                className="max-w-full max-h-[85vh] object-contain"
              />
            )}
          </div>
        </div>
      )}
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

function DocThumbnail({
  label,
  url,
  onPreview,
}: {
  label: string;
  url: string | null;
  onPreview: (url: string) => void;
}) {
  if (!url) {
    return (
      <div className="flex flex-col items-center justify-center p-3 bg-warm-50 rounded-lg border border-dashed border-warm-300 text-center">
        <FileText size={16} className="text-warm-300 mb-1" />
        <span className="text-xs text-warm-400">{label}</span>
        <span className="text-xs text-warm-300">Not uploaded</span>
      </div>
    );
  }

  return (
    <button
      onClick={() => onPreview(url)}
      className="flex flex-col items-center justify-center p-3 bg-green-50 rounded-lg border border-green-200 text-center hover:bg-green-100 transition-colors"
    >
      <Eye size={16} className="text-green-600 mb-1" />
      <span className="text-xs text-green-700 font-medium">{label}</span>
      <span className="text-xs text-green-500">View</span>
    </button>
  );
}
