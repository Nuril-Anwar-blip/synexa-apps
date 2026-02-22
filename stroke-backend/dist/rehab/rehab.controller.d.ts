import { RehabService } from './rehab.service';
export declare class RehabController {
    private readonly rehabService;
    constructor(rehabService: RehabService);
    getPhases(): Promise<{
        name: string;
        id: number;
        duration_weeks_min: number | null;
        duration_weeks_max: number | null;
        target_description: string | null;
        daily_duration_minutes: string | null;
        pass_score_min: number | null;
        min_consecutive_days: number | null;
        safety_notes: string[];
    }[]>;
    getExercises(phaseId: number): Promise<{
        name: string;
        id: string;
        media_url: string | null;
        phase_id: number | null;
        time_category: string | null;
        instructions: string[];
        duration_text: string | null;
        duration_seconds: number | null;
        is_repetition: boolean | null;
    }[]>;
    logExercise(data: {
        user_id: string;
        exercise_id: string;
        duration_seconds?: number;
        repetitions?: number;
    }): Promise<{
        id: string;
        user_id: string | null;
        duration_actual_seconds: number | null;
        is_aborted: boolean | null;
        abort_reason: string | null;
        completed_at: Date;
        exercise_id: string | null;
    }>;
    getQuiz(phaseId: number): Promise<{
        id: string;
        from_phase_id: number | null;
        order_index: number | null;
        question_text: string;
        is_critical: boolean | null;
    }[]>;
    submitQuiz(data: {
        user_id: string;
        phase_id: number;
        responses: any;
    }): Promise<{
        id: string;
        created_at: Date;
        user_id: string | null;
        score: number | null;
        passed: boolean | null;
        responses: import("@prisma/client/runtime/library").JsonValue | null;
        from_phase_id: number | null;
    }>;
    getProgress(userId: string): Promise<{
        phase: {
            name: string;
            id: number;
            duration_weeks_min: number | null;
            duration_weeks_max: number | null;
            target_description: string | null;
            daily_duration_minutes: string | null;
            pass_score_min: number | null;
            min_consecutive_days: number | null;
            safety_notes: string[];
        } | null;
    } & {
        user_id: string;
        phase_started_at: Date | null;
        last_quiz_at: Date | null;
        streak_count: number | null;
        current_phase_id: number | null;
    }>;
}
