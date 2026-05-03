import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { logWorkout, type ExerciseIn } from '@/api/workouts'
import { Button, buttonVariants } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Separator } from '@/components/ui/separator'
import { cn } from '@/lib/utils'
import { ArrowLeft, Plus, Trash2 } from 'lucide-react'

const emptyExercise = (): ExerciseIn => ({ name: '', sets: 3, reps: 10 })

export function LogWorkout() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [workoutName, setWorkoutName] = useState('')
  const [exercises, setExercises] = useState<ExerciseIn[]>([emptyExercise()])
  const [error, setError] = useState('')

  const mutation = useMutation({
    mutationFn: logWorkout,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['workouts'] })
      queryClient.invalidateQueries({ queryKey: ['stats'] })
      navigate('/workouts')
    },
    onError: () => setError('Failed to log workout. Please try again.'),
  })

  const updateExercise = (index: number, field: keyof ExerciseIn, value: string | number | undefined) => {
    setExercises((prev) => prev.map((ex, i) => i === index ? { ...ex, [field]: value } : ex))
  }

  const handleSubmit = (e: { preventDefault(): void }) => {
    e.preventDefault()
    setError('')
    mutation.mutate({ name: workoutName, exercises })
  }

  return (
    <div className="max-w-2xl mx-auto py-10 px-4 space-y-6">
      <Link to="/workouts" className={cn(buttonVariants({ variant: 'ghost' }), 'pl-0')}>
        <ArrowLeft className="h-4 w-4 mr-1" /> Back
      </Link>

      <h1 className="text-2xl font-semibold">Log Workout</h1>

      <form onSubmit={handleSubmit} className="space-y-6">
        {error && <p className="text-sm text-destructive">{error}</p>}

        <div className="space-y-2">
          <Label htmlFor="workout-name">Workout Name</Label>
          <Input
            id="workout-name"
            placeholder="e.g. Leg Day"
            value={workoutName}
            onChange={(e) => setWorkoutName(e.target.value)}
            required
          />
        </div>

        <Separator />

        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-medium">Exercises</h2>
            <Button type="button" variant="outline" size="sm" onClick={() => setExercises((p) => [...p, emptyExercise()])}>
              <Plus className="h-4 w-4 mr-1" /> Add Exercise
            </Button>
          </div>

          {exercises.map((ex, i) => (
            <Card key={i}>
              <CardHeader className="pb-2 flex flex-row items-center justify-between">
                <CardTitle className="text-sm">Exercise {i + 1}</CardTitle>
                {exercises.length > 1 && (
                  <Button type="button" variant="ghost" size="icon" onClick={() => setExercises((p) => p.filter((_, idx) => idx !== i))}>
                    <Trash2 className="h-4 w-4 text-muted-foreground" />
                  </Button>
                )}
              </CardHeader>
              <CardContent className="grid grid-cols-2 gap-3">
                <div className="col-span-2 space-y-1">
                  <Label>Name</Label>
                  <Input placeholder="e.g. Squat" value={ex.name} onChange={(e) => updateExercise(i, 'name', e.target.value)} required />
                </div>
                <div className="space-y-1">
                  <Label>Sets</Label>
                  <Input type="number" min={1} value={ex.sets} onChange={(e) => updateExercise(i, 'sets', Number(e.target.value))} required />
                </div>
                <div className="space-y-1">
                  <Label>Reps</Label>
                  <Input type="number" min={1} value={ex.reps} onChange={(e) => updateExercise(i, 'reps', Number(e.target.value))} required />
                </div>
                <div className="col-span-2 space-y-1">
                  <Label>Weight (kg) <span className="text-muted-foreground">optional</span></Label>
                  <Input
                    type="number"
                    min={0}
                    step={0.5}
                    value={ex.weight_kg ?? ''}
                    onChange={(e) => updateExercise(i, 'weight_kg', e.target.value ? Number(e.target.value) : undefined)}
                  />
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        <Button type="submit" className="w-full" disabled={mutation.isPending}>
          {mutation.isPending ? 'Saving...' : 'Save Workout'}
        </Button>
      </form>
    </div>
  )
}
