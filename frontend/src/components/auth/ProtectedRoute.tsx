import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { Box, CircularProgress, Container } from '@mui/material';
import { useAuth } from '../../contexts/AuthContext';

interface ProtectedRouteProps {
  children: React.ReactNode;
  redirectToLogin?: boolean;
}

const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ 
  children, 
  redirectToLogin = true 
}) => {
  const { user, isLoading } = useAuth();
  const location = useLocation();

  // Enquanto está carregando, mostra indicador
  if (isLoading) {
    return (
      <Container maxWidth="sm">
        <Box
          display="flex"
          justifyContent="center"
          alignItems="center"
          minHeight="100vh"
          flexDirection="column"
        >
          <CircularProgress size={48} />
          <Box mt={2}>
            Verificando autenticação...
          </Box>
        </Box>
      </Container>
    );
  }

  // Se não está autenticado e deve redirecionar para login
  if (!user && redirectToLogin) {
    return (
      <Navigate
        to="/login"
        state={{ from: location }}
        replace
      />
    );
  }

  // Se não está autenticado e não deve redirecionar para login
  if (!user && !redirectToLogin) {
    return (
      <Navigate
        to="/login"
        replace
      />
    );
  }

  // Se está autenticado, renderiza o conteúdo
  return <>{children}</>;
};

export default ProtectedRoute;