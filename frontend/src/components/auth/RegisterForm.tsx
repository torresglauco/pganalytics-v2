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
} from '@mui/material';
import { useAuth } from '../../contexts/AuthContext';

const RegisterForm = () => {
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [fullName, setFullName] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const { register, isLoading } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (password !== confirmPassword) {
      setError('As senhas não coincidem');
      return;
    }

    if (password.length < 8) {
      setError('A senha deve ter pelo menos 8 caracteres');
      return;
    }

    if (!/[A-Z]/.test(password)) {
      setError('A senha deve conter pelo menos uma letra maiúscula');
      return;
    }

    if (!/[0-9]/.test(password)) {
      setError('A senha deve conter pelo menos um número');
      return;
    }

    try {
      await register({ 
        username, 
        email, 
        password,
        full_name: fullName,
        confirm_password: confirmPassword
      });
      navigate('/dashboard');
    } catch (err: any) {
      console.error('Erro no registro:', err);
      const errorMessage = err.response?.data?.detail || 'Erro ao criar conta';
      if (Array.isArray(errorMessage)) {
        setError(errorMessage.map((e: any) => e.msg).join(', '));
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
        <Card sx={{ width: '100%', maxWidth: 500 }}>
          <CardContent sx={{ p: 4 }}>
            <Typography variant="h4" component="h1" gutterBottom align="center">
              PG Analytics
            </Typography>
            <Typography variant="h6" component="h2" gutterBottom align="center" color="textSecondary">
              Criar Conta
            </Typography>
            
            {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
            
            <Alert severity="info" sx={{ mb: 2 }}>
              A senha deve ter:
              <ul style={{ margin: '8px 0', paddingLeft: '20px' }}>
                <li>Pelo menos 8 caracteres</li>
                <li>Pelo menos uma letra maiúscula</li>
                <li>Pelo menos um número</li>
              </ul>
            </Alert>
            
            <form onSubmit={handleSubmit}>
              <TextField
                fullWidth
                label="Nome Completo"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                margin="normal"
                required
                autoFocus
              />
              <TextField
                fullWidth
                label="Usuário"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                margin="normal"
                required
              />
              <TextField
                fullWidth
                type="email"
                label="Email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                margin="normal"
                required
              />
              <TextField
                fullWidth
                type="password"
                label="Senha"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                margin="normal"
                required
                helperText="Min 8 caracteres, 1 maiúscula, 1 número"
              />
              <TextField
                fullWidth
                type="password"
                label="Confirmar Senha"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
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
                {isLoading ? 'Criando...' : 'Criar Conta'}
              </Button>
            </form>
            
            <Box sx={{ textAlign: 'center', mt: 2 }}>
              <Button
                variant="text"
                onClick={() => navigate('/login')}
                disabled={isLoading}
              >
                Já tem conta? Faça login
              </Button>
            </Box>
          </CardContent>
        </Card>
      </Box>
    </Container>
  );
};

export default RegisterForm;
