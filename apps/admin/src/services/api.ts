const API_BASE = '/api';

async function request<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const token = localStorage.getItem('admin_token');

  const res = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  if (res.status === 401) {
    localStorage.removeItem('admin_token');
    window.location.href = '/login';
    throw new Error('Unauthorized');
  }

  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: 'Request failed' }));
    throw new Error(err.error || err.message || `HTTP ${res.status}`);
  }

  return res.json();
}

// Auth
export const login = (email: string, password: string) =>
  request<{ token: string; user: any }>('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });

export const getMe = () => request<any>('/auth/me');

// Admin Stats
export const getStats = () => request<any>('/admin/stats');

// Users
export const getUsers = (params: Record<string, string>) => {
  const qs = new URLSearchParams(params).toString();
  return request<any>(`/admin/users?${qs}`);
};

export const getUser = (id: string) => request<any>(`/admin/users/${id}`);

export const updateUserStatus = (id: string, isActive: boolean) =>
  request<any>(`/admin/users/${id}/status`, {
    method: 'PATCH',
    body: JSON.stringify({ isActive }),
  });

export const deleteUser = (id: string) =>
  request<any>(`/admin/users/${id}`, { method: 'DELETE' });

// Worker Verification
export const getPendingWorkers = () =>
  request<any>('/admin/workers/pending');

export const getAllWorkers = (status?: string) => {
  const qs = status ? `?status=${status}` : '';
  return request<any>(`/admin/workers${qs}`);
};

export const verifyWorker = (userId: string, data: {
  status?: 'VERIFIED' | 'REJECTED' | 'PENDING';
  rejectionReason?: string;
  nicVerified?: boolean;
  qualificationsVerified?: boolean;
  backgroundCheckVerified?: boolean;
}) =>
  request<any>(`/users/${userId}/verify`, {
    method: 'PATCH',
    body: JSON.stringify(data),
  });

// Jobs
export const getJobs = (params: Record<string, string>) => {
  const qs = new URLSearchParams(params).toString();
  return request<any>(`/admin/jobs?${qs}`);
};

export const getJob = (id: string) => request<any>(`/jobs/${id}`);

// Categories
export const getCategories = () => request<any>('/categories');

export const createCategory = (data: { name: string; description?: string; iconUrl?: string }) =>
  request<any>('/categories', {
    method: 'POST',
    body: JSON.stringify(data),
  });

export const updateCategory = (id: string, data: { name?: string; description?: string; iconUrl?: string }) =>
  request<any>(`/categories/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  });

export const deleteCategory = (id: string) =>
  request<any>(`/categories/${id}`, { method: 'DELETE' });

// Payments
export const getPayments = (params: Record<string, string>) => {
  const qs = new URLSearchParams(params).toString();
  return request<any>(`/admin/payments?${qs}`);
};

// Payments - Admin Actions
export const adminReleasePayment = (jobId: string) =>
  request<any>(`/payments/${jobId}/release`, { method: 'POST' });

export const adminRefundPayment = (jobId: string) =>
  request<any>(`/payments/${jobId}/status`, {
    method: 'PATCH',
    body: JSON.stringify({ status: 'REFUNDED' }),
  });

// Matching Demo
export const getMatchingWorkers = () => request<any>('/admin/matching/workers');
export const getMatchingJobs = () => request<any>('/admin/matching/jobs');
export const simulatePresence = () =>
  request<any>('/admin/matching/simulate', { method: 'POST' });
export const runMatching = (jobId: string) =>
  request<any>(`/admin/matching/run/${jobId}`, { method: 'POST' });

// Jobs - Admin Actions
export const adminCloseJob = (id: string) =>
  request<any>(`/admin/jobs/${id}/close`, { method: 'PATCH' });

// Disputes
export const getDisputes = () => request<any>('/admin/disputes');

export const resolveDispute = (id: string, data: {
  resolution: 'refund_customer' | 'pay_worker' | 'no_compensation';
  notes?: string;
}) =>
  request<any>(`/admin/disputes/${id}/resolve`, {
    method: 'PATCH',
    body: JSON.stringify(data),
  });
