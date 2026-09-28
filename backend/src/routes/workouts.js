import { Router } from 'express';
import WorkoutController from '../controllers/WorkoutController.js';
import { authenticate } from '../middleware/auth.js';

const router = Router();

// All workout routes require a valid JWT Bearer token
router.use(authenticate);

// POST /workouts - Log new workout session
router.post('/', WorkoutController.createWorkout);

// GET /workouts - List authenticated user's workouts (paginated)
router.get('/', WorkoutController.listUserWorkouts);

// GET /workouts/:id - Get specific workout details
router.get('/:id', WorkoutController.getWorkoutById);

// PUT /workouts/:id - Update workout session
router.put('/:id', WorkoutController.updateWorkout);

// DELETE /workouts/:id - Delete workout session
router.delete('/:id', WorkoutController.deleteWorkout);

export default router;
