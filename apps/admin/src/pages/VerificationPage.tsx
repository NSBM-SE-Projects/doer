import { useEffect, useState, useCallback } from 'react';
import { getAllWorkers, verifyWorker } from '../services/api';
import {
  Search,
  ShieldCheck,
  ShieldX,
  RotateCcw,
  Eye,
  X,
  User,
  Star,
  Briefcase,
  FileText,
  CheckCircle,
  XCircle,
  Clock,
} from 'lucide-react';

export default function VerificationPage() {
  const [workers, setWorkers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [selectedWorker, setSelectedWorker] = useState<any | null>(null);
  const [alert, setAlert] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const showAlert = (type: 'success' | 'error', message: string) => {
    setAlert({ type, message });
    setTimeout(() => setAlert(null), 3000);
  };

  const fetchWorkers = useCallback(() => {
    setLoading(true);
    getAllWorkers(statusFilter || undefined)
      .then((res) => setWorkers(res.workers || []))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [statusFilter]);

  useEffect(() => {
    fetchWorkers();
  }, [fetchWorkers]);

  const handleAction = async (userId: string, data: any, label: string) => {
    setActionLoading(userId);
    try {
      await verifyWorker(userId, data);
      showAlert('success', label);
      fetchWorkers();
      if (selectedWorker?.userId === userId) {
        setSelectedWorker(null);
      }
    } catch (err: any) {
      showAlert('error', err.message || 'Action failed');
    } finally {
      setActionLoading(null);
    }
  };

  const filteredWorkers = workers.filter((w) => {
    if (!search) return true;
    const q = search.toLowerCase();
    return (
      (w.user?.name || '').toLowerCase().includes(q) ||
      (w.user?.email || '').toLowerCase().includes(q) ||
      (w.nicNumber || '').toLowerCase().includes(q)
    );
  });

  const statusBadge = (status: string) => {
    const styles: Record<string, string> = {
      NOT_SUBMITTED: 'bg-gray-100 text-gray-600',
      PENDING: 'bg-orange-100 text-orange-700',
      VERIFIED: 'bg-green-100 text-green-700',
      REJECTED: 'bg-red-100 text-red-700',
    };
    return (
      <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${styles[status] || 'bg-warm-100 text-warm-700'}`}>
        {status === 'VERIFIED' ? <CheckCircle size={10} /> : status === 'REJECTED' ? <XCircle size={10} /> : <Clock size={10} />}
        {status}
      </span>
    );
  };

  const badgeBadge = (level: string) => {
    const styles: Record<string, string> = {
      TRAINEE: 'bg-gray-100 text-gray-700',
      BRONZE: 'bg-amber-100 text-amber-800',
      SILVER: 'bg-slate-200 text-slate-700',
      GOLD: 'bg-yellow-100 text-yellow-800',
      PLATINUM: 'bg-indigo-100 text-indigo-800',
    };
    return (
      <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${styles[level] || styles.TRAINEE}`}>
        {level}
      </span>
    );
  };

  return (
    <div className="space-y-4">
      {alert && (
        <div className={`p-3 rounded-lg text-sm font-medium ${alert.type === 'success' ? 'bg-green-50 text-green-700 border border-green-200' : 'bg-red-50 text-red-700 border border-red-200'}`}>
          {alert.message}
        </div>
      )}

      {/* Filters */}
      <div className="bg-white rounded-xl border border-warm-300 p-4">
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-warm-400" />
            <input
              type="text"
              placeholder="Search by name, email, or NIC..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-9 pr-3 py-2 border border-warm-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-400"
            />
          </div>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-2 border border-warm-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-400"
          >
            <option value="">All Status</option>
            <option value="NOT_SUBMITTED">Not Submitted</option>
            <option value="PENDING">Pending</option>
            <option value="VERIFIED">Verified</option>
            <option value="REJECTED">Rejected</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-warm-300 overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center h-48">
            <div className="w-8 h-8 border-3 border-primary-200 border-t-primary-500 rounded-full animate-spin" />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="bg-warm-50 border-b border-warm-300">
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">Worker</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">NIC</th>
                  <th className="text-center px-4 py-3 text-xs font-medium text-warm-500 uppercase">NIC</th>
                  <th className="text-center px-4 py-3 text-xs font-medium text-warm-500 uppercase">Quals</th>
                  <th className="text-center px-4 py-3 text-xs font-medium text-warm-500 uppercase">BG Check</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">Badge</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">Status</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-warm-500 uppercase">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {filteredWorkers.map((w) => (
                  <tr key={w.id} className="hover:bg-warm-50">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 bg-primary-100 rounded-full flex items-center justify-center flex-shrink-0">
                          <span className="text-primary-800 text-sm font-medium">
                            {w.user?.name?.[0]?.toUpperCase() || '?'}
                          </span>
                        </div>
                        <div className="min-w-0">
                          <p className="text-sm font-medium text-warm-800 truncate">{w.user?.name || 'Unknown'}</p>
                          <p className="text-xs text-warm-500 truncate">{w.user?.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-sm text-warm-600">{w.nicNumber || 'N/A'}</td>
                    <td className="px-4 py-3 text-center">
                      {w.nicVerified ? (
                        <CheckCircle size={16} className="inline text-green-500" />
                      ) : w.nicFrontUrl ? (
                        <Clock size={16} className="inline text-orange-400" />
                      ) : (
                        <XCircle size={16} className="inline text-gray-300" />
                      )}
                    </td>
                    <td className="px-4 py-3 text-center">
                      {w.qualificationsVerified ? (
                        <CheckCircle size={16} className="inline text-green-500" />
                      ) : (w.qualificationDocs || []).length > 0 ? (
                        <Clock size={16} className="inline text-orange-400" />
                      ) : (
                        <XCircle size={16} className="inline text-gray-300" />
                      )}
                    </td>
                    <td className="px-4 py-3 text-center">
                      {w.backgroundCheckVerified ? (
                        <CheckCircle size={16} className="inline text-green-500" />
                      ) : w.backgroundCheckUrl ? (
                        <Clock size={16} className="inline text-orange-400" />
                      ) : (
                        <XCircle size={16} className="inline text-gray-300" />
                      )}
                    </td>
                    <td className="px-4 py-3">{badgeBadge(w.badgeLevel || 'TRAINEE')}</td>
                    <td className="px-4 py-3">{statusBadge(w.verificationStatus)}</td>
                    <td className="px-4 py-3">
                      <div className="flex items-center justify-end gap-1">
                        <button
                          onClick={() => setSelectedWorker(w)}
                          className="p-1.5 text-warm-400 hover:text-primary-600 hover:bg-primary-50 rounded-lg transition-colors"
                          title="View & manage"
                        >
                          <Eye size={16} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {filteredWorkers.length === 0 && (
                  <tr>
                    <td colSpan={8} className="px-4 py-12 text-center text-sm text-warm-500">
                      No workers found
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Detail Modal */}
      {selectedWorker && (
        <WorkerVerifyModal
          worker={selectedWorker}
          onClose={() => { setSelectedWorker(null); fetchWorkers(); }}
          onAction={handleAction}
          actionLoading={actionLoading}
        />
      )}
    </div>
  );
}

function WorkerVerifyModal({ worker: w, onClose, onAction, actionLoading }: {
  worker: any;
  onClose: () => void;
  onAction: (userId: string, data: any, label: string) => void;
  actionLoading: string | null;
}) {
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [showRejectForm, setShowRejectForm] = useState(false);
  const isLoading = actionLoading === w.userId;

  return (
    <>
      <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
        <div className="bg-white rounded-xl max-w-2xl w-full max-h-[85vh] overflow-y-auto">
          <div className="p-6 border-b border-warm-300 flex items-center justify-between sticky top-0 bg-white z-10">
            <h3 className="text-lg font-semibold text-warm-800">Worker Verification</h3>
            <button onClick={onClose} className="p-1 hover:bg-warm-100 rounded-lg"><X size={20} /></button>
          </div>
          <div className="p-6 space-y-6">
            {/* Worker info */}
            <div className="flex items-center gap-4">
              <div className="w-14 h-14 bg-primary-100 rounded-full flex items-center justify-center">
                <User size={24} className="text-primary-600" />
              </div>
              <div>
                <h4 className="text-lg font-semibold text-warm-800">{w.user?.name || 'Unknown'}</h4>
                <p className="text-sm text-warm-500">{w.user?.email}</p>
                <div className="flex gap-2 mt-1">
                  <span className="text-xs text-warm-400">NIC: {w.nicNumber || 'N/A'}</span>
                  <span className="text-xs text-warm-400">Rating: <Star size={10} className="inline text-yellow-500" /> {w.rating?.toFixed(1) || '0.0'}</span>
                  <span className="text-xs text-warm-400">Jobs: {w.totalJobs || 0}</span>
                </div>
              </div>
            </div>

            {/* 1. NIC Verification */}
            <DocSection
              title="National Identity Card"
              verified={w.nicVerified}
              hasDoc={!!(w.nicFrontUrl || w.nicBackUrl)}
              docs={[
                { label: 'NIC Front', url: w.nicFrontUrl },
                { label: 'NIC Back', url: w.nicBackUrl },
              ]}
              onPreview={setPreviewUrl}
              onVerify={() => onAction(w.userId, { nicVerified: true }, 'NIC verified')}
              onRevoke={() => onAction(w.userId, { nicVerified: false }, 'NIC verification revoked')}
              isLoading={isLoading}
            />

            {/* 2. Qualifications */}
            <DocSection
              title="Qualifications & Certificates"
              verified={w.qualificationsVerified}
              hasDoc={(w.qualificationDocs || []).length > 0}
              docs={(w.qualificationDocs || []).map((d: any) => ({ label: d.title, url: d.url }))}
              onPreview={setPreviewUrl}
              onVerify={() => onAction(w.userId, { qualificationsVerified: true }, 'Qualifications verified')}
              onRevoke={() => onAction(w.userId, { qualificationsVerified: false }, 'Qualifications verification revoked')}
              isLoading={isLoading}
            />

            {/* 3. Background Check */}
            <DocSection
              title="Background Check"
              verified={w.backgroundCheckVerified}
              hasDoc={!!w.backgroundCheckUrl}
              docs={[{ label: 'Police Certificate', url: w.backgroundCheckUrl }]}
              onPreview={setPreviewUrl}
              onVerify={() => onAction(w.userId, { backgroundCheckVerified: true }, 'Background check verified')}
              onRevoke={() => onAction(w.userId, { backgroundCheckVerified: false }, 'Background check revoked')}
              isLoading={isLoading}
            />

            {/* Overall actions */}
            <div className="border-t border-warm-200 pt-4">
              <div className="flex gap-2">
                {!showRejectForm ? (
                  <>
                    <button
                      onClick={() => onAction(w.userId, { status: 'PENDING' }, 'Status reset to pending')}
                      disabled={isLoading}
                      className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 border border-warm-300 text-warm-700 rounded-lg text-sm font-medium hover:bg-warm-50 disabled:opacity-50 transition-colors"
                    >
                      <RotateCcw size={16} />
                      Reset to Pending
                    </button>
                    <button
                      onClick={() => setShowRejectForm(true)}
                      disabled={isLoading}
                      className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 bg-red-600 text-white rounded-lg text-sm font-medium hover:bg-red-700 disabled:opacity-50 transition-colors"
                    >
                      <ShieldX size={16} />
                      Reject All
                    </button>
                  </>
                ) : (
                  <div className="w-full space-y-3">
                    <textarea
                      value={rejectReason}
                      onChange={(e) => setRejectReason(e.target.value)}
                      rows={3}
                      placeholder="Reason for rejection (shown to worker)..."
                      className="w-full px-3 py-2 border border-warm-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-400 resize-none"
                    />
                    <div className="flex gap-2">
                      <button
                        onClick={() => setShowRejectForm(false)}
                        className="flex-1 px-4 py-2 border border-warm-300 text-warm-700 rounded-lg text-sm"
                      >
                        Cancel
                      </button>
                      <button
                        onClick={() => {
                          onAction(w.userId, { status: 'REJECTED', rejectionReason: rejectReason }, 'Worker rejected');
                          setShowRejectForm(false);
                        }}
                        disabled={!rejectReason.trim() || isLoading}
                        className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg text-sm font-medium disabled:opacity-50"
                      >
                        Confirm Reject
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Document Preview */}
      {previewUrl && (
        <div className="fixed inset-0 bg-black/70 z-[60] flex items-center justify-center p-4" onClick={() => setPreviewUrl(null)}>
          <div className="relative max-w-3xl max-h-[90vh] bg-white rounded-xl overflow-hidden" onClick={(e) => e.stopPropagation()}>
            <button onClick={() => setPreviewUrl(null)} className="absolute top-3 right-3 z-10 w-8 h-8 bg-white rounded-full flex items-center justify-center shadow-md">
              <X size={16} />
            </button>
            <img src={previewUrl} alt="Document" className="max-w-full max-h-[85vh] object-contain" />
          </div>
        </div>
      )}
    </>
  );
}

function DocSection({ title, verified, hasDoc, docs, onPreview, onVerify, onRevoke, isLoading }: {
  title: string;
  verified: boolean;
  hasDoc: boolean;
  docs: { label: string; url: string | null }[];
  onPreview: (url: string) => void;
  onVerify: () => void;
  onRevoke: () => void;
  isLoading: boolean;
}) {
  return (
    <div className="border border-warm-200 rounded-xl p-4">
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <FileText size={16} className="text-warm-500" />
          <h5 className="font-medium text-warm-800">{title}</h5>
        </div>
        {verified ? (
          <span className="flex items-center gap-1 px-2 py-0.5 bg-green-100 text-green-700 rounded-full text-xs font-medium">
            <CheckCircle size={12} /> Verified
          </span>
        ) : hasDoc ? (
          <span className="flex items-center gap-1 px-2 py-0.5 bg-orange-100 text-orange-700 rounded-full text-xs font-medium">
            <Clock size={12} /> Pending Review
          </span>
        ) : (
          <span className="flex items-center gap-1 px-2 py-0.5 bg-gray-100 text-gray-500 rounded-full text-xs font-medium">
            <XCircle size={12} /> Not Submitted
          </span>
        )}
      </div>

      {/* Document thumbnails */}
      <div className="flex flex-wrap gap-2 mb-3">
        {docs.map((doc, i) => (
          doc.url ? (
            <button
              key={i}
              onClick={() => onPreview(doc.url!)}
              className="flex items-center gap-2 px-3 py-2 bg-blue-50 text-blue-700 rounded-lg text-xs hover:bg-blue-100 transition-colors"
            >
              <Eye size={14} />
              {doc.label}
            </button>
          ) : (
            <span key={i} className="flex items-center gap-2 px-3 py-2 bg-warm-50 text-warm-400 rounded-lg text-xs">
              <XCircle size={14} />
              {doc.label} — not uploaded
            </span>
          )
        ))}
      </div>

      {/* Verify / Revoke buttons */}
      {hasDoc && (
        <div className="flex gap-2">
          {!verified ? (
            <button
              onClick={onVerify}
              disabled={isLoading}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-green-600 text-white rounded-lg text-xs font-medium hover:bg-green-700 disabled:opacity-50 transition-colors"
            >
              <ShieldCheck size={14} />
              Verify
            </button>
          ) : (
            <button
              onClick={onRevoke}
              disabled={isLoading}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-orange-500 text-white rounded-lg text-xs font-medium hover:bg-orange-600 disabled:opacity-50 transition-colors"
            >
              <RotateCcw size={14} />
              Revoke
            </button>
          )}
        </div>
      )}
    </div>
  );
}
