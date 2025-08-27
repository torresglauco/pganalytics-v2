import { Box, Typography, Button } from '@mui/material';
import { useNavigate } from 'react-router-dom';

const TestPage = () => {
  const navigate = useNavigate();

  return (
    <Box sx={{ p: 4, textAlign: 'center' }}>
      <Typography variant="h3" color="primary" gutterBottom>
        🧪 PÁGINA DE TESTE - FRONTEND FUNCIONANDO!
      </Typography>
      <Typography variant="h6" gutterBottom>
        Se você está vendo isso, o React está funcionando perfeitamente!
      </Typography>
      <Box sx={{ mt: 4, display: 'flex', gap: 2, justifyContent: 'center' }}>
        <Button variant="contained" onClick={() => navigate('/login')}>
          Testar Login
        </Button>
        <Button variant="outlined" onClick={() => navigate('/register')}>
          Testar Register
        </Button>
      </Box>
    </Box>
  );
};

export default TestPage;
