import { useState } from 'react';
import { Link, useLocation, Outlet } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useLanguage } from '../context/LanguageContext';
import {
  LayoutDashboard,
  Users,
  Briefcase,
  ShieldCheck,
  FolderOpen,
  CreditCard,
  AlertTriangle,
  Zap,
  LogOut,
  Menu,
  X,
  ChevronRight,
  Languages,
} from 'lucide-react';

export default function Layout() {
  const { user, logout } = useAuth();
  const { lang, setLang, t } = useLanguage();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const navItems = [
    { path: '/', label: t('dashboard'), icon: LayoutDashboard },
    { path: '/users', label: t('users'), icon: Users },
    { path: '/verification', label: t('verification'), icon: ShieldCheck },
    { path: '/jobs', label: t('jobs'), icon: Briefcase },
    { path: '/categories', label: t('categories'), icon: FolderOpen },
    { path: '/payments', label: t('payments'), icon: CreditCard },
    { path: '/disputes', label: t('disputes'), icon: AlertTriangle },
    { path: '/matching', label: t('matchingDemo'), icon: Zap },
  ];

  return (
    <div className="min-h-screen bg-warm-50 flex">
      {/* Mobile overlay */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black/50 z-40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`fixed lg:static inset-y-0 left-0 z-50 w-64 bg-white border-r border-warm-300 transform transition-transform lg:transform-none ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
        }`}
      >
        <div className="flex items-center justify-between h-16 px-6 border-b border-warm-300">
          <Link to="/" className="flex items-center gap-2">
            <img src="/doer_logo.png" alt="Doer" className="w-9 h-9 object-contain" />
            <span className="text-lg font-bold text-warm-800">Doer Admin</span>
          </Link>
          <button
            className="lg:hidden text-warm-500 hover:text-warm-700"
            onClick={() => setSidebarOpen(false)}
          >
            <X size={20} />
          </button>
        </div>

        <nav className="p-4 space-y-1">
          {navItems.map((item) => {
            const isActive =
              item.path === '/'
                ? location.pathname === '/'
                : location.pathname.startsWith(item.path);
            const Icon = item.icon;
            return (
              <Link
                key={item.path}
                to={item.path}
                onClick={() => setSidebarOpen(false)}
                className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-primary-50 text-primary-800'
                    : 'text-warm-600 hover:bg-warm-100 hover:text-warm-800'
                }`}
              >
                <Icon size={18} />
                {item.label}
                {isActive && (
                  <ChevronRight size={16} className="ml-auto" />
                )}
              </Link>
            );
          })}
        </nav>

        <div className="absolute bottom-0 left-0 right-0 p-4 border-t border-warm-300">
          <div className="flex items-center gap-3 px-3 py-2">
            <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center">
              <span className="text-primary-800 text-sm font-medium">
                {user?.name?.[0]?.toUpperCase() || 'A'}
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-warm-800 truncate">
                {user?.name || 'Admin'}
              </p>
              <p className="text-xs text-warm-500 truncate">{user?.email}</p>
            </div>
            <button
              onClick={logout}
              className="text-warm-400 hover:text-red-600 transition-colors"
              title={t('logout')}
            >
              <LogOut size={18} />
            </button>
          </div>
        </div>
      </aside>

      {/* Main content */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Top bar */}
        <header className="h-16 bg-white border-b border-warm-300 flex items-center px-4 lg:px-6 gap-4">
          <button
            className="lg:hidden text-warm-500 hover:text-warm-700 mr-2"
            onClick={() => setSidebarOpen(true)}
          >
            <Menu size={24} />
          </button>
          <h1 className="text-lg font-semibold text-warm-800 flex-1">
            {navItems.find(
              (item) =>
                item.path === '/'
                  ? location.pathname === '/'
                  : location.pathname.startsWith(item.path)
            )?.label || t('adminPanel')}
          </h1>

          {/* Language toggle */}
          <button
            onClick={() => setLang(lang === 'en' ? 'si' : 'en')}
            className="flex items-center gap-1.5 px-3 py-1.5 border border-warm-300 rounded-lg text-sm text-warm-600 hover:bg-warm-50 transition-colors"
            title={t('language')}
          >
            <Languages size={15} />
            <span className="font-medium">{lang === 'si' ? 'සිං' : 'EN'}</span>
          </button>
        </header>

        {/* Page content */}
        <main className="flex-1 p-4 lg:p-6 overflow-auto">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
