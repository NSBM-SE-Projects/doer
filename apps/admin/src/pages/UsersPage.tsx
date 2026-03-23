import { useEffect, useState, useCallback } from 'react';
import { getUsers, updateUserStatus, deleteUser, verifyWorker } from '../services/api';
import {
  Search,
  ChevronLeft,
  ChevronRight,
  UserCheck,
  UserX,
  Eye,
  Trash2,
} from 'lucide-react';

export default function UsersPage() {
  const [users, setUsers] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [loading, setLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState<any | null>(null);
  const limit = 10;

  const fetchUsers = useCallback(() => {
    setLoading(true);
    const params: Record<string, string> = {
      page: String(page),
      limit: String(limit),
    };
    if (search) params.search = search;
    if (roleFilter) params.role = roleFilter;
    if (statusFilter) params.status = statusFilter;

    getUsers(params)
      .then((res) => {
        setUsers(res.users || res.data || []);
        setTotal(res.total || 0);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [page, search, roleFilter, statusFilter]);

  useEffect(() => {
    fetchUsers();
  }, [fetchUsers]);

  const [alert, setAlert] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const showAlert = (type: 'success' | 'error', message: string) => {
    setAlert({ type, message });
    setTimeout(() => setAlert(null), 3000);
  };

  const toggleStatus = async (userId: string, currentStatus: boolean) => {
    try {
      await updateUserStatus(userId, !currentStatus);
      showAlert('success', `User ${currentStatus ? 'deactivated' : 'activated'} successfully`);
      fetchUsers();
    } catch (err: any) {
      showAlert('error', err.message || 'Failed to update user status');
    }
  };

  const handleDelete = async (userId: string, userName: string) => {
    if (!window.confirm(`Are you sure you want to delete "${userName}"? This cannot be undone.`)) return;
    try {
      await deleteUser(userId);
      showAlert('success', `User "${userName}" deleted successfully`);
      fetchUsers();
    } catch (err: any) {
      showAlert('error', err.message || 'Failed to delete user');
    }
  };

  const totalPages = Math.ceil(total / limit);

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
            <Search
              size={16}
              className="absolute left-3 top-1/2 -translate-y-1/2 text-warm-400"
            />
            <input
              type="text"
              placeholder="Search by name or email..."
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
              className="w-full pl-9 pr-3 py-2 border border-warm-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-400"
            />
          </div>
          <select
            value={roleFilter}
            onChange={(e) => {
              setRoleFilter(e.target.value);
              setPage(1);
            }}
            className="px-3 py-2 border border-warm-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-400"
          >
            <option value="">All Roles</option>
            <option value="CUSTOMER">Customer</option>
            <option value="WORKER">Worker</option>
            <option value="ADMIN">Admin</option>
          </select>
          <select
            value={statusFilter}
            onChange={(e) => {
              setStatusFilter(e.target.value);
              setPage(1);
            }}
            className="px-3 py-2 border border-warm-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-400"
          >
            <option value="">All Status</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
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
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">
                    User
                  </th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">
                    Role
                  </th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">
                    Status
                  </th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-warm-500 uppercase">
                    Joined
                  </th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-warm-500 uppercase">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {users.map((user) => (
                  <tr key={user.id} className="hover:bg-warm-50">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 bg-primary-100 rounded-full flex items-center justify-center flex-shrink-0">
                          {user.avatarUrl ? (
                            <img
                              src={user.avatarUrl}
                              alt=""
                              className="w-9 h-9 rounded-full object-cover"
                            />
                          ) : (
                            <span className="text-primary-800 text-sm font-medium">
                              {user.name?.[0]?.toUpperCase() || '?'}
                            </span>
                          )}
                        </div>
                        <div className="min-w-0">
                          <p className="text-sm font-medium text-warm-800 truncate">
                            {user.name}
                          </p>
                          <p className="text-xs text-warm-500 truncate">
                            {user.email}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <RoleBadge role={user.role} />
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${
                          user.isActive
                            ? 'bg-green-100 text-green-700'
                            : 'bg-red-100 text-red-700'
                        }`}
                      >
                        <span
                          className={`w-1.5 h-1.5 rounded-full ${
                            user.isActive ? 'bg-green-500' : 'bg-red-500'
                          }`}
                        />
                        {user.isActive ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm text-warm-500">
                      {new Date(user.createdAt).toLocaleDateString()}
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => setSelectedUser(user)}
                          className="p-1.5 text-warm-400 hover:text-primary-600 hover:bg-primary-50 rounded-lg transition-colors"
                          title="View details"
                        >
                          <Eye size={16} />
                        </button>
                        <button
                          onClick={() => toggleStatus(user.id, user.isActive)}
                          className={`p-1.5 rounded-lg transition-colors ${
                            user.isActive
                              ? 'text-warm-400 hover:text-red-600 hover:bg-red-50'
                              : 'text-warm-400 hover:text-green-600 hover:bg-green-50'
                          }`}
                          title={user.isActive ? 'Deactivate' : 'Activate'}
                        >
                          {user.isActive ? (
                            <UserX size={16} />
                          ) : (
                            <UserCheck size={16} />
                          )}
                        </button>
                        <button
                          onClick={() => handleDelete(user.id, user.name)}
                          className="p-1.5 text-warm-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                          title="Delete user"
                        >
                          <Trash2 size={16} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {users.length === 0 && (
                  <tr>
                    <td
                      colSpan={5}
                      className="text-center py-8 text-sm text-warm-400"
                    >
                      No users found
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination */}
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
                className="p-1.5 rounded-lg text-warm-400 hover:text-warm-700 hover:bg-warm-100 disabled:opacity-30 disabled:cursor-not-allowed"
              >
                <ChevronLeft size={18} />
              </button>
              <span className="px-3 py-1 text-sm text-warm-700">
                {page} / {totalPages}
              </span>
              <button
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="p-1.5 rounded-lg text-warm-400 hover:text-warm-700 hover:bg-warm-100 disabled:opacity-30 disabled:cursor-not-allowed"
              >
                <ChevronRight size={18} />
              </button>
            </div>
          </div>
        )}
      </div>

      {/* User Detail Modal */}
      {selectedUser && (
        <UserDetailModal
          user={selectedUser}
          onClose={() => setSelectedUser(null)}
        />
      )}
    </div>
  );
}

function UserDetailModal({ user, onClose }: { user: any; onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl max-w-lg w-full max-h-[80vh] overflow-y-auto">
        <div className="p-6 border-b border-warm-300 flex items-center justify-between">
          <h3 className="font-semibold text-warm-800">User Details</h3>
          <button
            onClick={onClose}
            className="text-warm-400 hover:text-warm-700"
          >
            &times;
          </button>
        </div>
        <div className="p-6 space-y-4">
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center">
              {user.avatarUrl ? (
                <img
                  src={user.avatarUrl}
                  alt=""
                  className="w-16 h-16 rounded-full object-cover"
                />
              ) : (
                <span className="text-primary-800 text-xl font-bold">
                  {user.name?.[0]?.toUpperCase() || '?'}
                </span>
              )}
            </div>
            <div>
              <h4 className="text-lg font-semibold text-warm-800">{user.name}</h4>
              <p className="text-sm text-warm-500">{user.email}</p>
              <div className="flex items-center gap-2 mt-1">
                <RoleBadge role={user.role} />
                <span
                  className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                    user.isActive
                      ? 'bg-green-100 text-green-700'
                      : 'bg-red-100 text-red-700'
                  }`}
                >
                  {user.isActive ? 'Active' : 'Inactive'}
                </span>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <InfoItem label="Phone" value={user.phone || 'N/A'} />
            <InfoItem label="Joined" value={new Date(user.createdAt).toLocaleDateString()} />
            <InfoItem label="User ID" value={user.id} />
            <InfoItem label="Firebase UID" value={user.firebaseUid || 'N/A'} />
          </div>

          {user.workerProfile && (
            <div className="border-t border-warm-300 pt-4">
              <h5 className="font-medium text-warm-800 mb-3">Worker Profile</h5>
              <div className="grid grid-cols-2 gap-4">
                <InfoItem label="NIC" value={user.workerProfile.nicNumber || 'N/A'} />
                <InfoItem label="Verification" value={user.workerProfile.verificationStatus} />
                <InfoItem label="Rating" value={`${user.workerProfile.rating} / 5`} />
                <InfoItem label="Total Jobs" value={user.workerProfile.totalJobs} />
                <InfoItem label="Available" value={user.workerProfile.isAvailable ? 'Yes' : 'No'} />
                <InfoItem label="Bio" value={user.workerProfile.bio || 'N/A'} />
              </div>
              <div className="flex gap-2 mt-3">
                {user.workerProfile.verificationStatus !== 'VERIFIED' && (
                  <button
                    onClick={async () => {
                      try {
                        await verifyWorker(user.id, { status: 'VERIFIED' });
                        onClose();
                      } catch (err: any) {
                        alert(err.message || 'Failed to verify');
                      }
                    }}
                    className="px-3 py-1.5 bg-green-50 text-green-700 border border-green-200 rounded-lg text-xs font-medium hover:bg-green-100 transition-colors"
                  >
                    Verify Worker
                  </button>
                )}
                {user.workerProfile.verificationStatus === 'VERIFIED' && (
                  <button
                    onClick={async () => {
                      if (!window.confirm('Revoke this worker\'s verification?')) return;
                      try {
                        await verifyWorker(user.id, { status: 'PENDING' });
                        onClose();
                      } catch (err: any) {
                        alert(err.message || 'Failed to revoke');
                      }
                    }}
                    className="px-3 py-1.5 bg-red-50 text-red-700 border border-red-200 rounded-lg text-xs font-medium hover:bg-red-100 transition-colors"
                  >
                    Revoke Verification
                  </button>
                )}
              </div>
            </div>
          )}

          {user.customerProfile && (
            <div className="border-t border-warm-300 pt-4">
              <h5 className="font-medium text-warm-800 mb-3">Customer Profile</h5>
              <div className="grid grid-cols-2 gap-4">
                <InfoItem label="Address" value={user.customerProfile.address || 'N/A'} />
                <InfoItem
                  label="Location"
                  value={
                    user.customerProfile.latitude
                      ? `${user.customerProfile.latitude}, ${user.customerProfile.longitude}`
                      : 'N/A'
                  }
                />
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function InfoItem({ label, value }: { label: string; value: any }) {
  return (
    <div>
      <p className="text-xs text-warm-500">{label}</p>
      <p className="text-sm font-medium text-warm-800 break-all">{String(value)}</p>
    </div>
  );
}

function RoleBadge({ role }: { role: string }) {
  const styles: Record<string, string> = {
    CUSTOMER: 'bg-blue-100 text-blue-700',
    WORKER: 'bg-green-100 text-green-700',
    ADMIN: 'bg-purple-100 text-purple-700',
  };
  return (
    <span
      className={`px-2 py-0.5 rounded-full text-xs font-medium ${
        styles[role] || 'bg-warm-100 text-warm-700'
      }`}
    >
      {role}
    </span>
  );
}
