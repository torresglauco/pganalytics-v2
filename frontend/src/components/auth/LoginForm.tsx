import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  Alert,
  CircularProgress,
  Container,
  Fade
} from '@mui/material';
import { useAuth } from '../../contexts/AuthContext';

interface LocationState {
  from?: {
    pathname: string;
  };
}

const LoginForm: React.FC = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [progress, setProgress] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  
  const { login, user } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  
  const locationState = location.state as LocationState;
  const from = locationState?.from?.pathname || '/dashboard';

  // Se o usuário já está logado, redireciona imediatamente
  React.useEffect(() => {
    if (user) {
      navigate(from, { replace: true });
    }
  }, [user, navigate, from]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (isLoading) return; // Previne múltiplas submissões
    
    setError('');
    setProgress('');
    setIsLoading(true);

    try {
      setProgress('🔐 Verificando credenciais...');
      
      await login(username, password);
      
      setProgress('✅ Login realizado! Redirecionando...');
      
      // O redirecionamento será feito pelo useEffect acima quando user for atualizado
      
    } catch (error: any) {
      console.error('Erro no login:', error);
      setError(
        error.response?.data?.detail || 
        error.message || 
        'Erro ao fazer login. Verifique suas credenciais.'
      );
      setProgress('');
    } finally {
      setIsLoading(false);
    }
  };

  // Se o usuário já está logado, não mostra o formulário
  if (user) {
    return (
      <Container maxWidth="sm">
        <Box
          display="flex"
          justifyContent="center"
          alignItems="center"
          minHeight="100vh"
        >
          <CircularProgress />
        </Box>
      </Container>
    );
  }

  return (
    <Container maxWidth="sm">
      <Box
        display="flex"
        justifyContent="center"
        alignItems="center"
        minHeight="100vh"
      >
        <Fade in timeout={800}>
          <Card elevation={3} sx={{ width: '100%', maxWidth: 400 }}>
            <CardContent sx={{ p: 4 }}>
              <Typography variant="h4" component="h1" gutterBottom align="center">
                PG Analytics
              </Typography>
              <Typography variant="h6" component="h2" gutterBottom align="center" color="textSecondary">
                Faça login em sua conta
              </Typography>

              <Box component="form" onSubmit={handleSubmit} sx={{ mt: 3 }}>
                <TextField
                  fullWidth
                  label="Usuário"
                  variant="outlined"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  required
                  disabled={isLoading}
                  sx={{ mb: 2 }}
                />
                
                <TextField
                  fullWidth
                  label="Senha"
                  type="password"
                  variant="outlined"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  disabled={isLoading}
                  sx={{ mb: 3 }}
                />

                <Button
                  type="submit"
                  fullWidth
                  variant="contained"
                  size="large"
                  disabled={isLoading || !username.trim() || !password.trim()}
                  sx={{ mb: 2 }}
                >
                  {isLoading ? (
                    <CircularProgress size={24} color="inherit" />
                  ) : (
                    'Entrar'
                  )}
                </Button>

                {progress && (
                  <Alert severity="info" sx={{ mb: 2 }}>
                    {progress}
                  </Alert>
                )}

                {error && (
                  <Alert severity="error">
                    {error}
                  </Alert>
                )}
              </Box>
            </CardContent>
          </Card>
        </Fade>
      </Box>
    </Container>
  );
};

export default LoginForm;