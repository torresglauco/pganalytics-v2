import { ReactNode } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { Box, CircularProgress, Typography } from '@mui/material';

interface ProtectedRouteProps {
  children: ReactNode;
}

const ProtectedRoute = ({ children }: ProtectedRouteProps) => {
  const { user, isLoading } = useAuth();

  if (isLoading) {
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
        <CircularProgress />
        <Typography>Carregando...</Typography>
      </Box>
    );
  }

  if (!user) {
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
        <Typography variant="h5">Acesso negado</Typography>
        <Typography>Você precisa estar logado para acessar esta página.</Typography>
      </Box>
    );
  }

  return <>{children}</>;
};

export default ProtectedRoute;
