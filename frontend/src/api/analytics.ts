import { analyticsClient } from './client'

export interface Stats {
  user_id: string
  total_workouts: number
  current_streak: number
  last_workout_at: string | null
}

export const getStats = () =>
  analyticsClient.get<Stats>('/api/v1/analytics/stats')
