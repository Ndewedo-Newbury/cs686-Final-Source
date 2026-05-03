import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { listWorkouts, deleteWorkout } from '@/api/workouts'
import { Button, buttonVariants } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Trash2 } from 'lucide-react'

export function Workouts() {
  const queryClient = useQueryClient()
  const { data: workouts, isLoading } = useQuery({
    queryKey: ['workouts'],
    queryFn: () => listWorkouts().then((r) => r.data),
  })

  const deleteMutation = useMutation({
    mutationFn: deleteWorkout,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['workouts'] }),
  })

  return (
    <div className="max-w-2xl mx-auto py-10 px-4 space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Workouts</h1>
        <Link to="/workouts/log" className={buttonVariants()}>Log Workout</Link>
      </div>

      {isLoading && <p className="text-muted-foreground">Loading...</p>}

      {workouts?.length === 0 && (
        <p className="text-muted-foreground text-sm">No workouts logged yet.</p>
      )}

      <div className="space-y-3">
        {workouts?.map((workout) => (
          <Card key={workout.id}>
            <CardHeader className="pb-2 flex flex-row items-center justify-between">
              <Link to={`/workouts/${workout.id}`}>
                <CardTitle className="text-base hover:underline">{workout.name}</CardTitle>
              </Link>
              <Button
                variant="ghost"
                size="icon"
                onClick={() => deleteMutation.mutate(workout.id)}
              >
                <Trash2 className="h-4 w-4 text-muted-foreground" />
              </Button>
            </CardHeader>
            <CardContent className="flex items-center gap-3">
              <Badge variant="secondary">{workout.exercises.length} exercises</Badge>
              <span className="text-xs text-muted-foreground">
                {new Date(workout.logged_at).toLocaleDateString()}
              </span>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  )
}
