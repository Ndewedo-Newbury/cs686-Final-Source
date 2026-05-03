import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '@/context/AuthContext'
import { Button } from '@/components/ui/button'
import { Dumbbell } from 'lucide-react'

export function Navbar() {
  const { token, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <nav className="border-b px-6 py-3 flex items-center justify-between">
      <Link to="/" className="flex items-center gap-2 font-semibold text-lg">
        <Dumbbell className="h-5 w-5" />
        FitTracker
      </Link>
      {token && (
        <div className="flex items-center gap-4">
          <Link to="/dashboard" className="text-sm text-muted-foreground hover:text-foreground">Dashboard</Link>
          <Link to="/workouts" className="text-sm text-muted-foreground hover:text-foreground">Workouts</Link>
          <Button variant="outline" size="sm" onClick={handleLogout}>Logout</Button>
        </div>
      )}
    </nav>
  )
}
