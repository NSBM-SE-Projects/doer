import { useEffect, useState, useCallback } from 'react';
import { getPayments, adminReleasePayment, adminRefundPayment } from '../services/api';
import {
  ChevronLeft,
  ChevronRight,
  CreditCard,
  DollarSign,
  Filter,
  Clock,
  AlertTriangle,
  ArrowUpRight,
  RotateCcw,
} from 'lucide-react';

const STATUS_OPTIONS = ['PENDING', 'HELD', 'RELEASED', 'DISPUTED', 'REFUNDED'];

export default function PaymentsPage() {
  const [payments, setPayments] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [totalRevenue, setTotalRevenue] = useState(0);
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState('');
  const [loading, setLoading] = useState(true);
  const limit = 10;

  const fetchPayments = useCallback(() => {
    setLoading(true);
    const params: Record<string, string> = {
      page: String(page),
      limit: String(limit),
    };
    if (statusFilter) params.status = statusFilter;

    getPayments(params)
      .then((res) => {
        setPayments(res.payments || res.data || []);
        setTotal(res.total || 0);
        setTotalRevenue(res.totalRevenue || 0);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [page, statusFilter]);

  useEffect(() => {
    fetchPayments();
  }, [fetchPayments]);

  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [actionMsg, setActionMsg] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const totalPages = Math.ceil(total / limit);

  // Count by status
  const heldCount = payments.filter(p => p.status === 'HELD').length;
  const disputedCount = payments.filter(p => p.status === 'DISPUTED').length;

  const handleRelease = async (jobId: string) => {
    if (!confirm('Release these held funds to the worker?')) return;
    setActionLoading(jobId);
    setActionMsg(null);
    try {
      await adminReleasePayment(jobId);
      setActionMsg({ type: 'success', text: 'Funds released successfully' });
      fetchPayments();
    } catch (err: any) {
      setActionMsg({ type: 'error', text: err.message || 'Failed to release' });
    } finally {
      setActionLoading(null);
    }
  };

  const handleRefund = async (jobId: string) => {
    if (!confirm('Refund this payment to the customer?')) return;
    setActionLoading(jobId);
    setActionMsg(null);
    try {
      await adminRefundPayment(jobId);
      setActionMsg({ type: 'success', text: 'Payment refunded successfully' });
      fetchPayments();
    } catch (err: any) {
      setActionMsg({ type: 'error', text: err.message || 'Failed to refund' });
    } finally {
      setActionLoading(null);
    }
  };

  return (
    <div className="space-y-4">
      {/* Summary */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white rounded-xl border border-warm-300 p-5">
          <div className="flex items-center gap-2 text-warm-500 text-sm mb-1">
            <CreditCard size={16} />
            Total Payments
          </div>
          <p className="text-2xl font-bold text-warm-800">{total}</p>
        </div>
        <div className="bg-white rounded-xl border border-warm-300 p-5">
          <div className="flex items-center gap-2 text-warm-500 text-sm mb-1">
            <DollarSign size={16} />
            Total Released
          </div>
          <p className="text-2xl font-bold text-green-600">
            Rs. {totalRevenue.toLocaleString()}
          </p>
        </div>
        <div className="bg-white rounded-xl border border-warm-300 p-5">
          <div className="flex items-center gap-2 text-warm-500 text-sm mb-1">
            <Clock size={16} />
            Held in Escrow
          </div>
          <p className="text-2xl font-bold text-orange-600">{heldCount}</p>
        </div>
        <div className="bg-white rounded-xl border border-warm-300 p-5">
          <div className="flex items-center gap-2 text-warm-500 text-sm mb-1">
            <AlertTriangle size={16} />
            Disputed
          </div>
          <p className="text-2xl font-bold text-red-600">{disputedCount}</p>
        </div>
      </div>

      {/* Filter */}
      <div className="bg-white rounded-xl border border-warm-300 p-4">
        <div className="flex items-center gap-2">
          <Filter size={16} className="text-warm-400" />
          <select
            value={statusFilter}
            onChange={(e) => {
              setStatusFilter(e.target.value);
              setPage(1);
            }}
            className="px-3 py-2 border border-warm-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-400"
          >
            <option value="">All Statuses</option>
            {STATUS_OPTIONS.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </select>
        </div>
      </div>

      {actionMsg && (
        <div className={`p-3 rounded-lg text-sm ${actionMsg.type === 'success' ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'}`}>
          {actionMsg.text}
        </div>
      )}

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
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">
                    Job
                  </th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">
                    Customer
                  </th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">
                    Worker
                  </th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">
                    Amount
                  </th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">
                    Status
                  </th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">
                    Held At
                  </th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">
                    Date
                  </th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-warm-500 uppercase">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {payments.map((payment) => (
                  <tr key={payment.id} className="hover:bg-warm-50">
                    <td className="px-4 py-3 text-sm text-warm-800">
                      {payment.job?.title || 'N/A'}
                    </td>
                    <td className="px-4 py-3 text-sm text-warm-700">
                      {payment.job?.customer?.user?.name || 'N/A'}
                    </td>
                    <td className="px-4 py-3 text-sm text-warm-700">
                      {payment.job?.worker?.user?.name || '-'}
                    </td>
                    <td className="px-4 py-3 text-sm font-medium text-warm-800">
                      Rs. {payment.amount?.toLocaleString()}
                    </td>
                    <td className="px-4 py-3">
                      <PaymentStatusBadge status={payment.status} />
                    </td>
                    <td className="px-4 py-3 text-sm text-warm-500">
                      {payment.heldAt
                        ? new Date(payment.heldAt).toLocaleDateString()
                        : '-'}
                    </td>
                    <td className="px-4 py-3 text-sm text-warm-500">
                      {new Date(payment.createdAt).toLocaleDateString()}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <div className="flex items-center justify-end gap-1">
                        {(payment.status === 'HELD' || payment.status === 'DISPUTED') && (
                          <button
                            onClick={() => handleRelease(payment.job?.id || payment.jobId)}
                            disabled={actionLoading === (payment.job?.id || payment.jobId)}
                            title="Release to worker"
                            className="p-1.5 text-green-600 hover:bg-green-50 rounded-lg transition-colors disabled:opacity-30"
                          >
                            <ArrowUpRight size={16} />
                          </button>
                        )}
                        {(payment.status === 'HELD' || payment.status === 'DISPUTED') && (
                          <button
                            onClick={() => handleRefund(payment.job?.id || payment.jobId)}
                            disabled={actionLoading === (payment.job?.id || payment.jobId)}
                            title="Refund to customer"
                            className="p-1.5 text-purple-600 hover:bg-purple-50 rounded-lg transition-colors disabled:opacity-30"
                          >
                            <RotateCcw size={16} />
                          </button>
                        )}
                        {payment.status !== 'HELD' && payment.status !== 'DISPUTED' && (
                          <span className="text-xs text-warm-400">—</span>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
                {payments.length === 0 && (
                  <tr>
                    <td
                      colSpan={8}
                      className="text-center py-8 text-sm text-warm-400"
                    >
                      No payments found
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}

        {totalPages > 1 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-warm-300">
            <p className="text-sm text-warm-500">
              Showing {(page - 1) * limit + 1}-{Math.min(page * limit, total)} of{' '}
              {total}
            </p>
            <div className="flex items-center gap-1">
              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="p-1.5 rounded-lg text-warm-400 hover:text-warm-700 hover:bg-warm-100 disabled:opacity-30"
              >
                <ChevronLeft size={18} />
              </button>
              <span className="px-3 py-1 text-sm text-warm-700">
                {page} / {totalPages}
              </span>
              <button
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="p-1.5 rounded-lg text-warm-400 hover:text-warm-700 hover:bg-warm-100 disabled:opacity-30"
              >
                <ChevronRight size={18} />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function PaymentStatusBadge({ status }: { status: string }) {
  const styles: Record<string, string> = {
    PENDING: 'bg-yellow-100 text-yellow-700',
    HELD: 'bg-orange-100 text-orange-700',
    RELEASED: 'bg-green-100 text-green-700',
    DISPUTED: 'bg-red-100 text-red-700',
    REFUNDED: 'bg-purple-100 text-purple-700',
  };
  return (
    <span
      className={`px-2 py-0.5 rounded-full text-xs font-medium ${
        styles[status] || 'bg-warm-100 text-warm-700'
      }`}
    >
      {status}
    </span>
  );
}
