import { ReactNode, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { Box, CircularProgress, Typography, Button } from '@mui/material';

interface ProtectedRouteProps {
  children: ReactNode;
}

const ProtectedRoute = ({ children }: ProtectedRouteProps) => {
  const { user, isLoading } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  console.log('🛡️  ProtectedRoute - user:', user, 'isLoading:', isLoading, 'path:', location.pathname);

  useEffect(() => {
    console.log('🛡️  ProtectedRoute useEffect - user:', user, 'isLoading:', isLoading);
    
    if (!isLoading && !user) {
      console.log('🔄 Usuário não autenticado, redirecionando para login...');
      navigate('/login', { 
        state: { from: location },
        replace: true 
      });
    }
  }, [user, isLoading, navigate, location]);

  // Aguardar carregamento inicial
  if (isLoading) {
    console.log('⏳ ProtectedRoute - Carregando...');
    return (
      <Box
        sx={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          height: '100vh',
          gap: 2
        }}
      >
        <CircularProgress size={60} />
        <Typography variant="h6">Verificando autenticação...</Typography>
        <Typography variant="body2" color="textSecondary">
          Aguarde enquanto validamos seu acesso...
        </Typography>
      </Box>
    );
  }

  // Se não tem usuário após carregamento, está redirecionando
  if (!user) {
    console.log('❌ ProtectedRoute - Sem usuário, redirecionando...');
    return (
      <Box
        sx={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          height: '100vh',
          gap: 2
        }}
      >
        <Typography variant="h5">Redirecionando...</Typography>
        <Typography>Você precisa estar logado para acessar esta página.</Typography>
        <Button 
          variant="contained" 
          onClick={() => navigate('/login')}
        >
          Ir para Login
        </Button>
      </Box>
    );
  }

  console.log('✅ ProtectedRoute - Usuário autenticado, mostrando conteúdo...');
  return <>{children}</>;
};

export default ProtectedRoute;
