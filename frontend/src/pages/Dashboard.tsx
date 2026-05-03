import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { getStats } from '@/api/analytics'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { buttonVariants } from '@/components/ui/button'
import { Dumbbell, Flame, Calendar } from 'lucide-react'

export function Dashboard() {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['stats'],
    queryFn: () => getStats().then((r) => r.data),
    retry: false,
  })

  return (
    <div className="max-w-2xl mx-auto py-10 px-4 space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Dashboard</h1>
        <Link to="/workouts/log" className={buttonVariants()}>Log Workout</Link>
      </div>

      {isLoading && <p className="text-muted-foreground">Loading stats...</p>}

      {isError && (
        <Card>
          <CardContent className="pt-6">
            <p className="text-muted-foreground text-sm">No stats yet — log your first workout to get started!</p>
          </CardContent>
        </Card>
      )}

      {data && (
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <Card>
            <CardHeader className="flex flex-row items-center gap-2 pb-2">
              <Dumbbell className="h-4 w-4 text-muted-foreground" />
              <CardTitle className="text-sm font-medium">Total Workouts</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-3xl font-bold">{data.total_workouts}</p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center gap-2 pb-2">
              <Flame className="h-4 w-4 text-muted-foreground" />
              <CardTitle className="text-sm font-medium">Current Streak</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-3xl font-bold">{data.current_streak} days</p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center gap-2 pb-2">
              <Calendar className="h-4 w-4 text-muted-foreground" />
              <CardTitle className="text-sm font-medium">Last Workout</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm font-medium">
                {data.last_workout_at
                  ? new Date(data.last_workout_at).toLocaleDateString()
                  : '—'}
              </p>
            </CardContent>
          </Card>
        </div>
      )}

      <div className="pt-2">
        <Link to="/workouts" className={buttonVariants({ variant: 'outline' })}>
          View all workouts →
        </Link>
      </div>
    </div>
  )
}
