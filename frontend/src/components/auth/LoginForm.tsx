import { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
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
  const [username, setUsername] = useState('demo');
  const [password, setPassword] = useState('Demo123!');
  const [error, setError] = useState('');
  const [progress, setProgress] = useState('');
  const { login, isLoading, user } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  console.log('🔐 LoginForm renderizado - user atual:', user);

  // Redirecionar automaticamente se já estiver logado
  useEffect(() => {
    console.log('🔐 LoginForm useEffect - user:', user, 'isLoading:', isLoading);
    
    if (user && !isLoading) {
      console.log('🔐 Usuário logado detectado, redirecionando...');
      const from = (location.state as any)?.from?.pathname || '/dashboard';
      navigate(from, { replace: true });
    }
  }, [user, isLoading, navigate, location]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setProgress('');
    
    console.log('🔐 Iniciando login para:', username);

    try {
      setProgress('🔐 Fazendo autenticação...');
      await login({ username, password });
      
      setProgress('✅ Login realizado! Redirecionando...');
      
      // Forçar redirecionamento após pequeno delay
      setTimeout(() => {
        const from = (location.state as any)?.from?.pathname || '/dashboard';
        console.log('🔐 Forçando redirecionamento para:', from);
        navigate(from, { replace: true });
      }, 1000);
      
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

  // Se usuário já está logado, mostrar redirecionamento
  if (user && !isLoading) {
    return (
      <Container maxWidth="sm">
        <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh' }}>
          <Card sx={{ width: '100%', maxWidth: 400 }}>
            <CardContent sx={{ p: 4, textAlign: 'center' }}>
              <Typography variant="h4" gutterBottom color="success.main">
                ✅ Já está logado!
              </Typography>
              <Typography variant="h6" gutterBottom>
                Olá, {user.full_name}!
              </Typography>
              <LinearProgress sx={{ my: 2 }} />
              <Typography variant="body2" color="textSecondary" gutterBottom>
                Redirecionando para o dashboard...
              </Typography>
              <Button
                variant="contained"
                size="large"
                onClick={() => navigate('/dashboard', { replace: true })}
                sx={{ mt: 2 }}
              >
                Ir Agora para Dashboard
              </Button>
            </CardContent>
          </Card>
        </Box>
      </Container>
    );
  }

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
            <Box sx={{ textAlign: 'center', mb: 3 }}>
              <Typography variant="h3" component="h1" gutterBottom color="primary">
                PG Analytics
              </Typography>
              <Typography variant="h6" component="h2" color="textSecondary">
                Faça login para continuar
              </Typography>
            </Box>
            
            {progress && (
              <Alert severity="success" sx={{ mb: 2 }}>
                {progress}
                {isLoading && <LinearProgress sx={{ mt: 1 }} />}
              </Alert>
            )}
            
            {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
            
            <Alert severity="info" sx={{ mb: 3 }}>
              <strong>Credenciais de teste:</strong><br />
              Usuário: demo | Senha: Demo123!
            </Alert>
            
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
                Criar nova conta
              </Button>
            </Box>
          </CardContent>
        </Card>
      </Box>
    </Container>
  );
};

export default LoginForm;
