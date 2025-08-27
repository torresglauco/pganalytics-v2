import { ReactNode, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { Box, CircularProgress, Typography, Button, Card, CardContent } from '@mui/material';

interface ProtectedRouteProps {
  children: ReactNode;
}

const ProtectedRoute = ({ children }: ProtectedRouteProps) => {
  const { user, isLoading } = useAuth();
  const navigate = useNavigate();

  console.log('🛡️  ProtectedRoute - user:', user, 'isLoading:', isLoading);

  useEffect(() => {
    console.log('🛡️  ProtectedRoute useEffect - user:', user, 'isLoading:', isLoading);
    
    if (!isLoading && !user) {
      console.log('🔄 Redirecionando para /login...');
      navigate('/login');
    }
  }, [user, isLoading, navigate]);

  if (isLoading) {
    console.log('⏳ ProtectedRoute - Mostrando loading...');
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
          Se esta tela persistir, há um problema no AuthContext
        </Typography>
        <Button 
          variant="outlined" 
          onClick={() => navigate('/login')}
        >
          Ir para Login Manualmente
        </Button>
      </Box>
    );
  }

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
        <Card>
          <CardContent>
            <Typography variant="h5" gutterBottom>🔄 Redirecionando...</Typography>
            <Typography>Se não redirecionou automaticamente:</Typography>
            <Button 
              variant="contained" 
              onClick={() => navigate('/login')}
              sx={{ mt: 2 }}
            >
              Clique aqui para Login
            </Button>
          </CardContent>
        </Card>
      </Box>
    );
  }

  console.log('✅ ProtectedRoute - Usuário autenticado, mostrando conteúdo...');
  return <>{children}</>;
};

export default ProtectedRoute;
