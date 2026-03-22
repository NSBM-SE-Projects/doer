import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { login as apiLogin, getMe } from '../services/api';

interface AuthState {
  user: any | null;
  token: string | null;
  loading: boolean;
}

interface AuthContextType extends AuthState {
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AuthState>({
    user: null,
    token: localStorage.getItem('admin_token'),
    loading: true,
  });

  useEffect(() => {
    if (state.token) {
      getMe()
        .then((res) => {
          if (res.user?.role !== 'ADMIN') {
            localStorage.removeItem('admin_token');
            setState({ user: null, token: null, loading: false });
          } else {
            setState((s) => ({ ...s, user: res.user, loading: false }));
          }
        })
        .catch(() => {
          localStorage.removeItem('admin_token');
          setState({ user: null, token: null, loading: false });
        });
    } else {
      setState((s) => ({ ...s, loading: false }));
    }
  }, [state.token]);

  const login = async (email: string, password: string) => {
    const res = await apiLogin(email, password);
    if (res.user.role !== 'ADMIN') {
      throw new Error('Access denied. Admin privileges required.');
    }
    localStorage.setItem('admin_token', res.token);
    setState({ user: res.user, token: res.token, loading: false });
  };

  const logout = () => {
    localStorage.removeItem('admin_token');
    setState({ user: null, token: null, loading: false });
  };

  return (
    <AuthContext.Provider value={{ ...state, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
