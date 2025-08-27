import { useState } from 'react';
import {
  Box,
  Container,
  Grid,
  Card,
  CardContent,
  Typography,
  Button,
  Alert,
  Paper,
  Chip,
} from '@mui/material';
import {
  Storage,
  Speed,
  Timeline,
  Settings as SettingsIcon,
} from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import Header from './Header';

const Dashboard = () => {
  const { user } = useAuth();
  const [selectedDatabase, setSelectedDatabase] = useState<string | null>(null);

  const mockDatabases = [
    { name: 'production_db', status: 'online', size: '2.3 GB', connections: 45 },
    { name: 'staging_db', status: 'online', size: '856 MB', connections: 8 },
    { name: 'analytics_db', status: 'maintenance', size: '4.1 GB', connections: 0 },
  ];

  const mockMetrics = [
    { title: 'Active Connections', value: '53', icon: <Speed /> },
    { title: 'Database Size', value: '7.3 GB', icon: <Storage /> },
    { title: 'Queries/sec', value: '1,247', icon: <Timeline /> },
  ];

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: 'grey.50' }}>
      <Header />
      
      <Container maxWidth="lg" sx={{ py: 4 }}>
        {/* Welcome Section */}
        <Box sx={{ mb: 4 }}>
          <Typography variant="h4" gutterBottom>
            Dashboard
          </Typography>
          <Typography variant="body1" color="textSecondary">
            Bem-vindo, {user?.full_name}! Monitore suas bases de dados PostgreSQL.
          </Typography>
        </Box>

        {/* Metrics Cards */}
        <Grid container spacing={3} sx={{ mb: 4 }}>
          {mockMetrics.map((metric, index) => (
            <Grid item xs={12} sm={6} md={4} key={index}>
              <Card>
                <CardContent>
                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                    {metric.icon}
                    <Typography variant="h6" sx={{ ml: 1 }}>
                      {metric.title}
                    </Typography>
                  </Box>
                  <Typography variant="h3" color="primary">
                    {metric.value}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>

        {/* Database List */}
        <Paper sx={{ p: 3 }}>
          <Typography variant="h6" gutterBottom>
            Bases de Dados
          </Typography>
          
          <Grid container spacing={2}>
            {mockDatabases.map((db, index) => (
              <Grid item xs={12} sm={6} md={4} key={index}>
                <Card 
                  sx={{ 
                    cursor: 'pointer',
                    border: selectedDatabase === db.name ? 2 : 1,
                    borderColor: selectedDatabase === db.name ? 'primary.main' : 'grey.300'
                  }}
                  onClick={() => setSelectedDatabase(db.name)}
                >
                  <CardContent>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                      <Typography variant="h6">{db.name}</Typography>
                      <Chip 
                        label={db.status} 
                        color={db.status === 'online' ? 'success' : 'warning'}
                        size="small"
                      />
                    </Box>
                    <Typography variant="body2" color="textSecondary">
                      Tamanho: {db.size}
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      Conexões: {db.connections}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>

          {selectedDatabase && (
            <Alert severity="info" sx={{ mt: 3 }}>
              Base selecionada: <strong>{selectedDatabase}</strong>
              <br />
              <Button 
                startIcon={<SettingsIcon />} 
                sx={{ mt: 1 }}
                variant="outlined"
                size="small"
              >
                Configurar Monitoramento
              </Button>
            </Alert>
          )}
        </Paper>

        {/* User Info Card */}
        <Paper sx={{ p: 3, mt: 3 }}>
          <Typography variant="h6" gutterBottom>
            Informações da Conta
          </Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} sm={6}>
              <Typography variant="body2" color="textSecondary">Nome:</Typography>
              <Typography variant="body1">{user?.full_name}</Typography>
            </Grid>
            <Grid item xs={12} sm={6}>
              <Typography variant="body2" color="textSecondary">Email:</Typography>
              <Typography variant="body1">{user?.email}</Typography>
            </Grid>
            <Grid item xs={12} sm={6}>
              <Typography variant="body2" color="textSecondary">Usuário:</Typography>
              <Typography variant="body1">{user?.username}</Typography>
            </Grid>
            <Grid item xs={12} sm={6}>
              <Typography variant="body2" color="textSecondary">Papel:</Typography>
              <Chip label={user?.role} color={user?.role === 'ADMIN' ? 'error' : 'default'} />
            </Grid>
          </Grid>
        </Paper>
      </Container>
    </Box>
  );
};

export default Dashboard;
