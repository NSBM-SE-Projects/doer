import { useEffect, useState } from 'react';
import { getDisputes } from '../services/api';
import {
  AlertTriangle,
  MessageSquare,
  User,
  Clock,
  CheckCircle,
} from 'lucide-react';

export default function DisputesPage() {
  const [disputes, setDisputes] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedDispute, setSelectedDispute] = useState<any | null>(null);

  useEffect(() => {
    getDisputes()
      .then((res) => setDisputes(res.disputes || res.data || []))
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

  if (disputes.length === 0) {
    return (
      <div className="bg-white rounded-xl border border-warm-300 p-12 text-center">
        <CheckCircle size={48} className="mx-auto text-green-400 mb-4" />
        <h3 className="text-lg font-semibold text-warm-800">No disputes</h3>
        <p className="text-sm text-warm-500 mt-1">
          No cancelled or disputed jobs to review.
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
                <span>Worker: {job.worker?.user?.name || 'Not assigned'}</span>
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
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl max-w-2xl w-full max-h-[80vh] overflow-y-auto">
            <div className="p-6 border-b border-warm-300 flex items-center justify-between">
              <h3 className="font-semibold text-warm-800 flex items-center gap-2">
                <AlertTriangle size={18} className="text-orange-500" />
                Dispute Details
              </h3>
              <button
                onClick={() => setSelectedDispute(null)}
                className="text-warm-400 hover:text-warm-700"
              >
                &times;
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <h4 className="text-lg font-semibold text-warm-800">
                  {selectedDispute.title}
                </h4>
                {selectedDispute.description && (
                  <p className="text-sm text-warm-600 mt-1">
                    {selectedDispute.description}
                  </p>
                )}
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-xs text-warm-500">Customer</p>
                  <p className="text-sm font-medium text-warm-800">
                    {selectedDispute.customer?.user?.name || 'N/A'}
                  </p>
                  <p className="text-xs text-warm-400">
                    {selectedDispute.customer?.user?.email}
                  </p>
                </div>
                <div>
                  <p className="text-xs text-warm-500">Worker</p>
                  <p className="text-sm font-medium text-warm-800">
                    {selectedDispute.worker?.user?.name || 'Not assigned'}
                  </p>
                  <p className="text-xs text-warm-400">
                    {selectedDispute.worker?.user?.email}
                  </p>
                </div>
                <div>
                  <p className="text-xs text-warm-500">Price</p>
                  <p className="text-sm font-medium text-warm-800">
                    {selectedDispute.price
                      ? `Rs. ${selectedDispute.price.toLocaleString()}`
                      : 'N/A'}
                  </p>
                </div>
                <div>
                  <p className="text-xs text-warm-500">Category</p>
                  <p className="text-sm font-medium text-warm-800">
                    {selectedDispute.category?.name || 'N/A'}
                  </p>
                </div>
              </div>

              {selectedDispute.review && (
                <div className="border-t border-warm-300 pt-4">
                  <h5 className="font-medium text-warm-800 mb-2">Review</h5>
                  <div className="flex items-center gap-1 mb-1">
                    {[1, 2, 3, 4, 5].map((i) => (
                      <span
                        key={i}
                        className={`text-lg ${
                          i <= selectedDispute.review.rating
                            ? 'text-yellow-400'
                            : 'text-gray-300'
                        }`}
                      >
                        &#9733;
                      </span>
                    ))}
                  </div>
                  {selectedDispute.review.comment && (
                    <p className="text-sm text-warm-600">
                      {selectedDispute.review.comment}
                    </p>
                  )}
                </div>
              )}

              {selectedDispute.messages && selectedDispute.messages.length > 0 && (
                <div className="border-t border-warm-300 pt-4">
                  <h5 className="font-medium text-warm-800 mb-2 flex items-center gap-2">
                    <MessageSquare size={16} />
                    Recent Messages
                  </h5>
                  <div className="space-y-2 max-h-60 overflow-y-auto">
                    {selectedDispute.messages.map((msg: any) => (
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
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
