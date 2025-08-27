import { useState, useEffect } from 'react'
import {
  Grid,
  Paper,
  Typography,
  Box,
  CircularProgress,
  Card,
  CardContent,
  Chip,
} from '@mui/material'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'

const Dashboard: React.FC = () => {
  const [loading, setLoading] = useState(true)
  
  // Mock data para demonstração
  const [metrics] = useState({
    connections: { active: 45, max: 100, trend: 'stable', status: 'healthy' },
    database: { size: 2147483648, growth_trend: 'up' },
    performance: { queries_per_second: 150, trend: 'up', status: 'healthy' },
    system: { cpu_percent: 25.5, cpu_trend: 'stable', cpu_status: 'healthy' }
  })

  const [historicalData] = useState([
    { timestamp: '10:00', connections: 40, queries_per_second: 120 },
    { timestamp: '10:05', connections: 42, queries_per_second: 135 },
    { timestamp: '10:10', connections: 45, queries_per_second: 150 },
    { timestamp: '10:15', connections: 43, queries_per_second: 145 },
    { timestamp: '10:20', connections: 47, queries_per_second: 160 },
  ])

  useEffect(() => {
    // Simular carregamento
    setTimeout(() => setLoading(false), 1000)
  }, [])

  const formatBytes = (bytes: number) => {
    return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB'
  }

  if (loading) {
    return (
      <Box className="loading-spinner">
        <CircularProgress />
        <Typography variant="body1" sx={{ ml: 2 }}>
          Loading metrics...
        </Typography>
      </Box>
    )
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        PostgreSQL Dashboard
      </Typography>

      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card className="metric-card">
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Active Connections
              </Typography>
              <Typography variant="h4" component="div">
                {metrics.connections.active}
              </Typography>
              <Typography variant="body2" color="textSecondary">
                Max: {metrics.connections.max}
              </Typography>
              <Chip label={metrics.connections.status} color="success" size="small" />
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card className="metric-card">
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Database Size
              </Typography>
              <Typography variant="h4" component="div">
                {formatBytes(metrics.database.size)}
              </Typography>
              <Typography variant="body2" color="textSecondary">
                Total Size
              </Typography>
              <Chip label="healthy" color="success" size="small" />
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card className="metric-card">
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Queries/sec
              </Typography>
              <Typography variant="h4" component="div">
                {metrics.performance.queries_per_second}
              </Typography>
              <Typography variant="body2" color="textSecondary">
                Current Rate
              </Typography>
              <Chip label={metrics.performance.status} color="success" size="small" />
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card className="metric-card">
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                CPU Usage
              </Typography>
              <Typography variant="h4" component="div">
                {metrics.system.cpu_percent.toFixed(1)}%
              </Typography>
              <Typography variant="body2" color="textSecondary">
                Current Usage
              </Typography>
              <Chip label={metrics.system.cpu_status} color="success" size="small" />
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={3}>
        <Grid item xs={12} lg={6}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              Connection History
            </Typography>
            <Box className="chart-container">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={historicalData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="timestamp" />
                  <YAxis />
                  <Tooltip />
                  <Line
                    type="monotone"
                    dataKey="connections"
                    stroke="#1976d2"
                    strokeWidth={2}
                  />
                </LineChart>
              </ResponsiveContainer>
            </Box>
          </Paper>
        </Grid>
        
        <Grid item xs={12} lg={6}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              Query Performance
            </Typography>
            <Box className="chart-container">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={historicalData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="timestamp" />
                  <YAxis />
                  <Tooltip />
                  <Line
                    type="monotone"
                    dataKey="queries_per_second"
                    stroke="#dc004e"
                    strokeWidth={2}
                  />
                </LineChart>
              </ResponsiveContainer>
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  )
}

export default Dashboard
