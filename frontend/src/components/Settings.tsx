import React, { useState } from 'react'
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  TextField,
  Button,
  Alert,
  Switch,
  FormControlLabel,
} from '@mui/material'
import { Save, Storage } from '@mui/icons-material'

const Settings: React.FC = () => {
  const [settings, setSettings] = useState({
    database: {
      host: 'localhost',
      port: 5432,
      database: 'postgres',
      username: 'postgres',
    },
    monitoring: {
      interval: 30,
      retention_days: 30,
      enable_alerts: true,
    },
  })
  
  const [success, setSuccess] = useState(false)

  const handleSave = () => {
    setSuccess(true)
    setTimeout(() => setSuccess(false), 3000)
  }

  const handleInputChange = (section: string, field: string, value: any) => {
    setSettings(prev => ({
      ...prev,
      [section]: {
        ...prev[section as keyof typeof prev],
        [field]: value,
      },
    }))
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Settings
      </Typography>

      {success && (
        <Alert severity="success" sx={{ mb: 2 }}>
          Settings saved successfully!
        </Alert>
      )}

      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" gap={1} mb={2}>
                <Storage color="primary" />
                <Typography variant="h6">Database Connection</Typography>
              </Box>
              
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Host"
                    value={settings.database.host}
                    onChange={(e) => handleInputChange('database', 'host', e.target.value)}
                  />
                </Grid>
                <Grid item xs={6}>
                  <TextField
                    fullWidth
                    label="Port"
                    type="number"
                    value={settings.database.port}
                    onChange={(e) => handleInputChange('database', 'port', parseInt(e.target.value))}
                  />
                </Grid>
                <Grid item xs={6}>
                  <TextField
                    fullWidth
                    label="Database"
                    value={settings.database.database}
                    onChange={(e) => handleInputChange('database', 'database', e.target.value)}
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Username"
                    value={settings.database.username}
                    onChange={(e) => handleInputChange('database', 'username', e.target.value)}
                  />
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Monitoring Settings
              </Typography>
              
              <Grid container spacing={2}>
                <Grid item xs={6}>
                  <TextField
                    fullWidth
                    label="Interval (seconds)"
                    type="number"
                    value={settings.monitoring.interval}
                    onChange={(e) => handleInputChange('monitoring', 'interval', parseInt(e.target.value))}
                  />
                </Grid>
                <Grid item xs={6}>
                  <TextField
                    fullWidth
                    label="Retention (days)"
                    type="number"
                    value={settings.monitoring.retention_days}
                    onChange={(e) => handleInputChange('monitoring', 'retention_days', parseInt(e.target.value))}
                  />
                </Grid>
                <Grid item xs={12}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={settings.monitoring.enable_alerts}
                        onChange={(e) => handleInputChange('monitoring', 'enable_alerts', e.target.checked)}
                      />
                    }
                    label="Enable Alerts"
                  />
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12}>
          <Box display="flex" justifyContent="flex-end">
            <Button
              variant="contained"
              onClick={handleSave}
              startIcon={<Save />}
            >
              Save Settings
            </Button>
          </Box>
        </Grid>
      </Grid>
    </Box>
  )
}

export default Settings
