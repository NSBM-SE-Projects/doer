export interface User {
  id: string;
  firebaseUid: string | null;
  email: string;
  name: string;
  phone: string | null;
  avatarUrl: string | null;
  role: 'CUSTOMER' | 'WORKER' | 'ADMIN';
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
  customerProfile?: CustomerProfile;
  workerProfile?: WorkerProfile;
}

export interface CustomerProfile {
  id: string;
  userId: string;
  address: string | null;
  latitude: number | null;
  longitude: number | null;
}

export type BadgeLevel = 'TRAINEE' | 'BRONZE' | 'SILVER' | 'GOLD' | 'PLATINUM';

export interface QualificationDoc {
  id: string;
  title: string;
  url: string;
  workerId: string;
}

export interface WorkerProfile {
  id: string;
  userId: string;
  bio: string | null;
  latitude: number | null;
  longitude: number | null;
  nicNumber: string | null;
  nicFrontUrl: string | null;
  nicBackUrl: string | null;
  backgroundCheckUrl: string | null;
  badgeLevel: BadgeLevel;
  rejectionReason: string | null;
  verificationStatus: 'NOT_SUBMITTED' | 'PENDING' | 'VERIFIED' | 'REJECTED';
  isAvailable: boolean;
  rating: number;
  totalJobs: number;
  categories?: { category: ServiceCategory }[];
  qualificationDocs?: QualificationDoc[];
}

export interface ServiceCategory {
  id: string;
  name: string;
  description: string | null;
  iconUrl: string | null;
}

export interface Job {
  id: string;
  title: string;
  description: string | null;
  status: JobStatus;
  price: number | null;
  budgetMin: number | null;
  budgetMax: number | null;
  urgency: 'LOW' | 'NORMAL' | 'URGENT' | 'EMERGENCY';
  latitude: number | null;
  longitude: number | null;
  address: string | null;
  scheduledAt: string | null;
  scheduledEnd: string | null;
  completedAt: string | null;
  createdAt: string;
  updatedAt: string;
  customerId: string;
  workerId: string | null;
  categoryId: string;
  customer?: { user: User };
  worker?: { user: User };
  category?: ServiceCategory;
  payment?: Payment;
  review?: Review;
  _count?: { applications: number; messages: number };
}

export type JobStatus =
  | 'OPEN'
  | 'APPLICATIONS_RECEIVED'
  | 'ASSIGNED'
  | 'IN_PROGRESS'
  | 'COMPLETED'
  | 'REVIEWING'
  | 'CLOSED'
  | 'CANCELLED';

export interface Payment {
  id: string;
  amount: number;
  status: 'PENDING' | 'COMPLETED' | 'FAILED' | 'REFUNDED';
  payhereRef: string | null;
  createdAt: string;
  jobId: string;
  job?: Job;
}

export interface Review {
  id: string;
  rating: number;
  comment: string | null;
  createdAt: string;
  jobId: string;
  customerId: string;
  workerId: string;
}

export interface Notification {
  id: string;
  title: string;
  body: string;
  isRead: boolean;
  createdAt: string;
  userId: string;
}

export interface DashboardStats {
  users: {
    total: number;
    customers: number;
    workers: number;
    admins: number;
  };
  jobs: {
    total: number;
    open: number;
    inProgress: number;
    completed: number;
    cancelled: number;
  };
  payments: {
    total: number;
    totalRevenue: number;
    completed: number;
    pending: number;
  };
  pendingVerifications: number;
  recentJobs: Job[];
  monthlyRevenue: { month: string; revenue: number }[];
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface JobApplication {
  id: string;
  status: 'PENDING' | 'ACCEPTED' | 'REJECTED' | 'WITHDRAWN';
  message: string | null;
  price: number | null;
  createdAt: string;
  updatedAt: string;
  jobId: string;
  workerId: string;
  worker?: { user: User };
  job?: Job;
}
