import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import api from '../services/api';

export interface User {
  id: number;
  username: string;
  email: string;
  full_name: string;
  is_active: boolean;
  created_at: string;
}

interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  login: (username: string, password: string) => Promise<void>;
  logout: () => void;
  refreshToken: () => Promise<boolean>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Função para configurar o header de autorização
  const setAuthHeader = (token: string | null) => {
    if (token) {
      api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
    } else {
      delete api.defaults.headers.common['Authorization'];
    }
  };

  // Função para limpar dados de autenticação
  const clearAuthData = () => {
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
    setAuthHeader(null);
    setUser(null);
  };

  // Função para renovar token
  const refreshToken = async (): Promise<boolean> => {
    try {
      const refresh_token = localStorage.getItem('refresh_token');
      if (!refresh_token) {
        return false;
      }

      const response = await api.post('/api/v1/auth/refresh', {
        refresh_token: refresh_token
      });

      const { access_token, refresh_token: new_refresh_token } = response.data;
      
      localStorage.setItem('access_token', access_token);
      localStorage.setItem('refresh_token', new_refresh_token);
      setAuthHeader(access_token);

      return true;
    } catch (error) {
      console.error('Erro ao renovar token:', error);
      clearAuthData();
      return false;
    }
  };

  // Função para buscar dados do usuário
  const fetchUserData = async (): Promise<boolean> => {
    try {
      const response = await api.get('/api/v1/auth/me');
      setUser(response.data);
      return true;
    } catch (error) {
      console.error('Erro ao buscar dados do usuário:', error);
      
      // Tenta renovar o token
      const tokenRefreshed = await refreshToken();
      if (tokenRefreshed) {
        try {
          const response = await api.get('/api/v1/auth/me');
          setUser(response.data);
          return true;
        } catch (retryError) {
          console.error('Erro ao buscar dados do usuário após refresh:', retryError);
        }
      }
      
      clearAuthData();
      return false;
    }
  };

  // Função de login
  const login = async (username: string, password: string): Promise<void> => {
    try {
      const response = await api.post('/api/v1/auth/login', {
        username,
        password
      });

      const { access_token, refresh_token } = response.data;

      localStorage.setItem('access_token', access_token);
      localStorage.setItem('refresh_token', refresh_token);
      setAuthHeader(access_token);

      await fetchUserData();
    } catch (error) {
      console.error('Erro no login:', error);
      clearAuthData();
      throw error;
    }
  };

  // Função de logout
  const logout = () => {
    try {
      // Opcional: chamar endpoint de logout no backend
      api.post('/api/v1/auth/logout').catch(() => {
        // Ignora erros de logout no backend
      });
    } finally {
      clearAuthData();
    }
  };

  // Interceptor para renovação automática de token
  useEffect(() => {
    const responseInterceptor = api.interceptors.response.use(
      (response) => response,
      async (error) => {
        const originalRequest = error.config;

        if (error.response?.status === 401 && !originalRequest._retry) {
          originalRequest._retry = true;

          const tokenRefreshed = await refreshToken();
          if (tokenRefreshed) {
            return api(originalRequest);
          }
        }

        return Promise.reject(error);
      }
    );

    return () => {
      api.interceptors.response.eject(responseInterceptor);
    };
  }, []);

  // Inicialização: verifica se há token salvo
  useEffect(() => {
    const initializeAuth = async () => {
      const token = localStorage.getItem('access_token');
      
      if (token) {
        setAuthHeader(token);
        await fetchUserData();
      }
      
      setIsLoading(false);
    };

    initializeAuth();
  }, []);

  const value = {
    user,
    isLoading,
    login,
    logout,
    refreshToken
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};