import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  TextField,
  Button,
  Typography,
  Alert,
  Card,
  CardContent,
  Container,
  LinearProgress,
} from '@mui/material';
import { useAuth } from '../../contexts/AuthContext';

const LoginForm = () => {
  const [username, setUsername] = useState('demo'); // Pre-fill para teste
  const [password, setPassword] = useState('Demo123!'); // Pre-fill para teste
  const [error, setError] = useState('');
  const [progress, setProgress] = useState('');
  const { login, isLoading, user } = useAuth();
  const navigate = useNavigate();

  console.log('🔐 LoginForm renderizado - user atual:', user);

  // Se já está logado, mostrar info e botão para dashboard
  if (user) {
    return (
      <Container maxWidth="sm">
        <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh' }}>
          <Card sx={{ width: '100%', maxWidth: 400 }}>
            <CardContent sx={{ p: 4, textAlign: 'center' }}>
              <Typography variant="h4" gutterBottom color="primary">
                ✅ Logado com Sucesso!
              </Typography>
              <Typography variant="h6" gutterBottom>
                Bem-vindo, {user.full_name}!
              </Typography>
              <Typography variant="body2" color="textSecondary" gutterBottom>
                Username: {user.username} | Role: {user.role}
              </Typography>
              <Button
                variant="contained"
                size="large"
                onClick={() => navigate('/dashboard')}
                sx={{ mt: 3 }}
              >
                Ir para Dashboard
              </Button>
            </CardContent>
          </Card>
        </Box>
      </Container>
    );
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setProgress('');
    
    console.log('🔐 Iniciando login para:', username);

    try {
      setProgress('🔐 Fazendo login...');
      await login({ username, password });
      
      setProgress('✅ Login bem-sucedido! Redirecionando...');
      
      // Aguardar um pouco e redirecionar
      setTimeout(() => {
        navigate('/dashboard');
      }, 1500);
      
    } catch (err: any) {
      console.error('🔐 Erro no login:', err);
      setProgress('');
      
      const errorMessage = err.response?.data?.detail || err.message || 'Erro ao fazer login';
      if (Array.isArray(errorMessage)) {
        setError(errorMessage.map((e: any) => e.msg || e).join(', '));
      } else {
        setError(errorMessage);
      }
    }
  };

  return (
    <Container maxWidth="sm">
      <Box
        sx={{
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          minHeight: '100vh',
        }}
      >
        <Card sx={{ width: '100%', maxWidth: 400 }}>
          <CardContent sx={{ p: 4 }}>
            <Typography variant="h4" component="h1" gutterBottom align="center">
              PG Analytics
            </Typography>
            <Typography variant="h6" component="h2" gutterBottom align="center" color="textSecondary">
              Login
            </Typography>
            
            {/* Progress */}
            {progress && (
              <Alert severity="info" sx={{ mb: 2 }}>
                {progress}
                {isLoading && <LinearProgress sx={{ mt: 1 }} />}
              </Alert>
            )}
            
            {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
            
            <form onSubmit={handleSubmit}>
              <TextField
                fullWidth
                label="Usuário"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                margin="normal"
                required
                autoFocus
              />
              <TextField
                fullWidth
                type="password"
                label="Senha"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                margin="normal"
                required
              />
              <Button
                type="submit"
                fullWidth
                variant="contained"
                size="large"
                sx={{ mt: 3, mb: 2 }}
                disabled={isLoading}
              >
                {isLoading ? 'Entrando...' : 'Entrar'}
              </Button>
            </form>
            
            <Box sx={{ textAlign: 'center', mt: 2 }}>
              <Button
                variant="text"
                onClick={() => navigate('/register')}
                disabled={isLoading}
              >
                Não tem conta? Registre-se
              </Button>
            </Box>
            
            {/* Debug info */}
            <Box sx={{ mt: 2, p: 1, bgcolor: 'grey.100', borderRadius: 1 }}>
              <Typography variant="caption" sx={{ fontFamily: 'monospace' }}>
                Debug: isLoading={isLoading.toString()}, 
                user={user ? user.username : 'null'}
              </Typography>
            </Box>
          </CardContent>
        </Card>
      </Box>
    </Container>
  );
};

export default LoginForm;
