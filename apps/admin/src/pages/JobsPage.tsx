import { useEffect, useState, useCallback } from 'react';
import { getJobs, getCategories, adminCloseJob } from '../services/api';
import {
  Search,
  ChevronLeft,
  ChevronRight,
  Eye,
  MapPin,
  Clock,
  DollarSign,
  Filter,
  CheckCircle,
} from 'lucide-react';

const STATUS_OPTIONS = [
  'OPEN',
  'APPLICATIONS_RECEIVED',
  'ASSIGNED',
  'IN_PROGRESS',
  'COMPLETED',
  'REVIEWING',
  'CLOSED',
  'CANCELLED',
];

export default function JobsPage() {
  const [jobs, setJobs] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [categories, setCategories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedJob, setSelectedJob] = useState<any | null>(null);
  const limit = 10;

  useEffect(() => {
    getCategories().then((res) => setCategories(Array.isArray(res) ? res : res.categories || [])).catch(console.error);
  }, []);

  const fetchJobs = useCallback(() => {
    setLoading(true);
    const params: Record<string, string> = {
      page: String(page),
      limit: String(limit),
    };
    if (search) params.search = search;
    if (statusFilter) params.status = statusFilter;
    if (categoryFilter) params.categoryId = categoryFilter;

    getJobs(params)
      .then((res) => {
        setJobs(res.jobs || res.data || []);
        setTotal(res.total || 0);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [page, search, statusFilter, categoryFilter]);

  useEffect(() => {
    fetchJobs();
  }, [fetchJobs]);

  const totalPages = Math.ceil(total / limit);

  return (
    <div className="space-y-4">
      {/* Filters */}
      <div className="bg-white rounded-xl border border-warm-300 p-4">
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search
              size={16}
              className="absolute left-3 top-1/2 -translate-y-1/2 text-warm-400"
            />
            <input
              type="text"
              placeholder="Search jobs..."
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
              className="w-full pl-9 pr-3 py-2 border border-warm-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-400"
            />
          </div>
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
                  {s.replace(/_/g, ' ')}
                </option>
              ))}
            </select>
            <select
              value={categoryFilter}
              onChange={(e) => {
                setCategoryFilter(e.target.value);
                setPage(1);
              }}
              className="px-3 py-2 border border-warm-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-400"
            >
              <option value="">All Categories</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Jobs List */}
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
                    Category
                  </th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">
                    Customer
                  </th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">
                    Worker
                  </th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">
                    Status
                  </th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">
                    Price
                  </th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-warm-500 uppercase">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {jobs.map((job) => (
                  <tr key={job.id} className="hover:bg-warm-50">
                    <td className="px-4 py-3">
                      <div className="min-w-0">
                        <p className="text-sm font-medium text-warm-800 truncate max-w-[200px]">
                          {job.title}
                        </p>
                        <div className="flex items-center gap-1 mt-0.5">
                          <Clock size={12} className="text-warm-400" />
                          <span className="text-xs text-warm-400">
                            {new Date(job.createdAt).toLocaleDateString()}
                          </span>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <span className="px-2 py-0.5 bg-warm-100 text-warm-700 rounded-full text-xs">
                        {job.category?.name || 'N/A'}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm text-warm-700">
                      {job.customer?.user?.name || 'N/A'}
                    </td>
                    <td className="px-4 py-3 text-sm text-warm-700">
                      {job.worker?.user?.name || '-'}
                    </td>
                    <td className="px-4 py-3">
                      <StatusBadge status={job.status} />
                    </td>
                    <td className="px-4 py-3 text-sm text-warm-700">
                      {job.price
                        ? `Rs. ${job.price.toLocaleString()}`
                        : job.budgetMin
                        ? `Rs. ${job.budgetMin}-${job.budgetMax}`
                        : 'N/A'}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <button
                        onClick={() => setSelectedJob(job)}
                        className="p-1.5 text-warm-400 hover:text-primary-600 hover:bg-primary-50 rounded-lg transition-colors"
                      >
                        <Eye size={16} />
                      </button>
                    </td>
                  </tr>
                ))}
                {jobs.length === 0 && (
                  <tr>
                    <td
                      colSpan={7}
                      className="text-center py-8 text-sm text-warm-400"
                    >
                      No jobs found
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

      {/* Job Detail Modal */}
      {selectedJob && (
        <JobDetailModal
          job={selectedJob}
          onClose={() => setSelectedJob(null)}
          onJobUpdated={() => {
            setSelectedJob(null);
            fetchJobs();
          }}
        />
      )}
    </div>
  );
}

function JobDetailModal({
  job,
  onClose,
  onJobUpdated,
}: {
  job: any;
  onClose: () => void;
  onJobUpdated: () => void;
}) {
  const [closing, setClosing] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const handleCloseJob = async () => {
    if (!confirm('Are you sure you want to close this job?')) return;
    setClosing(true);
    setError('');
    try {
      await adminCloseJob(job.id);
      setSuccess('Job closed successfully');
      setTimeout(onJobUpdated, 1000);
    } catch (err: any) {
      setError(err.message || 'Failed to close job');
    } finally {
      setClosing(false);
    }
  };

  const canClose = job.status === 'REVIEWING' || job.status === 'COMPLETED';

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl max-w-2xl w-full max-h-[80vh] overflow-y-auto">
        <div className="p-6 border-b border-warm-300 flex items-center justify-between">
          <h3 className="font-semibold text-warm-800">Job Details</h3>
          <button onClick={onClose} className="text-warm-400 hover:text-warm-700">
            &times;
          </button>
        </div>
        <div className="p-6 space-y-4">
          <div className="flex items-start justify-between">
            <div>
              <h4 className="text-lg font-semibold text-warm-800">{job.title}</h4>
              <div className="flex items-center gap-2 mt-1">
                <StatusBadge status={job.status} />
                <span className="text-sm text-warm-500">
                  {job.category?.name}
                </span>
                <UrgencyBadge urgency={job.urgency} />
              </div>
            </div>
            <div className="text-right">
              <p className="text-lg font-bold text-warm-800">
                {job.price
                  ? `Rs. ${job.price.toLocaleString()}`
                  : job.budgetMin
                  ? `Rs. ${job.budgetMin}-${job.budgetMax}`
                  : 'N/A'}
              </p>
            </div>
          </div>

          {job.description && (
            <div className="p-3 bg-warm-50 rounded-lg">
              <p className="text-sm text-warm-700">{job.description}</p>
            </div>
          )}

          <div className="grid grid-cols-2 gap-4">
            <InfoItem label="Customer" value={job.customer?.user?.name || 'N/A'} />
            <InfoItem label="Worker" value={job.worker?.user?.name || 'Not assigned'} />
            <InfoItem
              label="Address"
              value={job.address || 'N/A'}
              icon={MapPin}
            />
            <InfoItem
              label="Created"
              value={new Date(job.createdAt).toLocaleString()}
              icon={Clock}
            />
            {job.scheduledAt && (
              <InfoItem
                label="Scheduled"
                value={new Date(job.scheduledAt).toLocaleString()}
              />
            )}
            {job.completedAt && (
              <InfoItem
                label="Completed"
                value={new Date(job.completedAt).toLocaleString()}
              />
            )}
          </div>

          {job.payment && (
            <div className="border-t border-warm-300 pt-4">
              <h5 className="font-medium text-warm-800 mb-2 flex items-center gap-2">
                <DollarSign size={16} /> Payment
              </h5>
              <div className="grid grid-cols-2 gap-4">
                <InfoItem label="Amount" value={`Rs. ${job.payment.amount?.toLocaleString()}`} />
                <InfoItem label="Status" value={job.payment.status} />
              </div>
            </div>
          )}

          {job.review && (
            <div className="border-t border-warm-300 pt-4">
              <h5 className="font-medium text-warm-800 mb-2">Review</h5>
              <div className="flex items-center gap-1 mb-1">
                {[1, 2, 3, 4, 5].map((i) => (
                  <span
                    key={i}
                    className={`text-lg ${
                      i <= job.review.rating
                        ? 'text-yellow-400'
                        : 'text-gray-300'
                    }`}
                  >
                    &#9733;
                  </span>
                ))}
              </div>
              {job.review.comment && (
                <p className="text-sm text-warm-600">{job.review.comment}</p>
              )}
            </div>
          )}

          {job._count && (
            <div className="border-t border-warm-300 pt-4">
              <div className="flex gap-6">
                <p className="text-sm text-warm-500">
                  <span className="font-medium text-warm-800">
                    {job._count.applications}
                  </span>{' '}
                  applications
                </p>
                <p className="text-sm text-warm-500">
                  <span className="font-medium text-warm-800">
                    {job._count.messages}
                  </span>{' '}
                  messages
                </p>
              </div>
            </div>
          )}

          {error && (
            <div className="p-3 bg-red-50 text-red-700 rounded-lg text-sm">{error}</div>
          )}
          {success && (
            <div className="p-3 bg-green-50 text-green-700 rounded-lg text-sm">{success}</div>
          )}

          {canClose && (
            <div className="border-t border-warm-300 pt-4">
              <button
                onClick={handleCloseJob}
                disabled={closing}
                className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 text-sm font-medium transition-colors"
              >
                <CheckCircle size={16} />
                {closing ? 'Closing...' : 'Close Job'}
              </button>
              <p className="text-xs text-warm-400 mt-1">
                This will mark the job as completed and notify both parties.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function InfoItem({
  label,
  value,
  icon: Icon,
}: {
  label: string;
  value: any;
  icon?: any;
}) {
  return (
    <div>
      <p className="text-xs text-warm-500 flex items-center gap-1">
        {Icon && <Icon size={12} />}
        {label}
      </p>
      <p className="text-sm font-medium text-warm-800">{String(value)}</p>
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
    CLOSED: 'bg-warm-100 text-warm-700',
    CANCELLED: 'bg-red-100 text-red-700',
  };
  return (
    <span
      className={`px-2 py-0.5 rounded-full text-xs font-medium ${
        styles[status] || 'bg-warm-100 text-warm-700'
      }`}
    >
      {status.replace(/_/g, ' ')}
    </span>
  );
}

function UrgencyBadge({ urgency }: { urgency: string }) {
  const styles: Record<string, string> = {
    LOW: 'bg-warm-100 text-warm-600',
    NORMAL: 'bg-blue-100 text-blue-600',
    URGENT: 'bg-orange-100 text-orange-600',
    EMERGENCY: 'bg-red-100 text-red-600',
  };
  return (
    <span
      className={`px-2 py-0.5 rounded-full text-xs font-medium ${
        styles[urgency] || 'bg-warm-100 text-warm-600'
      }`}
    >
      {urgency}
    </span>
  );
}
