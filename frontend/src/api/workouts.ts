import { workoutsClient } from './client'

export interface Exercise {
  id: string
  name: string
  sets: number
  reps: number
  weight_kg: number | null
}

export interface Workout {
  id: string
  name: string
  logged_at: string
  exercises: Exercise[]
}

export interface ExerciseIn {
  name: string
  sets: number
  reps: number
  weight_kg?: number
}

export interface WorkoutIn {
  name: string
  exercises: ExerciseIn[]
}

export const logWorkout = (data: WorkoutIn) =>
  workoutsClient.post<Workout>('/api/v1/workouts/', data)

export const listWorkouts = () =>
  workoutsClient.get<Workout[]>('/api/v1/workouts/')

export const getWorkout = (id: string) =>
  workoutsClient.get<Workout>(`/api/v1/workouts/${id}`)

export const deleteWorkout = (id: string) =>
  workoutsClient.delete(`/api/v1/workouts/${id}`)
