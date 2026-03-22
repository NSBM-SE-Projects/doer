import { useEffect, useState } from 'react';
import { getDisputes, resolveDispute } from '../services/api';
import {
  AlertTriangle,
  MessageSquare,
  User,
  Clock,
  CheckCircle,
  ShieldCheck,
  DollarSign,
} from 'lucide-react';

export default function DisputesPage() {
  const [disputes, setDisputes] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedDispute, setSelectedDispute] = useState<any | null>(null);

  const fetchDisputes = () => {
    setLoading(true);
    getDisputes()
      .then((res) => setDisputes(res.disputes || res.data || []))
      .catch(console.error)
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchDisputes();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="w-8 h-8 border-3 border-primary-200 border-t-primary-500 rounded-full animate-spin" />
      </div>
    );
  }

  if (disputes.length === 0) {
    return (
      <div className="bg-white rounded-xl border border-warm-300 p-12 text-center">
        <CheckCircle size={48} className="mx-auto text-green-400 mb-4" />
        <h3 className="text-lg font-semibold text-warm-800">No disputes</h3>
        <p className="text-sm text-warm-500 mt-1">
          No cancelled jobs with assigned workers to review.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <p className="text-sm text-warm-500 flex items-center gap-2">
        <AlertTriangle size={16} className="text-orange-500" />
        {disputes.length} dispute(s) to review
      </p>

      <div className="space-y-3">
        {disputes.map((job) => (
          <div
            key={job.id}
            className="bg-white rounded-xl border border-warm-300 p-5 hover:shadow-md transition-shadow cursor-pointer"
            onClick={() => setSelectedDispute(job)}
          >
            <div className="flex items-start justify-between">
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <h4 className="font-semibold text-warm-800">{job.title}</h4>
                  <span className="px-2 py-0.5 bg-red-100 text-red-700 rounded-full text-xs font-medium">
                    CANCELLED
                  </span>
                </div>
                <p className="text-sm text-warm-500 mt-1">
                  {job.category?.name} &middot; {job.address || 'No address'}
                </p>
              </div>
              <div className="text-right">
                <p className="text-sm font-medium text-warm-800">
                  {job.price ? `Rs. ${job.price.toLocaleString()}` : 'N/A'}
                </p>
                <p className="text-xs text-warm-400">
                  {new Date(job.createdAt).toLocaleDateString()}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-6 mt-3 pt-3 border-t border-warm-200">
              <div className="flex items-center gap-2 text-sm text-warm-600">
                <User size={14} className="text-warm-400" />
                <span>
                  Customer: {job.customer?.user?.name || 'N/A'}
                </span>
              </div>
              <div className="flex items-center gap-2 text-sm text-warm-600">
                <User size={14} className="text-warm-400" />
                <span>Worker: {job.worker?.user?.name || 'N/A'}</span>
              </div>
              {job._count?.messages > 0 && (
                <div className="flex items-center gap-1 text-sm text-warm-500">
                  <MessageSquare size={14} />
                  {job._count.messages} messages
                </div>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Dispute Detail Modal */}
      {selectedDispute && (
        <DisputeDetailModal
          dispute={selectedDispute}
          onClose={() => setSelectedDispute(null)}
          onResolved={() => {
            setSelectedDispute(null);
            fetchDisputes();
          }}
        />
      )}
    </div>
  );
}

function DisputeDetailModal({
  dispute,
  onClose,
  onResolved,
}: {
  dispute: any;
  onClose: () => void;
  onResolved: () => void;
}) {
  const [resolution, setResolution] = useState<'refund_customer' | 'pay_worker' | 'no_compensation'>('no_compensation');
  const [notes, setNotes] = useState('');
  const [resolving, setResolving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const handleResolve = async () => {
    const labels: Record<string, string> = {
      refund_customer: 'refund the customer',
      pay_worker: 'compensate the worker',
      no_compensation: 'resolve with no compensation',
    };
    if (!confirm(`Are you sure you want to ${labels[resolution]}?`)) return;

    setResolving(true);
    setError('');
    try {
      await resolveDispute(dispute.id, { resolution, notes: notes || undefined });
      setSuccess('Dispute resolved successfully');
      setTimeout(onResolved, 1000);
    } catch (err: any) {
      setError(err.message || 'Failed to resolve dispute');
    } finally {
      setResolving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl max-w-2xl w-full max-h-[80vh] overflow-y-auto">
        <div className="p-6 border-b border-warm-300 flex items-center justify-between">
          <h3 className="font-semibold text-warm-800 flex items-center gap-2">
            <AlertTriangle size={18} className="text-orange-500" />
            Dispute Details
          </h3>
          <button
            onClick={onClose}
            className="text-warm-400 hover:text-warm-700"
          >
            &times;
          </button>
        </div>
        <div className="p-6 space-y-4">
          <div>
            <h4 className="text-lg font-semibold text-warm-800">
              {dispute.title}
            </h4>
            {dispute.description && (
              <p className="text-sm text-warm-600 mt-1">
                {dispute.description}
              </p>
            )}
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-xs text-warm-500">Customer</p>
              <p className="text-sm font-medium text-warm-800">
                {dispute.customer?.user?.name || 'N/A'}
              </p>
              <p className="text-xs text-warm-400">
                {dispute.customer?.user?.email}
              </p>
            </div>
            <div>
              <p className="text-xs text-warm-500">Worker</p>
              <p className="text-sm font-medium text-warm-800">
                {dispute.worker?.user?.name || 'N/A'}
              </p>
              <p className="text-xs text-warm-400">
                {dispute.worker?.user?.email}
              </p>
            </div>
            <div>
              <p className="text-xs text-warm-500">Price</p>
              <p className="text-sm font-medium text-warm-800">
                {dispute.price
                  ? `Rs. ${dispute.price.toLocaleString()}`
                  : 'N/A'}
              </p>
            </div>
            <div>
              <p className="text-xs text-warm-500">Category</p>
              <p className="text-sm font-medium text-warm-800">
                {dispute.category?.name || 'N/A'}
              </p>
            </div>
          </div>

          {dispute.payment && (
            <div className="border-t border-warm-300 pt-4">
              <h5 className="font-medium text-warm-800 mb-2 flex items-center gap-2">
                <DollarSign size={16} /> Payment
              </h5>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-xs text-warm-500">Amount</p>
                  <p className="text-sm font-medium text-warm-800">
                    Rs. {dispute.payment.amount?.toLocaleString()}
                  </p>
                </div>
                <div>
                  <p className="text-xs text-warm-500">Status</p>
                  <p className="text-sm font-medium text-warm-800">
                    {dispute.payment.status}
                  </p>
                </div>
              </div>
            </div>
          )}

          {dispute.review && (
            <div className="border-t border-warm-300 pt-4">
              <h5 className="font-medium text-warm-800 mb-2">Review</h5>
              <div className="flex items-center gap-1 mb-1">
                {[1, 2, 3, 4, 5].map((i) => (
                  <span
                    key={i}
                    className={`text-lg ${
                      i <= dispute.review.rating
                        ? 'text-yellow-400'
                        : 'text-gray-300'
                    }`}
                  >
                    &#9733;
                  </span>
                ))}
              </div>
              {dispute.review.comment && (
                <p className="text-sm text-warm-600">
                  {dispute.review.comment}
                </p>
              )}
            </div>
          )}

          {dispute.messages && dispute.messages.length > 0 && (
            <div className="border-t border-warm-300 pt-4">
              <h5 className="font-medium text-warm-800 mb-2 flex items-center gap-2">
                <MessageSquare size={16} />
                Recent Messages
              </h5>
              <div className="space-y-2 max-h-60 overflow-y-auto">
                {dispute.messages.map((msg: any) => (
                  <div
                    key={msg.id}
                    className="p-3 bg-warm-50 rounded-lg"
                  >
                    <div className="flex items-center justify-between mb-1">
                      <p className="text-xs font-medium text-warm-700">
                        {msg.sender?.name || 'Unknown'}
                      </p>
                      <p className="text-xs text-warm-400 flex items-center gap-1">
                        <Clock size={10} />
                        {new Date(msg.createdAt).toLocaleString()}
                      </p>
                    </div>
                    <p className="text-sm text-warm-600">{msg.content}</p>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Resolution Section */}
          <div className="border-t border-warm-300 pt-4">
            <h5 className="font-medium text-warm-800 mb-3 flex items-center gap-2">
              <ShieldCheck size={16} />
              Resolve Dispute
            </h5>

            <div className="space-y-2 mb-3">
              <label className="flex items-center gap-3 p-3 border border-warm-200 rounded-lg cursor-pointer hover:bg-warm-50 transition-colors">
                <input
                  type="radio"
                  name="resolution"
                  value="refund_customer"
                  checked={resolution === 'refund_customer'}
                  onChange={() => setResolution('refund_customer')}
                  className="accent-primary-600"
                />
                <div>
                  <p className="text-sm font-medium text-warm-800">Refund Customer</p>
                  <p className="text-xs text-warm-500">Issue a full refund to the customer for this job</p>
                </div>
              </label>
              <label className="flex items-center gap-3 p-3 border border-warm-200 rounded-lg cursor-pointer hover:bg-warm-50 transition-colors">
                <input
                  type="radio"
                  name="resolution"
                  value="pay_worker"
                  checked={resolution === 'pay_worker'}
                  onChange={() => setResolution('pay_worker')}
                  className="accent-primary-600"
                />
                <div>
                  <p className="text-sm font-medium text-warm-800">Compensate Worker</p>
                  <p className="text-xs text-warm-500">Pay the worker for work completed before cancellation</p>
                </div>
              </label>
              <label className="flex items-center gap-3 p-3 border border-warm-200 rounded-lg cursor-pointer hover:bg-warm-50 transition-colors">
                <input
                  type="radio"
                  name="resolution"
                  value="no_compensation"
                  checked={resolution === 'no_compensation'}
                  onChange={() => setResolution('no_compensation')}
                  className="accent-primary-600"
                />
                <div>
                  <p className="text-sm font-medium text-warm-800">No Compensation</p>
                  <p className="text-xs text-warm-500">Close the dispute without issuing any compensation</p>
                </div>
              </label>
            </div>

            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Add resolution notes (optional)..."
              rows={2}
              className="w-full px-3 py-2 border border-warm-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 resize-none mb-3"
            />

            {error && (
              <div className="p-3 bg-red-50 text-red-700 rounded-lg text-sm mb-3">{error}</div>
            )}
            {success && (
              <div className="p-3 bg-green-50 text-green-700 rounded-lg text-sm mb-3">{success}</div>
            )}

            <button
              onClick={handleResolve}
              disabled={resolving}
              className="flex items-center gap-2 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 text-sm font-medium transition-colors"
            >
              <ShieldCheck size={16} />
              {resolving ? 'Resolving...' : 'Resolve Dispute'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
