import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { api } from '../services/api';

// Interface baseada na resposta real do /me
interface User {
  id: number;
  username: string;
  email: string;
  full_name: string;
  role: string;
  is_active: boolean;
  is_verified: boolean;
  created_at: string;
  last_login: string | null;
}

interface LoginCredentials {
  username: string;
  password: string;
}

interface RegisterData {
  username: string;
  email: string;
  password: string;
  full_name: string;
  confirm_password: string;
}

// Interface baseada na resposta real do login
interface LoginResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
  expires_in: number;
}

interface AuthContextType {
  user: User | null;
  login: (credentials: LoginCredentials) => Promise<void>;
  register: (data: RegisterData) => Promise<void>;
  logout: () => void;
  isLoading: boolean;
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

export const AuthProvider = ({ children }: AuthProviderProps) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  console.log('🔐 AuthProvider - user:', user, 'isLoading:', isLoading);

  useEffect(() => {
    console.log('🔐 AuthProvider useEffect iniciado');
    const token = localStorage.getItem('access_token');
    console.log('🔐 Token encontrado:', token ? 'SIM' : 'NÃO');
    
    if (token) {
      api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
      checkAuthStatus();
    } else {
      console.log('🔐 Sem token, definindo isLoading = false');
      setIsLoading(false);
    }
  }, []);

  const checkAuthStatus = async () => {
    console.log('🔐 Verificando status de auth...');
    try {
      const response = await api.get<User>('/api/v1/auth/me');
      console.log('🔐 Resposta do /me:', response.data);
      setUser(response.data);
    } catch (error) {
      console.log('🔐 Erro ao verificar auth:', error);
      logout();
    } finally {
      console.log('🔐 Definindo isLoading = false');
      setIsLoading(false);
    }
  };

  const login = async (credentials: LoginCredentials) => {
    console.log('🔐 Tentando login para:', credentials.username);
    try {
      setIsLoading(true);
      
      // PASSO 1: Fazer login e obter token
      console.log('🔐 PASSO 1: Fazendo login...');
      const loginResponse = await api.post<LoginResponse>('/api/v1/auth/login', credentials);
      const loginData = loginResponse.data;
      console.log('🔐 Login bem-sucedido, token recebido');
      
      // PASSO 2: Salvar tokens
      console.log('🔐 PASSO 2: Salvando tokens...');
      localStorage.setItem('access_token', loginData.access_token);
      localStorage.setItem('refresh_token', loginData.refresh_token);
      
      // PASSO 3: Configurar header de autorização
      console.log('🔐 PASSO 3: Configurando header...');
      api.defaults.headers.common['Authorization'] = `Bearer ${loginData.access_token}`;
      
      // PASSO 4: Buscar dados do usuário
      console.log('🔐 PASSO 4: Buscando dados do usuário...');
      const userResponse = await api.get<User>('/api/v1/auth/me');
      const userData = userResponse.data;
      console.log('🔐 Dados do usuário recebidos:', userData);
      
      // PASSO 5: Definir usuário no estado
      console.log('🔐 PASSO 5: Definindo usuário no estado...');
      setUser(userData);
      
      console.log('🔐 ✅ LOGIN COMPLETO!');
      
    } catch (error: any) {
      console.log('🔐 ❌ Erro no login:', error);
      logout(); // Limpar qualquer estado parcial
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const register = async (data: RegisterData) => {
    console.log('🔐 Tentando registro para:', data.username);
    try {
      setIsLoading(true);
      
      // PASSO 1: Fazer registro
      console.log('🔐 PASSO 1: Fazendo registro...');
      const registerResponse = await api.post('/api/v1/auth/register', data);
      console.log('🔐 Registro bem-sucedido');
      
      // PASSO 2: Se registro retornar tokens, usar
      if (registerResponse.data.access_token) {
        const authData = registerResponse.data;
        localStorage.setItem('access_token', authData.access_token);
        if (authData.refresh_token) {
          localStorage.setItem('refresh_token', authData.refresh_token);
        }
        api.defaults.headers.common['Authorization'] = `Bearer ${authData.access_token}`;
        
        // Buscar dados completos do usuário
        const userResponse = await api.get<User>('/api/v1/auth/me');
        setUser(userResponse.data);
      } else {
        // Se registro não retornar tokens, fazer login
        await login({ username: data.username, password: data.password });
      }
      
    } catch (error: any) {
      console.log('🔐 Erro no registro:', error);
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    console.log('🔐 Fazendo logout...');
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
    delete api.defaults.headers.common['Authorization'];
    setUser(null);
  };

  const value = {
    user,
    login,
    register,
    logout,
    isLoading,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
