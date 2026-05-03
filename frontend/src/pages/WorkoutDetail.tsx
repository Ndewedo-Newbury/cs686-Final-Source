import { useQuery } from '@tanstack/react-query'
import { useParams, Link } from 'react-router-dom'
import { getWorkout } from '@/api/workouts'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { buttonVariants } from '@/components/ui/button'
import { Separator } from '@/components/ui/separator'
import { cn } from '@/lib/utils'
import { ArrowLeft } from 'lucide-react'

export function WorkoutDetail() {
  const { id } = useParams<{ id: string }>()
  const { data: workout, isLoading } = useQuery({
    queryKey: ['workout', id],
    queryFn: () => getWorkout(id!).then((r) => r.data),
    enabled: !!id,
  })

  if (isLoading) return <p className="p-10 text-muted-foreground">Loading...</p>
  if (!workout) return <p className="p-10 text-muted-foreground">Workout not found.</p>

  return (
    <div className="max-w-2xl mx-auto py-10 px-4 space-y-6">
      <Link to="/workouts" className={cn(buttonVariants({ variant: 'ghost' }), 'pl-0')}>
        <ArrowLeft className="h-4 w-4 mr-1" /> Back
      </Link>

      <div>
        <h1 className="text-2xl font-semibold">{workout.name}</h1>
        <p className="text-sm text-muted-foreground mt-1">
          {new Date(workout.logged_at).toLocaleString()}
        </p>
      </div>

      <Separator />

      <div className="space-y-3">
        <h2 className="text-sm font-medium text-muted-foreground uppercase tracking-wide">Exercises</h2>
        {workout.exercises.map((ex) => (
          <Card key={ex.id}>
            <CardHeader className="pb-1">
              <CardTitle className="text-base">{ex.name}</CardTitle>
            </CardHeader>
            <CardContent className="text-sm text-muted-foreground">
              {ex.sets} sets × {ex.reps} reps
              {ex.weight_kg != null && ` @ ${ex.weight_kg} kg`}
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  )
}
