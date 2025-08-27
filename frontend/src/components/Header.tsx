import { AppBar, Toolbar, Typography, Button, Box, Chip } from '@mui/material'
import { useNavigate, useLocation } from 'react-router-dom'
import { Dashboard, Settings } from '@mui/icons-material'

const Header: React.FC = () => {
  const navigate = useNavigate()
  const location = useLocation()

  const menuItems = [
    { path: '/', label: 'Dashboard', icon: <Dashboard /> },
    { path: '/settings', label: 'Settings', icon: <Settings /> },
  ]

  return (
    <AppBar position="static">
      <Toolbar>
        <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
          pgAnalytics v3.0
        </Typography>
        
        <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
          {menuItems.map((item) => (
            <Button
              key={item.path}
              color="inherit"
              onClick={() => navigate(item.path)}
              sx={{
                backgroundColor: location.pathname === item.path ? 'rgba(255, 255, 255, 0.1)' : 'transparent',
              }}
              startIcon={item.icon}
            >
              {item.label}
            </Button>
          ))}
          
          <Chip 
            label="ADMIN" 
            color="secondary" 
            size="small"
          />
        </Box>
      </Toolbar>
    </AppBar>
  )
}

export default Header
